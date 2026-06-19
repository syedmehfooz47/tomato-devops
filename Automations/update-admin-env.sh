#!/bin/bash

# Set the Instance ID and path to the .env file
INSTANCE_ID="i-095fd99dcf1b8c13c"

# Retrieve the public IP address of the specified EC2 instance
ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

if [ -z "$ipv4_address" ] || [ "$ipv4_address" = "None" ]; then
    echo "ERROR: Could not retrieve IP address for instance $INSTANCE_ID"
    exit 1
fi

echo "EC2 Public IP: $ipv4_address"

# Path to the ADMIN .env file  (was incorrectly pointing to frontend before)
file_to_find="../admin/.env.docker"

if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi

# Update VITE_BACKEND_URL to the EC2 public IP with the backend NodePort (31002)
sed -i -e "s|VITE_BACKEND_URL=.*|VITE_BACKEND_URL=http://${ipv4_address}:31002|g" "$file_to_find"

echo "Updated $file_to_find with VITE_BACKEND_URL=http://${ipv4_address}:31002"
cat "$file_to_find"
