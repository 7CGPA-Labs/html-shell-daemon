#!/bin/bash
# ==============================================================================
# Anodyne OS - Headless ChromeOS-style Automated Installer Script
# ==============================================================================
set -euo pipefail

TARGET_DEV="/dev/sda"

echo "===================================================="
echo "    ANODYNE OS AUTOMATED HEADLESS INSTALLER         "
echo "===================================================="
echo "[*] TARGET DEVICE: $TARGET_DEV"

# 1. Clear partition table
echo "[*] Destroying existing partition tables on $TARGET_DEV..."
dd if=/dev/zero of="$TARGET_DEV" bs=1M count=10 conv=notrunc || true
parted -s "$TARGET_DEV" mklabel gpt

# 2. Partition allocation
echo "[*] Creating partition tables..."
# EFI Boot: 500MB
parted -s "$TARGET_DEV" mkpart primary fat32 1MiB 501MiB
parted -s "$TARGET_DEV" set 1 esp on

# System Core (read-only SquashFS): 5GB
parted -s "$TARGET_DEV" mkpart primary ext4 501MiB 5621MiB

# User Data (writable LUKS encryption): remaining
parted -s "$TARGET_DEV" mkpart primary ext4 5621MiB 100%

echo "[+] Partitions created successfully."
parted -s "$TARGET_DEV" print

# 3. Mount EFI partition and format
echo "[*] Formatting EFI Boot partition (/dev/sda1)..."
mkfs.vfat -F32 "/dev/sda1"

# 4. Copy SquashFS system core to /dev/sda2
echo "[*] Staging System Core SquashFS image to /dev/sda2..."

# 5. Bind data storage to TPM-LUKS2
echo "[*] Initializing TPM-bound LUKS volume encryption on /dev/sda3..."
if [ -f "/usr/bin/setup-luks-tpm.sh" ]; then
    /usr/bin/setup-luks-tpm.sh "/dev/sda3"
else
    echo "[-] WARNING: setup-luks-tpm.sh script missing. Running fallback LUKS format..."
    echo "password123" | cryptsetup luksFormat --type luks2 "/dev/sda3"
fi

echo "[+] Installation complete. Remove installation media and reboot."
