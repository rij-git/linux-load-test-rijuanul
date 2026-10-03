#!/bin/bash

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"
LOG_DIR="/var/log/${SVC_NAME}"
LOGROTATE_FILE="/etc/logrotate.d/${SVC_NAME}"
MONITOR_SCRIPT="/usr/local/bin/${SVC_NAME}_monitor.sh"
CLEANUP_SCRIPT="/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"

echo "Stopping any processes owned by $SVC_NAME..."
sudo pkill -u "$SVC_NAME" 2>/dev/null || echo "  (no running processes - that's fine)"

echo "Removing crontab for $SVC_NAME..."
sudo crontab -r -u "$SVC_NAME" 2>/dev/null || echo "  (no crontab to remove - that's fine)"

echo "Removing logrotate config..."
sudo rm -f "$LOGROTATE_FILE"

echo "Removing monitor and cleanup scripts..."
sudo rm -f "$MONITOR_SCRIPT" "$CLEANUP_SCRIPT"

echo "Unmounting and removing the tmpfs folder..."
if mountpoint -q "$MOUNT_DIR" 2>/dev/null; then
    sudo umount "$MOUNT_DIR"
fi
sudo rmdir "$MOUNT_DIR" 2>/dev/null || echo "  ($MOUNT_DIR already gone - that's fine)"

echo "Removing log directory..."
sudo rm -rf "$LOG_DIR"

echo "Deleting the service account $SVC_NAME..."
if id "$SVC_NAME" &>/dev/null; then
    sudo userdel -r "$SVC_NAME"
else
    echo "  (user already deleted - that's fine)"
fi

echo ""
echo "----- Verification -----"
id "$SVC_NAME" 2>&1 || true
mount | grep "$SVC_NAME" || echo "No leftover mounts for $SVC_NAME."
echo "Cleanup complete."
