#!/usr/bin/bash
set -e 

SOURCE_DIR="${SOURCE_DIR:-../WebOS-Appliance}"
FACTORY_DIR=$(pwd)

echo "===================================================="
echo "   PROJECT ANODYNE OS - HARDENED FACTORY LINE  "
echo "===================================================="

if [ ! -f "$SOURCE_DIR/AnodyneOS" ]; then
    echo "❌ ERROR: Compiled shell binary not found at $SOURCE_DIR/AnodyneOS"
    exit 1
fi

echo "📦 Step 1: Staging native application payloads..."
mkdir -p config/includes.chroot/usr/bin/web-apps
cp -f "$SOURCE_DIR/AnodyneOS" config/includes.chroot/usr/bin/
cp -rf "$SOURCE_DIR/web-apps/"* config/includes.chroot/usr/bin/web-apps/
find "$SOURCE_DIR/scripts/" -maxdepth 1 -type f -exec cp -f {} config/includes.chroot/usr/bin/ \;

echo "🛠️ Step 2: Harvesting host bootloaders and staging configuration map..."
mkdir -p config/bootloaders/isolinux

# Locate primary boot sector on host
HOST_ISOLINUX=$(find /usr/lib -name "isolinux.bin" 2>/dev/null | head -n 1)
if [ -z "$HOST_ISOLINUX" ]; then
    echo "❌ ERROR: Bootloader components missing on host."
    echo "Please run: sudo apt install -y isolinux syslinux-common"
    exit 1
fi
cp -f "$HOST_ISOLINUX" config/bootloaders/isolinux/

# Harvest the full cluster of required Syslinux COM32 companion modules
SYS_BIOS_DIR="/usr/lib/syslinux/modules/bios"
if [ -d "$SYS_BIOS_DIR" ]; then
    cp -f "$SYS_BIOS_DIR/ldlinux.c32" config/bootloaders/isolinux/
    cp -f "$SYS_BIOS_DIR/vesamenu.c32" config/bootloaders/isolinux/
    cp -f "$SYS_BIOS_DIR/libcom32.c32" config/bootloaders/isolinux/
    cp -f "$SYS_BIOS_DIR/libutil.c32" config/bootloaders/isolinux/
else
    cp -f $(find /usr/lib -name "ldlinux.c32" | head -n 1) config/bootloaders/isolinux/
    cp -f $(find /usr/lib -name "vesamenu.c32" | head -n 1) config/bootloaders/isolinux/
    cp -f $(find /usr/lib -name "libcom32.c32" | head -n 1) config/bootloaders/isolinux/
    cp -f $(find /usr/lib -name "libutil.c32" | head -n 1) config/bootloaders/isolinux/
fi

# Create structural empty bootlogo placeholder archive
echo -n "" | cpio -o -H newc > config/bootloaders/isolinux/bootlogo

# Verify local configuration file is in place
if [ ! -f "config/bootloaders/isolinux/isolinux.cfg" ]; then
    echo "❌ ERROR: config/bootloaders/isolinux/isolinux.cfg is missing!"
    exit 1
fi

echo "✅ Complete bootloader configuration array successfully staged."

echo "🔒 Step 3: Enforcing executive system file permissions..."
chmod +x config/includes.chroot/root/.profile || true
chmod +x config/includes.chroot/root/.xinitrc || true
chmod +x config/includes.chroot/usr/bin/AnodyneOS
chmod +x config/includes.chroot/usr/bin/*.sh || true

echo "🧹 Step 4: Purging temporary binary tracking states..."
# Cleans only the packaging wrapper layer so your compiled chroot filesystem isn't touched
sudo lb clean --binary

echo "🚀 Step 5: Synthesizing bootable operating system partitions..."
sudo lb build
