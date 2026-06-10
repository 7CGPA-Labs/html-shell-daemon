# Project WebOS Appliance (v1.0) - Core System Shell

Project WebOS Appliance is a lightweight, zero-trust hybrid operating system framework engineered specifically for legacy and resource-constrained hardware (2GB–4GB RAM). This repository contains the **Hard Layer** (native C++ & Qt/QML runtime executable) and the baseline **Soft Layer** (PWA/HTML5 dashboard interface), interconnected via a secure, bidirectional, multi-threaded Inter-Process Communication (IPC) engine.

## Architectural Overview

1. **The System Shell (Hard Layer):** Built on Qt 5 and Chromium (`QtWebEngine`). Runs full-screen, borderless, and strips standard web browser bloat to maximize memory utilization.
2. **The Dashboard (Soft Layer):** A modern, full-viewport "Momentum-style" web dashboard serving as the user baseline. Includes a dynamic clock, localized greeting routines, and application launching cards.
3. **The Secure IPC Bridge:** Powered by `QWebChannel`. Exposes a hardened platform interface (`window.sysContext`) securely to local sandboxed PWA web applications without allowing raw terminal access.
4. **Asynchronous I/O (Job Manager):** Offloads heavy disk and file operations (`copy`, `move`, `delete`, `recycle`) to a native C++ background thread pool. Operations execute concurrently and asynchronously, reporting real-time progress metrics to web client progress-bars even if an application window is dismissed.

---

## Repository Directory Structure

Ensure your project layout matches the structure below before running compilation tasks:

```text
/WebOS-Appliance
├── WebOSAppliance.pro     # Qt Project compilation configuration map
├── /src
│   ├── main.cpp           # System application vector & context initializer
│   ├── ShellBridge.h      # JavaScript-to-C++ gateway declaration
│   ├── ShellBridge.cpp    # Signal router & input intercept verification
│   ├── JobManager.h       # Asynchronous background thread pool declarations
│   └── JobManager.cpp     # Multithreaded I/O worker execution logic
├── /ui
│   ├── Shell.qml          # Hard Layer system layout interface, App Drawer & Spotlight
│   └── qml.qrc            # Qt Resource Manifest (packs QML securely into the binary)
└── /web-apps
    └── /homepage
        ├── index.html     # Semantic dashboard structure & bridge targets
        ├── style.css      # Dark presentation theme tokens & layout animations
        └── script.js      # Dynamic clock matrix & live telemetry listeners

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

*Expected output reference: `Using Qt version 5.x.x*`

---

## Building the Shell Core

The project uses a custom deployment rule inside `WebOSAppliance.pro` that normalizes workspace paths using `$$clean_path()` to ensure robustness during both in-source and out-of-source shadow compiles.

Execute these commands from the root directory of your `/WebOS-Appliance` folder:

```bash
# 1. Clear any old generation caching artifacts or broken Makefiles
make clean
rm -f Makefile

# 2. Evaluate project metadata and generate a clean Makefile
qmake WebOSAppliance.pro

# 3. Build the native machine payload executable
make

```

---

## Running the Application

Once compilation succeeds, a native executable binary artifact named `WebOSAppliance` will be generated in your project root. Run it directly with:

```bash
./WebOSAppliance

```

---

## Operational Verification Guide

Verify that the system meets the **Pass/Fail criteria** for the build:

* **Soft Layer Rendering:** The system boots directly into a dark full-screen frame with a live digital clock cycling second transformations.
* **Bidirectional Telemetry Loop:** 1. Click the **File Viewer** card inside the web interface.
2. The console log outputs a `⚠️ IPC Bridge Request Received` signal.
3. The C++ `JobManager` captures the call, logs a multi-threaded worker creation action (`Queueing Task ID...`), and fires concurrent chunks from $20\% \to 100\%$.
4. The web view captures these updates back across the bridge in real-time, displaying a dynamic blue loading animation bar that turns green upon successful validation.
* **System Overlay Engine:** Pressing **`Ctrl + Space`** toggles the darkened global Spotlight search card wrapper. Typing a general phrase pipes an escaped search URL directly into the browser viewport using Gemini web layouts.
* **Native Component Broadcast:** Clicking the hamburger menu (`☰`) in the Top Bar triggers a signal pass back through the C++ controller, which subsequently instructs QML to slide open the hard-coded Application Drawer.

```
