#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

echo "Running memory stress test as $SVC_NAME for 30 seconds (200M allocation)..."
sudo -u "$SVC_NAME" stress-ng --temp-path "$MOUNT_DIR" --vm 1 --vm-bytes 200M --timeout 30s
