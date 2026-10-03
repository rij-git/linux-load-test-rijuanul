#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"

for i in $(seq 1 20); do
    dd if=/dev/urandom of="${MOUNT_DIR}/file_${i}.dat" bs=1M count=10 status=none
    echo "Created file_${i}.dat -- current usage:"
    df -h "$MOUNT_DIR"
done
