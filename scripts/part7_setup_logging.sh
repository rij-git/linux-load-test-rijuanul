#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
LOG_DIR="/var/log/${SVC_NAME}"
LOGROTATE_FILE="/etc/logrotate.d/${SVC_NAME}"

echo "Creating log directory $LOG_DIR ..."
sudo mkdir -p "$LOG_DIR"
sudo chown "$SVC_NAME:$SVC_NAME" "$LOG_DIR"

echo "Writing logrotate config to $LOGROTATE_FILE ..."
sudo tee "$LOGROTATE_FILE" > /dev/null << EOF
${LOG_DIR}/*.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
    create 0664 ${SVC_NAME} ${SVC_NAME}
}
EOF

echo "Testing the logrotate rule now (force run)..."
sudo logrotate -f "$LOGROTATE_FILE"

echo ""
echo "----- Verification -----"
ls -lh "$LOG_DIR/"
