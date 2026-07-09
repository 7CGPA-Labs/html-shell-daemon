#!/bin/bash
# ==============================================================================
# Anodyne OS - Live-Build Bootloader Warning Fix & Cache Purge Tool
# ==============================================================================
# Solves the "ldlinux.c32" bootloader warning when loading built ISOs in virtualbox.
# ==============================================================================

set -euo pipefail

# Pathing parameters
ISOLINUX_DEST="config/bootloaders/isolinux"
SYS_SYSFILES_PATH="/usr/lib/syslinux/modules/bios"
SYS_ISOLINUX_PATH="/usr/lib/ISOLINUX"

echo "[*] Initializing factory bootloader repair sequence..."

# 1. Purge hidden build cache directories
echo "[*] Purging live-build assembly flags and cache directories..."
rm -rf .build/
rm -rf local/

# 2. Ensure target isolinux directory exists
mkdir -p "$ISOLINUX_DEST"

# 3. Locate and verify system syslinux installation
echo "[*] Checking for system bootloader modules..."
if [ ! -d "$SYS_SYSFILES_PATH" ] || [ ! -d "$SYS_ISOLINUX_PATH" ]; then
    echo "[-] WARNING: System bootloader packages missing. Installing syslinux and isolinux..."
    apt-get update && apt-get install -y syslinux syslinux-common isolinux
fi

# 4. Copy raw bios loaders directly from host system to bypass compiler warning
echo "[*] Copying isolinux binary assets into build partition bounds..."

# Core loader
cp -f "$SYS_ISOLINUX_PATH/isolinux.bin" "$ISOLINUX_DEST/"

# Core modules required to avoid the c32 load failures
c32_modules=(ldlinux.c32 vesamenu.c32 libcom32.c32 libutil.c32 chain.c32 reboot.c32 poweroff.c32)

for mod in "${c32_modules[@]}"; do
    SRC_FILE="$SYS_SYSFILES_PATH/$mod"
    if [ -f "$SRC_FILE" ]; then
        cp -f "$SRC_FILE" "$ISOLINUX_DEST/"
        echo "  [+] Copied: $mod"
    else
        echo "  [-] ERROR: Source module missing: $SRC_FILE" >&2
        exit 1
    fi
done

# 5. Generate pristine isolinux configuration loader file
echo "[*] Writing default isolinux boot configurations..."
cat <<EOF > "$ISOLINUX_DEST/isolinux.cfg"
default vesamenu.c32
prompt 0
timeout 50

menu title Project Anodyne OS Boot Kiosk
menu background 

label live
    menu label Start Anodyne OS (dm-verity secure boot)
    kernel /live/vmlinuz
    append initrd=/live/initrd.img boot=live components quiet splash systemd.verity=1

label live-failsafe
    menu label Start Anodyne OS (Failsafe Mode)
    kernel /live/vmlinuz
    append initrd=/live/initrd.img boot=live components xforcevesa nomodeset noapic noacpi nosplash irqpoll
EOF

echo "[+] Bootloader configuration mapped. Ready for live-build factory execution."
