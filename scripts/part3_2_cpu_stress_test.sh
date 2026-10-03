#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

if ! command -v stress-ng &>/dev/null; then
    echo "stress-ng not found. Installing..."
    sudo apt update
    sudo apt install stress-ng -y
else
    echo "stress-ng is already installed."
fi

echo ""
echo "Running CPU stress test as $SVC_NAME for 30 seconds (2 CPU workers)..."
sudo -u "$SVC_NAME" stress-ng --temp-path "$MOUNT_DIR" --cpu 2 --timeout 30s
