#!/bin/bash

set -e

if ! command -v sshd &>/dev/null; then
    echo "openssh-server not found. Installing..."
    sudo apt update
    sudo apt install openssh-server -y
else
    echo "openssh-server is already installed."
fi

echo "Enabling and starting the ssh service..."
sudo systemctl enable --now ssh

echo "Restarting ssh so any config changes take effect..."
sudo systemctl restart ssh

echo ""
echo "----- Verification: which port is SSH actually listening on? -----"
sudo ss -tlnp | grep ssh
