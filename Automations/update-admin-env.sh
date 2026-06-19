#!/bin/bash

INSTANCE_ID="i-095fd99dcf1b8c13c"

ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

if [ -z "$ipv4_address" ] || [ "$ipv4_address" = "None" ]; then
    echo "ERROR: Could not retrieve IP address for instance $INSTANCE_ID"
    exit 1
fi

echo "EC2 Public IP: $ipv4_address"

file_to_find="../admin/.env.docker"

if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi

sed -i -e "s|VITE_BACKEND_URL=.*|VITE_BACKEND_URL=http://${ipv4_address}:31002|g" "$file_to_find"

echo "Updated $file_to_find with VITE_BACKEND_URL=http://${ipv4_address}:31002"
cat "$file_to_find"
