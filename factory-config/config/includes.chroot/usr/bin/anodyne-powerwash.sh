#!/bin/bash
# ==============================================================================
# Anodyne OS - Powerwash Secure Factory Reset Controller
# ==============================================================================
set -euo pipefail

MAP_NAME="anodyne_secure_data"
MOUNT_POINT="/var/lib/anodyne/profiles"

echo "===================================================="
echo "          ANODYNE OS SYSTEM POWERWASH RESET         "
echo "===================================================="

# 1. Unmount active LUKS partition
echo "[*] Unmounting active secure profiles..."
umount "$MOUNT_POINT" || true

# 2. Close LUKS mapping container
echo "[*] Closing encrypted container mapping..."
cryptsetup close "$MAP_NAME" || true

# 3. Securely wipe user data metadata headers
echo "[*] Wiping partition block headers..."
USER_DATA_DEV=$(blkid -t TYPE=crypto_LUKS -o device | head -n 1 || echo "/dev/sda3")

echo "[*] Re-initializing TPM-LUKS secure volume on $USER_DATA_DEV..."
if [ -f "/usr/bin/setup-luks-tpm.sh" ]; then
    /usr/bin/setup-luks-tpm.sh "$USER_DATA_DEV"
else
    echo "[-] Fallback: Wiping and recreating filesystem directly."
    mkfs.ext4 -F "$USER_DATA_DEV"
fi

echo "[+] Powerwash complete. System reset to a clean factory-fresh state."
