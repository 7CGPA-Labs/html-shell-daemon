# Project Anodyne OS (v1.0) - Core System Shell

Project Anodyne OS is a lightweight, zero-trust hybrid operating system framework engineered specifically for legacy and resource-constrained hardware (2GB–4GB RAM). This repository contains the **Hard Layer** (native C++ & Qt/QML runtime executable) and the baseline **Soft Layer** (PWA/HTML5 dashboard interface), interconnected via a secure, bidirectional, multi-threaded Inter-Process Communication (IPC) engine.

## Architectural Overview

1. **The System Shell (Hard Layer):** Built on Qt 5 and Chromium (`QtWebEngine`). Runs full-screen, borderless, and strips standard web browser bloat to maximize memory utilization.
2. **Tabbed Multitasking (App Registry):** Traditional taskbars are discarded. Browser tabs serve as the core manager; switching active tabs corresponds directly to switching application contexts. WebEngine instances are preserved in the QML background to maintain state without reloading.
3. **The Secure IPC Bridge:** Powered by `QWebChannel`. Exposes a hardened platform interface (`window.sysContext`) securely to local sandboxed PWA web applications without allowing raw terminal access.
4. **Asynchronous I/O (Job Manager):** Offloads heavy disk and file operations to a native C++ background thread pool. Operations execute concurrently and asynchronously, reporting real-time progress metrics to web client progress-bars.
5. **Cross-Userland Bridge Daemon:** Simulates folder-based outbox/inbox IPC (`/var/lib/anodyne/ipc/`) bridging the isolated containerized desktop PWA scripts with the host Linux kernel (writing backlight brightness to sysfs and cellular network swaps to oFono via D-Bus).
6. **Zero-Trust Asset Packaging:** System apps and icon layouts are packaged locally offline using zero-network Web Awesome inline SVG vectors for maximum security compliance.

---

## Repository Directory Structure

Ensure your project layout matches the structure below before running compilation tasks:

```text
/Anodyne-Appliance
├── AnodyneOS.pro          # Qt Project compilation configuration map
├── /src
│   ├── main.cpp                # System application vector & context initializer
│   ├── ShellBridge.h           # JavaScript-to-C++ gateway declaration
│   ├── ShellBridge.cpp         # Signal router & input intercept verification
│   ├── JobManager.h            # Asynchronous background thread pool declarations
│   └── JobManager.cpp          # Multithreaded I/O worker execution logic
├── /ui
│   ├── Shell.qml               # Hard Layer system layout interface with tabbed multitasking
│   ├── TopBar.qml              # Modular system top bar showing notifications & inputs
│   ├── Theme.qml               # System colors, margins, and tab styling parameters
│   ├── qml.qrc                 # Qt Resource Manifest
│   ├── /components
│   │   ├── AppDrawer.qml       # Sliding app drawer wrapper
│   │   ├── AppDrawerItem.qml   # Item delegate for drawers
│   │   ├── StatusIndicator.qml  # Wifi and Battery icon indicators
│   │   └── TopBarIcon.qml      # Navigation control items
│   └── /icons                  # Local UI SVG files (drawer, battery, wifi, calendar, etc.)
├── /web-apps
│   ├── /homepage
│   │   ├── index.html          # Semantic dashboard structure & bridge targets
│   │   ├── style.css           # Dark presentation theme tokens
│   │   └── script.js           # Dynamic clock matrix & live telemetry listeners
│   ├── /files
│   │   ├── index.html          # File manager displaying dual-userland filesystem mounts
│   │   ├── style.css           # Table views & layout transitions
│   │   └── script.js           # Navigation click mockups & C++ JobManager hooks
│   ├── /settings
│   │   ├── index.html          # Unified Control showing 4G, APN forms & hardware sliders
│   │   ├── style.css           # Grid panels, toggle slider switches, power controls
│   │   └── script.js           # Sliders binding to sysfs/ALSA and oFono dbus simulators
│   └── /web-awesome
│       ├── icons.js            # Offline inline SVG icon package
│       └── test-svg.html       # Verification page rendering inline SVGs locally
├── /scripts
│   ├── ipc-bridge-daemon.py    # Python daemon simulating cross-userland folder IPC
│   ├── setup-luks-tpm.sh       # Encrypts user partition and locks key in TPM 2.0
│   ├── setup-dm-verity.sh      # Packs read-only root system and formats block verification hashes
│   ├── setup-zram.sh           # Allocates compressed zstd memory swap space
│   └── setup-network-routing.sh # Segregates Wi-Fi Direct casting from 4G WAN interfaces
└── /config
    ├── /bootloaders/isolinux
    │   └── fix-bootloader.sh   # Cleans live-build caches and rebuilds syslinux modules
    └── /includes.chroot/root
        └── dot_profile         # Automatic X11 launcher at root login on tty1
```

---

## OS Foundation Setup Scripts (Milestone 2)

We provide modular system shell scripts to configure kernel-level memory management, partition security, network policy rules, and automated ISO bootloader construction:

### 1. Cryptographic User Partition Setup (TPM-Bound LUKS2)
`setup-luks-tpm.sh` formats the target partition as LUKS2 and seals a cryptographically secure key file inside the Trusted Platform Module (TPM 2.0). It links validation to PCR registers 0, 4, and 7 to guarantee that if bootloader or kernel files are modified, the TPM refuses to release the crypt-key.
```bash
sudo ./scripts/setup-luks-tpm.sh /dev/sdb3
```

### 2. Read-Only Root Integrity Setup (dm-verity)
`setup-dm-verity.sh` packages the container directory, computes SHA-256 block tree hashes, formats a hash device, and exports command-line boot parameters:
```bash
sudo ./scripts/setup-dm-verity.sh
```

### 3. Memory swap compression (zRAM with zstd)
`setup-zram.sh` initializes `/dev/zram0`, sets the compression engine to `zstd`, allocates 1.5x capacity of RAM, and activates swap at priority 32767. This prevents out-of-memory lockups on resource-constrained devices:
```bash
sudo ./scripts/setup-zram.sh
```

### 4. Dual-Wireless network policy routing
`setup-network-routing.sh` creates separate routing configurations for high-bitrate wireless casting (Wi-Fi Direct) and outbound 4G cellular data. Wi-Fi Direct traffic routes through `wlan1` (or local link interface), while WAN requests route over `wwan0`/`rmnet0`:
```bash
sudo ./scripts/setup-network-routing.sh wwan0 wlan1
```

### 5. Live-Build isolinux modules warning fix
`fix-bootloader.sh` solves the legacy VirtualBox `ldlinux.c32` load failure by purging hidden build caches and copying raw isolinux files from the host system:
```bash
./config/bootloaders/isolinux/fix-bootloader.sh
```

---

## Prerequisites (Lubuntu / Debian Native Environment)

To compile and execute this project natively, your development environment must have the core compilation utilities and specific dynamic Qt runtime framework packages installed.

Open your terminal (`Ctrl + Alt + T`) and execute the following installation layers:

```bash
# 1. Update your package database index
sudo apt update

# 2. Install essential compilers and basic Qt5 building tooling
sudo apt install -y build-essential qt5-qmake qtbase5-dev qtdeclarative5-dev

# 3. Install the specialized Chromium WebEngine core development kits
sudo apt install -y qtwebengine5-dev

# 4. Install dynamic QML module plugins required by the UI runtime engine
sudo apt install -y qml-module-qtquick2 \
                    qml-module-qtquick-window2 \
                    qml-module-qtquick-layouts \
                    qml-module-qtquick-controls \
                    qml-module-qtquick-dialogs \
                    qml-module-qtwebchannel \
                    qml-module-qtwebengine
```

### Verification Check

Ensure your native build system points to the valid Qt 5 platform binaries by running:

```bash
qmake --version
```

---

## Building the Shell Core

Execute these commands from the root directory of your `/Anodyne-Appliance` folder:

```bash
# 1. Clear any old generation caching artifacts or Makefiles
make clean
rm -f Makefile

# 2. Evaluate project metadata and generate a clean Makefile
qmake AnodyneOS.pro

# 3. Build the native machine payload executable
make
```

---

## Running the Application

Once compilation succeeds, a native executable binary artifact named `AnodyneOS` will be generated in your project root. Run it directly with:

```bash
./AnodyneOS
```

To test the cross-userland bridge protocol concurrently on the host machine:

```bash
python3 scripts/ipc-bridge-daemon.py
```
