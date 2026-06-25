#!/bin/bash
# ==============================================================================
# WebOS Appliance - zRAM compressed swap (zstd algorithm) setup script
# ==============================================================================
# Configures swap virtualization to run heavy browser runtimes on low-RAM limits.
# ==============================================================================

set -euo pipefail

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] ERROR: This script must be run as root (sudo)." >&2
    exit 1
fi

echo "[*] Initializing zRAM swap allocation space..."

# 1. Load kernel module
if ! lsmod | grep -q "^zram"; then
    echo "[*] Loading kernel zram module..."
    modprobe zram num_devices=1
fi

# 2. Determine sizing (e.g., 1.5x total system RAM size to maximize compression swap headroom)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ZRAM_SIZE_KB=$((TOTAL_RAM_KB * 15 / 10)) # 1.5x RAM size
ZRAM_SIZE_BYTES=$((ZRAM_SIZE_KB * 1024))

echo "[*] Detected Total System RAM: $((TOTAL_RAM_KB / 1024)) MB"
echo "[*] Allocated zRAM Size: $((ZRAM_SIZE_KB / 1024)) MB (zstd compressed)"

# Ensure zram device is reset/idle
if [ -b /dev/zram0 ]; then
    echo 1 > /sys/block/zram0/reset || true
fi

# 3. Configure zRAM settings (comp_algorithm and disksize)
echo "[*] Setting zRAM compression engine to zstd..."
if grep -q "zstd" /sys/block/zram0/comp_algorithm; then
    echo "zstd" > /sys/block/zram0/comp_algorithm
else
    echo "[-] WARNING: zstd algorithm not supported by host kernel. Falling back to lzo-rle..."
    echo "lzo-rle" > /sys/block/zram0/comp_algorithm
fi

echo "[*] Applying disk capacity limit size: $ZRAM_SIZE_BYTES bytes..."
echo "$ZRAM_SIZE_BYTES" > /sys/block/zram0/disksize

# 4. Initialize swap signature
echo "[*] Registering virtual swap block space..."
mkswap /dev/zram0

# 5. Enable swap with top system priorities
echo "[*] Activating swap space swapon..."
swapon -p 32767 /dev/zram0

# 6. OPTIONAL: Configure physical flash storage writeback targets to offload idle, uncompressed pages
WRITEBACK_DEV="${1:-}" # Optional physical block device or file path
if [ -n "$WRITEBACK_DEV" ]; then
    echo "[*] Enabling physical writeback target: $WRITEBACK_DEV"
    if [ -f "$WRITEBACK_DEV" ] || [ -b "$WRITEBACK_DEV" ]; then
        echo "$WRITEBACK_DEV" > /sys/block/zram0/backing_dev
        # Enable writeback for idle/huge pages to reduce RAM utilization further
        echo "idle" > /sys/block/zram0/writeback || true
        echo "[+] Writeback backend configured successfully."
    else
        echo "[-] ERROR: Invalid backing device/file path: $WRITEBACK_DEV" >&2
    fi
fi

# Verify active memory partitions
echo "[+] Active Swap System Layout:"
swapon --show

echo "[+] zRAM Compression telemetry stats:"
cat /sys/block/zram0/mm_stat || echo "mm_stat check pending mount load."
echo "[+] Setup Complete. zRAM compressed swap is active."
