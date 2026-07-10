#!/bin/bash
# Anodyne OS - Storage Housekeeper Daemon
# Safely shreds files inside the recycle bin older than 30 days.

RECYCLE_BIN="/root/.recycle_bin"

if [ -d "$RECYCLE_BIN" ]; then
    find "$RECYCLE_BIN" -type f -mtime +30 -exec shred -u {} \;
    find "$RECYCLE_BIN" -mindepth 1 -type d -empty -delete
fi
