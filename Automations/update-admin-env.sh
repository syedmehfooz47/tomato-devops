#!/bin/bash

# Set the Instance ID and path to the .env file
INSTANCE_ID="i-0d83a05ecd053b415"

# Retrieve the public IP address of the specified EC2 instance
ipv4_address=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

# Path to the .env file
file_to_find="../frontend/.env.docker"

# Check the current VITE_BACKEND_URL in the .env file
current_url=$(cat $file_to_find)

# Update the .env file if the IP address has changed
if [[ "$current_url" != "VITE_BACKEND_URL=\"http://${ipv4_address}:4000\"" ]]; then
    if [ -f $file_to_find ]; then
        sed -i -e "s|VITE_BACKEND_URL.*|VITE_BACKEND_URL=\"http://${ipv4_address}:4000\"|g" $file_to_find
    else
        echo "ERROR: File not found."
    fi
fi