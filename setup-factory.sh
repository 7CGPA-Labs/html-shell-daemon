#!/bin/bash
# ==============================================================================
# Anodyne OS - Factory Workspace Staging Setup Script
# ==============================================================================
set -euo pipefail

# Default workspace directory is sibling to the repository
DEFAULT_WORKSPACE="../WebOS-Appliance-Factory"
WORKSPACE="${1:-$DEFAULT_WORKSPACE}"

echo "===================================================="
echo "    ANODYNE OS - FACTORY WORKSPACE SETUP SCRIPT     "
echo "===================================================="
echo "[*] TARGET WORKSPACE: $WORKSPACE"

# 1. Initialize directory layout if it doesn't exist
if [ ! -d "$WORKSPACE" ]; then
    echo "[*] Target workspace does not exist. Creating directory..."
    mkdir -p "$WORKSPACE"
fi

# 2. Stage live-build configurations
echo "[*] Copying configurations and scripts..."
mkdir -p "$WORKSPACE/config/bootloaders/isolinux"
mkdir -p "$WORKSPACE/config/package-lists"
mkdir -p "$WORKSPACE/config/hooks"
mkdir -p "$WORKSPACE/config/includes.chroot/etc/systemd/system"
mkdir -p "$WORKSPACE/config/includes.chroot/etc/inittab.d"
mkdir -p "$WORKSPACE/config/includes.chroot/etc/cron.daily"
mkdir -p "$WORKSPACE/config/includes.chroot/root"
mkdir -p "$WORKSPACE/config/includes.chroot/usr/bin"

# Copy base config templates
cp -f factory-config/build-image.sh "$WORKSPACE/"
cp -f factory-config/config/common "$WORKSPACE/config/"
cp -f factory-config/config/bootstrap "$WORKSPACE/config/"
cp -f factory-config/config/chroot "$WORKSPACE/config/"
cp -f factory-config/config/binary "$WORKSPACE/config/"
cp -f factory-config/config/source "$WORKSPACE/config/"
cp -f factory-config/config/bootloaders/isolinux/isolinux.cfg "$WORKSPACE/config/bootloaders/isolinux/"
cp -f factory-config/config/package-lists/appliance-core.list.chroot "$WORKSPACE/config/package-lists/"
cp -f factory-config/config/hooks/*.chroot "$WORKSPACE/config/hooks/"

# Copy system service definitions
cp -f factory-config/config/includes.chroot/etc/systemd/system/anodyne-kiosk.service "$WORKSPACE/config/includes.chroot/etc/systemd/system/"
cp -f factory-config/config/includes.chroot/etc/inittab.d/anodyne-kiosk.conf "$WORKSPACE/config/includes.chroot/etc/inittab.d/"
cp -f factory-config/config/includes.chroot/etc/cron.daily/anodyne-housekeeper "$WORKSPACE/config/includes.chroot/etc/cron.daily/"

# Copy kiosk environment parameters
cp -f factory-config/config/includes.chroot/root/.xinitrc "$WORKSPACE/config/includes.chroot/root/"
cp -f factory-config/config/includes.chroot/root/.profile "$WORKSPACE/config/includes.chroot/root/"

# Copy system maintenance scripts
cp -f factory-config/config/includes.chroot/usr/bin/anodyne-*.sh "$WORKSPACE/config/includes.chroot/usr/bin/"

# 3. Apply executable permissions
echo "[*] Setting execution permissions..."
chmod +x "$WORKSPACE/build-image.sh"
chmod +x "$WORKSPACE/config/includes.chroot/usr/bin/anodyne-kiosk-start.sh"
chmod +x "$WORKSPACE/config/includes.chroot/usr/bin/anodyne-housekeeper.sh"
chmod +x "$WORKSPACE/config/includes.chroot/usr/bin/anodyne-installer.sh"
chmod +x "$WORKSPACE/config/includes.chroot/usr/bin/anodyne-powerwash.sh"
chmod +x "$WORKSPACE/config/includes.chroot/etc/cron.daily/anodyne-housekeeper"

echo "===================================================="
echo "[+] SUCCESS: Factory workspace is successfully staged."
echo "    You can now cd into $WORKSPACE and run ./build-image.sh"
echo "===================================================="
