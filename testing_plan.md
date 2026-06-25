# Unified Verification & Testing Plan - Project WebOS Appliance

This document provides complete instructions to compile, verify, and dry-run test the features implemented in Milestones 1 and 2, including the ZRAM metrics query integration.

---

## 💻 Phase 1: Native Lubuntu Shell Compilation

Execute these steps on your Lubuntu machine to install the required development kits and compile the C++ binary:

### 1. Install Qt 5 and WebEngine dependencies
Open your Lubuntu terminal and run:
```bash
sudo apt update
sudo apt install -y build-essential qt5-qmake qtbase5-dev qtdeclarative5-dev qtwebengine5-dev \
                    qml-module-qtquick2 qml-module-qtquick-window2 qml-module-qtquick-layouts \
                    qml-module-qtquick-controls qml-module-qtquick-dialogs \
                    qml-module-qtwebchannel qml-module-qtwebengine
```

### 2. Compile the Shell Core
Navigate to the repository folder on your machine:
```bash
cd html-shell-daemon

# Clean old artifacts
make clean || true
rm -f Makefile

# Generate Makefile
qmake WebOSAppliance.pro

# Compile binary
make -j$(nproc)
```
*Verification Check:* Confirm that a compiled binary named `WebOSAppliance` exists in the folder.

### 3. Run the Shell
Start the system shell locally:
```bash
./WebOSAppliance
```

---

## 📱 Phase 2: Soft Layer & PWA Multitasking Verification

With the shell running, verify the tab-switching UX:

### 1. Browser-style Tab Multitasking
- **Action**: Click the hamburger menu (`☰`) on the top bar to slide open the App Drawer. Click **File Viewer**.
- **Result**: A new tab labeled "Files" should spawn below the TopBar. The viewport should display the local directory structure.
- **Action**: Open the drawer again, and click **OS Settings**.
- **Result**: A second tab labeled "Settings" spawns next to "Files" and switches active focus.
- **Action**: Input credentials or change a slider inside the "Settings" tab, then click back to the "Home Dashboard" or "Files" tab, and then return to "Settings".
- **Result**: Verify that slider positions and logs are preserved. The app stays running in the background without reloading.

### 2. Spotlight Search overlay (`Ctrl + Space`)
- **Action**: Press `Ctrl + Space` on your keyboard.
- **Result**: The Spotlight search overlay should fade in and slide down.
- **Action**: Type `files` or `settings` and press **Enter**.
- **Result**: The search box closes and switches active tab focus directly.
- **Action**: Press `Ctrl + Space`, type a random search term (e.g. `Wayland compositor cgroups`), and press **Enter**.
- **Result**: Spawns a new tab labeled "Gemini: [Query]" and redirects the viewport to the Google Gemini interface. Verify that you can click the `×` button on the tab to close it.

### 3. Zero-Trust Local SVG Icons
- **Action**: Navigate to `web-apps/web-awesome/test-svg.html` by typing `web-awesome/test-svg.html` inside the Spotlight Search.
- **Result**: Confirm that the grid renders all 7 packaged offline SVGs (Drawer, Calendar, WiFi, Battery, Gear, Folder, Terminal) without hitting external networks.

---

## 🔌 Phase 3: Telephony, System Metrics & C++ Bridge Telemetry

### 1. Asynchronous I/O Thread Pool (File Viewer)
- **Action**: Switch to the **Files** PWA tab and click **Backup Files to USB**.
- **Result**: 
  1. Look at your terminal shell output. You should see C++ debug logging: `⚠️ IPC Bridge Request Received -> Action: files` and `JobManager: Queueing Task ID [...] type: copy`.
  2. The QML TopBar displays a progress status (e.g., `Backup: 20%`).
  3. The File PWA footer displays a yellow progress percentage tracking the copy worker increments.
  4. Once complete, the TopBar updates to `Backup Complete` (fading out after 4 seconds) and the PWA footer turns green with success notifications.

### 2. Real Host ZRAM & Swappiness Telemetry (Settings)
- **Action**: Open the **Settings** PWA tab while running on Lubuntu (after setting up zRAM).
- **Result**: Verify the bottom "oFono Telephony Engine & System Metrics" grid:
  - **zRAM Size**: Displays the actual capacity in MB read from `/sys/block/zram0/disksize` (e.g. `1536 MB` or `2048 MB`).
  - **zRAM Engine**: Displays the active algorithm engine from `/sys/block/zram0/comp_algorithm` (e.g. `zstd` or `lzo-rle`).
  - **Swappiness**: Displays the current kernel swappiness from `/proc/sys/vm/swappiness` (should be `150` if zram script has executed).

### 3. Hardware sliders & oFono Bindings
- **Action**: Move the **Screen Brightness** and **Volume** sliders.
- **Result**: The settings log displays `/sys/class/backlight/brightness set to: X%` and master volume set to `Y%`.
- **Action**: Watch the logs at the bottom.
- **Result**: Verify CPU load fluctuates every 4 seconds, and mock D-Bus telephony carrier events and SMS logs print every 25 seconds.

---

## 🐧 Phase 4: OS Foundation Setup Scripts (Dry-run testing)

Because setup scripts configure kernel-level spaces, test them via dry-runs and syntax verification:

### 1. zRAM zstd swap Allocation
Run the script to check if the zRAM configurations map correctly to memory space:
```bash
# Syntax Check
bash -n scripts/setup-zram.sh

# Run allocation and check if comp_algorithm updates to zstd and swappiness to 150
sudo ./scripts/setup-zram.sh
```
*Verification Check:* Run `cat /sys/block/zram0/comp_algorithm` and verify `[zstd]` is active. Run `cat /proc/sys/vm/swappiness` and verify output is `150`.

### 2. Network Policy Routing Table
Verify policy parameters are added to route tables:
```bash
# Syntax Check
bash -n scripts/setup-network-routing.sh

# Verify routing table registry insertion
grep "casting" /etc/iproute2/rt_tables
```

### 3. dm-verity cryptographic packaging
Verify dm-verity packages mock SquashFS trees and generates hash files:
```bash
# Syntax Check
bash -n scripts/setup-dm-verity.sh

# Execute build block run
sudo ./scripts/setup-dm-verity.sh
```
*Verification Check:* Check if a hash block device is outputted in `/tmp/webos_build/rootfs.verity_hash` and matches the hash in `/tmp/webos_build/verity_metadata.json`.

### 4. TPM LUKS User partition
Verify cryptsetup maps correctly:
```bash
# Syntax Check
bash -n scripts/setup-luks-tpm.sh
```
