#!/bin/bash

set -e

SVC_NAME="bgdsvc_tas"
MOUNT_DIR="/mnt/${SVC_NAME}_tmp"
MONITOR_SCRIPT="/usr/local/bin/${SVC_NAME}_monitor.sh"
CLEANUP_SCRIPT="/usr/local/bin/${SVC_NAME}_cleanup_old_files.sh"

echo "Writing monitoring script to $MONITOR_SCRIPT ..."
sudo tee "$MONITOR_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
LOG_DIR="/var/log/bgdsvc_tas"
mkdir -p "$LOG_DIR"
{
    echo "----- $(date) -----"
    free -h
    df -h /mnt/bgdsvc_tas_tmp
} >> "$LOG_DIR/monitor.log"
EOF
sudo chmod +x "$MONITOR_SCRIPT"

echo "Writing cleanup script to $CLEANUP_SCRIPT ..."
sudo tee "$CLEANUP_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
find /mnt/bgdsvc_tas_tmp -name "file_*.dat" -mtime +1 -delete
EOF
sudo chmod +x "$CLEANUP_SCRIPT"

echo "Adding cron jobs for $SVC_NAME ..."
CRON_JOBS="*/5 * * * * ${MONITOR_SCRIPT}
0 2 * * * ${CLEANUP_SCRIPT}"
echo "$CRON_JOBS" | sudo crontab -u "$SVC_NAME" -

echo ""
echo "----- Verification: current crontab for $SVC_NAME -----"
sudo crontab -l -u "$SVC_NAME"
