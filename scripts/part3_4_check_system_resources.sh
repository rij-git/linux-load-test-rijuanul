#!/bin/bash

echo "----- Memory usage (free -h) -----"
free -h

echo ""
echo "----- Process / CPU snapshot (top, one-shot) -----"
top -bn1 | head -20

echo ""
echo "----- Checking kernel log for OOM events -----"
if dmesg | grep -qi oom; then
    dmesg | grep -i oom
else
    echo "No OOM (Out Of Memory) messages found."
fi
