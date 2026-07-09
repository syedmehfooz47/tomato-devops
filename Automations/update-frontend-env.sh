#!/bin/bash

BACKEND_URL="https://food-delivery.projects.syedmehfooz.com"

file_to_find="../frontend/.env.docker"

if [ ! -f "$file_to_find" ]; then
    echo "ERROR: File not found: $file_to_find"
    exit 1
fi

sed -i -e "s|VITE_BACKEND_URL=.*|VITE_BACKEND_URL=${BACKEND_URL}|g" "$file_to_find"

echo "Updated $file_to_find with VITE_BACKEND_URL=${BACKEND_URL}"
cat "$file_to_find"
