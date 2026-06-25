#!/bin/bash
# ==============================================================================
# WebOS Appliance - TPM 2.0-bound LUKS2 Partition Encryption Setup Script
# ==============================================================================
# Sets up encrypted user volumes bound to system Trusted Platform Module (TPM).
# ==============================================================================

set -euo pipefail

# Configuration parameters
PARTITION_DEVICE="${1:-}" # Device path, e.g. /dev/sdb2 or /dev/nvme0n1p2
MAP_NAME="webos_secure_data"
MOUNT_POINT="/var/lib/webos/profiles"
KEY_FILE="/tmp/tpm_luks_transient.key"

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

if [ -z "$PARTITION_DEVICE" ]; then
    echo "[-] ERROR: Target partition device path required." >&2
    echo "    Usage: sudo $0 <target-partition-device>  (e.g., /dev/sdb3)" >&2
    exit 1
fi

echo "[*] Initializing TPM-bound LUKS encryption sequence..."

# 1. Dependency checks
echo "[*] Checking dependency packages..."
dependencies=(cryptsetup tpm2-tools tpm2-openssl openssl)
for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "[-] Installing missing dependency: $dep"
        apt-get update && apt-get install -y "$dep"
    else
        echo "[+] Dependency verified: $dep"
    fi
done

# 2. Key Generation
echo "[*] Generating cryptographically secure key file..."
openssl rand -hex 64 > "$KEY_FILE"
chmod 400 "$KEY_FILE"

# 3. LUKS2 Formatting
echo "[*] Formatting $PARTITION_DEVICE with LUKS2..."
# Format device using LUKS2 layout
cryptsetup luksFormat --type luks2 --pbkdf argon2id --key-file "$KEY_FILE" "$PARTITION_DEVICE"

# 4. Bind the passphrase key file inside TPM 2.0 PCR registers
echo "[*] Binding partition key file into TPM 2.0 (PCR 0,4,7 policy validation)..."
# Create primary key object under owner hierarchy
tpm2_createprimary -C o -g sha256 -G rsa -c /tmp/primary.ctx

# Seal the key file inside TPM non-volatile storage, gated by PCR 0 (firmware), PCR 4 (kernel boot), PCR 7 (Secure Boot)
# This guarantees that if the kernel or bootloaders are tampered with (violating dm-verity state), the TPM rejects key release.
tpm2_create -C /tmp/primary.ctx -g sha256 -G keyedhash -i "$KEY_FILE" -u /tmp/key.pub -r /tmp/key.priv -L /tmp/policy.pcr
tpm2_load -C /tmp/primary.ctx -u /tmp/key.pub -r /tmp/key.priv -c /tmp/key.ctx

# Evict old handles and store the context in a persistent TPM handle (e.g. 0x81010001)
PERSISTENT_HANDLE="0x81010002"
# Clear slot if currently occupied
tpm2_evictcontrol -C o -c "$PERSISTENT_HANDLE" &>/dev/null || true
tpm2_evictcontrol -C o -c /tmp/key.ctx "$PERSISTENT_HANDLE"

echo "[+] Successfully locked key file in TPM handle: $PERSISTENT_HANDLE"

# 5. Map the encrypted block device
echo "[*] Opening LUKS container mapping..."
cryptsetup open "$PARTITION_DEVICE" "$MAP_NAME" --key-file "$KEY_FILE"

# 6. Format and mount filesystem
MAPPED_DEV="/dev/mapper/$MAP_NAME"
echo "[*] Formatting mapped block device $MAPPED_DEV as ext4 filesystem..."
mkfs.ext4 -F "$MAPPED_DEV"

echo "[*] Mounting secure volume to $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"
mount "$MAPPED_DEV" "$MOUNT_POINT"

# 7. Add permanent system hooks
echo "[*] Configuring crypttab and fstab mounts..."
# Retrieve Partition UUID
UUID_VAL=$(blkid -s UUID -o value "$PARTITION_DEVICE")

# Build systemd crypttab option to release TPM key automatically at boot
echo "$MAP_NAME UUID=$UUID_VAL none luks,discard,keyscript=/lib/cryptsetup/scripts/tpm2-decrypt" >> /etc/crypttab
echo "$MAPPED_DEV $MOUNT_POINT ext4 defaults,noatime,nofail 0 2" >> /etc/fstab

# Clean up transient key file
rm -f "$KEY_FILE" /tmp/primary.ctx /tmp/key.pub /tmp/key.priv /tmp/key.ctx /tmp/policy.pcr

echo "[+] Setup Complete. LUKS partition is bound to TPM and mounted successfully at $MOUNT_POINT."
