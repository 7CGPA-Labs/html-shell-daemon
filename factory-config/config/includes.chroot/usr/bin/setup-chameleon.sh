#!/bin/bash
# ==============================================================================
# Anodyne OS - Chameleon Adaptive Touchscreen Input Detector
# ==============================================================================
# Scans input devices for touchscreen capabilities to configure UI scaling.
# ==============================================================================

set -euo pipefail

FLAG_FILE="/tmp/touchscreen_detected"

echo "[*] Running Anodyne Chameleon Input Scanner..."

# Scan uevent input properties and udev database logs for touchscreen tags
if grep -qi "touchscreen" /sys/class/input/input*/device/uevent 2>/dev/null || \
   (udevadm info --export-db 2>/dev/null | grep -qi "ID_INPUT_TOUCHSCREEN=1"); then
    
    echo "[+] Touchscreen interface detected! Writing system flag."
    touch "$FLAG_FILE"
    chmod 666 "$FLAG_FILE"
    logger -t anodyne-chameleon "Touchscreen interface detected. Scaling UI factor."
else
    echo "[*] Standard mouse/keyboard input interface detected."
    rm -f "$FLAG_FILE"
    logger -t anodyne-chameleon "Standard mouse/keyboard interface detected."
fi
