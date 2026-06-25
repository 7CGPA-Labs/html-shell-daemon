#!/bin/bash
# ==============================================================================
# WebOS Appliance - dm-verity Boot Block Cryptographic Verification Setup
# ==============================================================================
# Packages the container userland and calculates verification hash parameters.
# ==============================================================================

set -euo pipefail

# Configuration paths
USERLAND_DIR="/var/lib/webos/rootfs"
BUILD_DIR="/tmp/webos_build"
SQUASHFS_IMAGE="$BUILD_DIR/rootfs.squashfs"
VERITY_HASH_DEV="$BUILD_DIR/rootfs.verity_hash"
VERITY_METADATA="$BUILD_DIR/verity_metadata.json"

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

echo "[*] Initializing dm-verity cryptographic block packaging..."

# Create work area
mkdir -p "$BUILD_DIR"

# 1. Verify dependencies
dependencies=(squashfs-tools cryptsetup jq)
for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo "[-] Installing dependency: $dep"
        apt-get update && apt-get install -y "$dep"
    fi
done

# 2. Package userland folder into immutable SquashFS filesystem block
echo "[*] Packaging $USERLAND_DIR into a compressed SquashFS block..."
if [ ! -d "$USERLAND_DIR" ] || [ -z "$(ls -A "$USERLAND_DIR")" ]; then
    echo "[!] WARNING: $USERLAND_DIR is empty. Packaging a fallback mock folder for sandbox testing..."
    MOCK_ROOT="/tmp/webos_mock_root"
    mkdir -p "$MOCK_ROOT/bin" "$MOCK_ROOT/etc" "$MOCK_ROOT/usr"
    echo "WebOS Appliance minimal root" > "$MOCK_ROOT/etc/webos-release"
    mksquashfs "$MOCK_ROOT" "$SQUASHFS_IMAGE" -noappend -comp xz
else
    mksquashfs "$USERLAND_DIR" "$SQUASHFS_IMAGE" -noappend -comp xz
fi

echo "[+] SquashFS image generated successfully: $SQUASHFS_IMAGE ($(du -sh "$SQUASHFS_IMAGE" | cut -f1))"

# 3. Calculate dm-verity tree blocks and Root Hash
echo "[*] Computing cryptographic block integrity hash device..."
# Format the SquashFS image with dm-verity, creating the hash device mapping
VERITY_OUTPUT=$(veritysetup format "$SQUASHFS_IMAGE" "$VERITY_HASH_DEV")

# Extract the critical Root Hash value from output
ROOT_HASH=$(echo "$VERITY_OUTPUT" | grep -i "Root hash:" | awk '{print $3}')
UUID_VAL=$(echo "$VERITY_OUTPUT" | grep -i "UUID:" | awk '{print $2}')
DATA_BLOCKS=$(echo "$VERITY_OUTPUT" | grep -i "Data blocks:" | awk '{print $3}')

# Write credentials to disk for bootloader integration
cat <<EOF > "$VERITY_METADATA"
{
  "uuid": "$UUID_VAL",
  "root_hash": "$ROOT_HASH",
  "data_blocks": "$DATA_BLOCKS",
  "algorithm": "sha256",
  "data_device": "rootfs.squashfs",
  "hash_device": "rootfs.verity_hash"
}
EOF

echo "[+] Integrity generation complete."
echo "--------------------------------------------------"
echo "UUID:        $UUID_VAL"
echo "Root Hash:   $ROOT_HASH"
echo "Data Blocks: $DATA_BLOCKS"
echo "Metadata:    $VERITY_METADATA"
echo "--------------------------------------------------"

# 4. Generate systemd/Grub Kernel Command parameters
echo "[*] Generating GRUB kernel boot command mapping parameters..."
echo ""
echo ">>> INTEGRATE THE FOLLOWING LINE INTO GRUB_CMDLINE_LINUX_DEFAULT <<<"
echo "systemd.verity=1 verity.usr=UUID=$UUID_VAL usrhash=$ROOT_HASH dm-mod.create=\"webos_root,,,ro, 0 $DATA_BLOCKS verity /dev/loop0 /dev/loop1 0 sha256 $ROOT_HASH\""
echo ""
echo "[*] Done. SquashFS and verification hashes are ready in $BUILD_DIR."
EOF
