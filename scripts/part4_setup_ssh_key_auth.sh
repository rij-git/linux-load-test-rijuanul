#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
KEY_PATH="$HOME/.ssh/${SVC_NAME}_key"
SVC_SSH_DIR="/home/${SVC_NAME}/.ssh"

echo "Generating SSH key pair at $KEY_PATH (no passphrase)..."
ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -q

echo "Creating .ssh folder for $SVC_NAME..."
sudo mkdir -p "$SVC_SSH_DIR"

echo "Copying the public key into authorized_keys..."
sudo cp "${KEY_PATH}.pub" "${SVC_SSH_DIR}/authorized_keys"

echo "Fixing ownership and permissions..."
sudo chown -R "$SVC_NAME:$SVC_NAME" "$SVC_SSH_DIR"
sudo chmod 700 "$SVC_SSH_DIR"
sudo chmod 600 "${SVC_SSH_DIR}/authorized_keys"

echo ""
echo "Done. You can now test the connection with:"
echo "  ssh -o IdentitiesOnly=yes -i $KEY_PATH ${SVC_NAME}@localhost"
echo "(Note: since the account's shell is /usr/sbin/nologin, the login"
echo "will be accepted and then closed right away - that is expected"
echo "for a service account.)"
