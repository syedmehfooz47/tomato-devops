#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root (use sudo)"
  exit 1
fi

echo "=========================================="
echo " Setting up socat proxies for Tomato App  "
echo "=========================================="

# 1. Get the IP of the Kind worker node
# Note: NodePort services are accessible on ALL worker nodes, so we can just use mkcluster-worker
WORKER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mkcluster-worker)

if [ -z "$WORKER_IP" ]; then
    echo "ERROR: Could not find IP for mkcluster-worker. Is the Kind cluster running?"
    exit 1
fi

echo "Found mkcluster-worker IP: $WORKER_IP"

# Define our services and their ports
# Format: "ServiceName:NodePort:HostPort"
SERVICES=(
    "frontend:31000:8960"
    "admin:31001:8961"
    "backend:31002:8962"
)

# 2. Loop through and create a systemd service for each
for entry in "${SERVICES[@]}"; do
    IFS=":" read -r SVC_NAME NODE_PORT HOST_PORT <<< "$entry"
    
    SERVICE_FILE="/etc/systemd/system/tomato-${SVC_NAME}-proxy.service"
    
    echo "Creating systemd service for ${SVC_NAME} (Host:${HOST_PORT} -> Node:${NODE_PORT})..."
    
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Tomato ${SVC_NAME} TCP Proxy

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:${HOST_PORT},fork,reuseaddr TCP:${WORKER_IP}:${NODE_PORT}
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

    echo "Service file created at $SERVICE_FILE"
done

# 3. Reload systemd, enable, and start the services
echo "Reloading systemd daemon..."
systemctl daemon-reload

for entry in "${SERVICES[@]}"; do
    IFS=":" read -r SVC_NAME NODE_PORT HOST_PORT <<< "$entry"
    SERVICE_NAME="tomato-${SVC_NAME}-proxy"
    
    echo "Enabling and starting $SERVICE_NAME..."
    systemctl enable "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"
done

echo "=========================================="
echo " Setup Complete! "
echo "=========================================="
echo "Your services are now exposed on the VPS host at the following local ports:"
echo " - Frontend (NodePort 31000) -> 127.0.0.1:8960"
echo " - Admin    (NodePort 31001) -> 127.0.0.1:8961"
echo " - Backend  (NodePort 31002) -> 127.0.0.1:8962"
echo ""
echo "Next step: Configure your cPanel reverse proxy to point to these local ports."
