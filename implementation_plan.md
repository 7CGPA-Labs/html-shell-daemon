# Unified Implementation Plan - Project Anodyne OS

This document provides a single, unified roadmap of the implementation steps across all project milestones.

---

## 🟢 Milestone 1: UI/UX Prototyping (Completed)

### Objectives
1. **Refactor Shell Layout**: Migrate [Shell.qml](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/ui/Shell.qml) to use modular [Theme.qml](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/ui/Theme.qml), [TopBar.qml](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/ui/TopBar.qml), and [AppDrawer.qml](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/ui/components/AppDrawer.qml).
2. **App Registry & Multitasking**: Maintain open PWA instances in a background QML `Repeater` mapping, permitting rapid browser-style tab switches without reloading view states.
3. **Files & Settings PWAs**: Build standalone web configurations under `web-apps/files/` and `web-apps/settings/` mirroring filesystem layouts and network controls.
4. **Spotlight Search**: Elevate `Ctrl+Space` search to support dynamic PWA tab switching and external Google Gemini queries.
5. **Zero-Trust Assets**: Bundle offline inline SVG icons in `web-apps/web-awesome/` for offline verification.

---

## 🟢 Milestone 2: OS Foundation (Completed)

### Objectives
1. **TPM LUKS2 User Volumes**: Script [setup-luks-tpm.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-luks-tpm.sh) to automate partition encryption, sealing the decryption key inside the hardware TPM 2.0 bound to boot PCRs.
2. **Cryptographic dm-verity Boot Blocks**: Script [setup-dm-verity.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-dm-verity.sh) to package read-only root filesystems and calculate SHA-256 block tree hashes.
3. **zRAM zstd Memory Compression**: Script [setup-zram.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-zram.sh) to allocate virtual swap capacity sized dynamically at 1.5x total system RAM using `zstd` engines.
4. **Dual-Wireless Policy Routing**: Script [setup-network-routing.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-network-routing.sh) to route local casting (Wi-Fi Direct) over `wlan1` and default internet over 4G modems (`wwan0`/`rmnet0`).
5. **Kiosk Autostart**: Create `/root/.profile` to trigger X11 server and launch the shell full-screen without cursor pointers (`-nocursor`). Fix VirtualBox `ldlinux.c32` warning states in [fix-bootloader.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/config/bootloaders/isolinux/fix-bootloader.sh).

---

## 🔵 Phase 2.5: Legacy MemFusion Integration & Purge (Completed)

### Objectives
1. **Migrate zRAM Queries to C++ Bridge**:
   - Port ZRAM statistics checking logic from the legacy dialog to [ShellBridge.cpp](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/src/ShellBridge.cpp) via `getZramDiskSize()`, `getZramAlgorithm()`, and `getSystemSwappiness()`.
2. **Settings telemetry panel**:
   - Bind settings javascript to query these C++ slots, displaying real zRAM details instead of simulated mockups.
3. **Optimizations**:
   - Add `sysctl vm.swappiness=150` directly into `setup-zram.sh` to carry over old MemFusion watchdog configurations.
4. **Purge obsolete code**:
   - Delete `memfusionconfig.cpp`, `memfusionconfig.h`, and `memfusion-watchdog.py`.

---

## 🟡 Milestone 3: Hardware Integration & Deployment (Pending)

### Objectives
1. **Automated Lubuntu live-build installer**: Build [build-iso.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/build-iso.sh) compiling the shell binary, packaging assets, and calling live-build to generate `live-image-amd64.hybrid.iso`.
2. **Telephony D-Bus Modem Hook**: Bind QtDBus connections inside `ShellBridge` to map real SMS, telephony call events, and RF switches dynamically.
3. **Namespace Container Jail Orchestration**: Write [launch-desktop-container.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/launch-desktop-container.sh) using `unshare` and `cgroups` v2 CPU/Freezer limits to containerize the desktop files and dynamically issue `SIGSTOP` freezes to standard mobile Gaia UI processes when casting initiates.
4. **Offline Powerwash recovery**: Write [powerwash.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/powerwash.sh) to format secure TPM LUKS volumes offline and reset defaults.
