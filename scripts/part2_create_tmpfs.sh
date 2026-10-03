#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

echo "Creating mount directory: $MOUNT_DIR"
sudo mkdir -p "$MOUNT_DIR"

echo "Mounting a 256M tmpfs at $MOUNT_DIR"
sudo mount -t tmpfs -o size=256M tmpfs "$MOUNT_DIR"

echo "Giving ownership of $MOUNT_DIR to $SVC_NAME"
sudo chown "$SVC_NAME:$SVC_NAME" "$MOUNT_DIR"

echo ""
echo "----- Verification -----"
df -h "$MOUNT_DIR"
