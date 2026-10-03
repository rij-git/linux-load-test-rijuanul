#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"

echo "Checking if service account '$SVC_NAME' already exists..."

if id "$SVC_NAME" &>/dev/null; then
    echo "User '$SVC_NAME' already exists. Skipping creation."
else
    echo "User '$SVC_NAME' does not exist. Creating it now..."
    sudo useradd -r -m -s /usr/sbin/nologin "$SVC_NAME"
    echo "User '$SVC_NAME' created."
fi

echo ""
echo "----- Verification -----"
id "$SVC_NAME"
getent passwd "$SVC_NAME"
