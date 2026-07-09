#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)"
  exit 1
fi

echo "=========================================="
echo " Setting up Ingress socat proxy for Tomato App  "
echo "=========================================="

# 1. Get the IP of the Kind worker node
WORKER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mkcluster-worker)

if [ -z "$WORKER_IP" ]; then
    echo "ERROR: Could not find IP for mkcluster-worker. Is the Kind cluster running?"
    exit 1
fi

echo "Found mkcluster-worker IP: $WORKER_IP"

# 2. Get the NodePort of the Ingress Controller
# Use sudo -u to run kubectl as the original user, because root usually doesn't have the kubeconfig
if [ -n "$SUDO_USER" ]; then
    INGRESS_NODE_PORT=$(sudo -u "$SUDO_USER" kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)
else
    INGRESS_NODE_PORT=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}' 2>/dev/null)
fi

if [ -z "$INGRESS_NODE_PORT" ]; then
    echo "ERROR: Could not find ingress-nginx-controller NodePort. Did you install NGINX Ingress?"
    echo "Run: kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"
    exit 1
fi

echo "Found Ingress NodePort: $INGRESS_NODE_PORT"

# 3. Create a single systemd service for the Ingress
HOST_PORT=8960
SERVICE_FILE="/etc/systemd/system/tomato-ingress-proxy.service"

echo "Creating systemd service for Ingress (Host:${HOST_PORT} -> Node:${INGRESS_NODE_PORT})..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Tomato Ingress TCP Proxy

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:${HOST_PORT},fork,reuseaddr TCP:${WORKER_IP}:${INGRESS_NODE_PORT}
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

# 4. Reload systemd, disable old services, enable new one
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Disabling old separate proxy services if they exist..."
systemctl stop tomato-frontend-proxy tomato-backend-proxy tomato-admin-proxy 2>/dev/null || true
systemctl disable tomato-frontend-proxy tomato-backend-proxy tomato-admin-proxy 2>/dev/null || true

echo "Enabling and starting tomato-ingress-proxy..."
systemctl enable tomato-ingress-proxy
systemctl restart tomato-ingress-proxy

echo "=========================================="
echo " Setup Complete! "
echo "=========================================="
echo "Your entire application is now exposed via Ingress on the VPS host at:"
echo " -> 127.0.0.1:8960"
echo ""
echo "Next step: Configure your cPanel reverse proxy to point YOUR ENTIRE DOMAIN to 127.0.0.1:8960"
