# System Architecture Document
## Project Anodyne OS: Dual-Target Web-First Desktop Framework

* **Document Version:** 1.0.0
* **System Identifiers:** `WebOS-Appliance` (Bare-Metal Linux) & `Anodyne-Desktop-Android` (Android Container)
* **Author:** Advanced Agentic Architecture Group
* **Status:** In Active Development / Production Hardening
* **Date:** October 2026

---

## 1. High-Level Architectural Topology

Anodyne OS is architected as a **Two-Layer Hybrid Computing Platform**:
1. **The Hard Layer (Native Host Shell):** Provides direct hardware abstraction, display rendering, OS security, process management, and telemetry services.
2. **The Soft Layer (Web Presentation & Compute):** Delivers the user-facing desktop shell, tabbed multitasking, progressive web applications (PWAs), and client-side WebAssembly computation workers.

```mermaid
flowchart TB
    subgraph SoftLayer["Layer 2: Soft Layer (Shared Across Targets)"]
        direction TB
        HUD["Momentum Ambient HUD & Clock"]
        Tabs["Horizontal Multitasking Tab Bar"]
        TopNav["Dynamic TopBar with App Menus"]
        PWAs["First-Party PWAs\n(Files, Settings, Notepad, Dashboard)"]
        WasmPool["WebAssembly Worker Compute Pool\n(SQLite, PDFium, Libarchive, ImageMagick, FFmpeg)"]
        IPCClient["Universal Client Bridge (window.anodyneIPC)"]
    end

    subgraph HardLayerLinux["Target A: Bare-Metal Linux Hard Layer (C++/Qt5)"]
        QtShell["QML Runtime Shell (Shell.qml / TopBar.qml)"]
        WebEngine["QtWebEngine Core (Chromium Compositor)"]
        CBridge["C++ ShellBridge (D-Bus, Telemetry, Tab State)"]
        JobMgr["C++ JobManager (Multithreaded I/O Worker Pool)"]
        KernelSec["Linux Kernel (zRAM zstd + TPM LUKS2 + dm-verity)"]
    end

    subgraph HardLayerAndroid["Target B: Android Host Container (Kotlin)"]
        Activity["MainActivity (Phone Controller & Immersive Mode)"]
        Presentation["DesktopPresentation (Secondary Display Manager)"]
        AWebView["Android System WebView Container"]
        ABridge["Kotlin AndroidSysContext (@JavascriptInterface)"]
        AndroidOS["Android 10+ OS (DisplayManager + Miracast + StatFs)"]
    end

    IPCClient <==>|QWebChannel Protocol| CBridge
    IPCClient <==>|WebMessagePort / JSBridge| ABridge

    CBridge --- QtShell
    CBridge --- JobMgr
    QtShell --- WebEngine
    WebEngine --- KernelSec

    ABridge --- Activity
    Activity --- Presentation
    Presentation --- AWebView
    AWebView --- AndroidOS
```

---

## 2. Hard Layer vs. Soft Layer Separation

### 2.1 The Hard Layer (Native OS & Platform Host)
The Hard Layer is platform-specific and responsible for:
* **Display Output & Window Composition:** Spawning a borderless, full-screen hardware-accelerated canvas. On Linux, this is a kiosk X11 window. On Android, this is an immersive `Presentation` window rendered on secondary screens.
* **Hardware Abstraction & Telemetry:** Querying battery levels, network SSID, disk space, and memory statistics directly from kernel/system APIs without granting raw bash/terminal access to the web UI.
* **Persistent WebView State Management:** Retaining multiple WebViews in memory to achieve instantaneous context switches without reloading web assets.
* **Storage & Memory Hardening:**
  * **Linux:** Managing TPM 2.0 LUKS2 partitions, `dm-verity` root verification, and `/dev/zram0` compression.
  * **Android:** Enforcing WebView sandboxing (`allowFileAccess = false`, `allowContentAccess = false`), origin validation, and scoped storage access.

### 2.2 The Soft Layer (Web Presentation & Compute)
The Soft Layer is 100% portable and operates identically on both targets:
* **Zero-Network Packaging:** All styling (CSS custom properties), typography (system font stack), and iconography (Web Awesome inlined SVG vectors) are stored locally in the package.
* **Tab-Driven Multitasking:** Replaces window-snapping and taskbars with a browser-style horizontal tab registry.
* **WebAssembly Compute Offload:** Heavy computations (PDF rendering, ZIP compression, image conversion, SQLite indexing) run client-side in background Web Workers, completely decoupled from the UI thread.

---

## 3. Detailed Data & Control Flow Sequences

### 3.1 Dynamic Application Menu Registration & Dispatch
When an application tab (e.g. `Notepad`) loads, it registers category-based menus in the native TopBar. Clicks on the TopBar are dispatched directly back to the active page:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant PWA as Active PWA (Notepad)
    participant IPC as window.anodyneIPC
    participant Host as Host Bridge (ShellBridge / AndroidSysContext)
    participant TopBar as TopBar UI (QML / Native)

    PWA->>IPC: send("setAppMenus", "notepad", "Notepad", [File, Edit])
    IPC->>Host: setAppMenus("notepad", categories)
    Host->>TopBar: Emit activeAppMenusChanged()
    TopBar->>TopBar: Repeater renders "File", "Edit" Dropdowns

    User->>TopBar: Clicks "File" -> "Save Note"
    TopBar->>Host: menuActionTriggered("File", "Save Note")
    Host->>PWA: eval("window.onAnodyneMenuAction('File', 'Save Note')")
    PWA->>PWA: Execute saveDocument()
```

---

### 3.2 Tab Closure & Dirty Form Verification
To prevent accidental data loss, closing a tab triggers an introspection routine across all `input` and `textarea` DOM nodes before destroying the view:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant TopBar as Tab Close Button
    participant Shell as Shell Manager (QML / Kotlin)
    participant WebView as Target Tab WebView
    participant Dialog as Native Confirmation Modal

    User->>TopBar: Clicks [x] on active tab
    TopBar->>Shell: closeTab(tabIndex)
    Shell->>WebView: runJavaScript("(checkInputDirtyScript)()")
    WebView-->>Shell: returns isDirty (boolean)

    alt isDirty === true
        Shell->>Dialog: dirtyConfirmDialog.open()
        User->>Dialog: Accepts "Close Anyway"
        Dialog->>Shell: Confirm closeTab(targetIndex)
        Shell->>WebView: Destroy / Recache WebView
    else isDirty === false
        Shell->>WebView: Destroy / Recache WebView
    end
```

---

### 3.3 Android Miracast / Secondary Display Plug & Play
When an Android smartphone detects an external monitor or wireless Miracast connection:

```mermaid
sequenceDiagram
    autonumber
    participant DisplayMgr as Android DisplayManager
    participant MainAct as MainActivity (Phone Screen)
    participant Pres as DesktopPresentation (Secondary Screen)
    participant TV as External Monitor / Miracast TV

    TV-->>DisplayMgr: Display Connected (HDMI / Miracast)
    DisplayMgr->>MainAct: onDisplayAdded(displayId)
    MainAct->>Pres: Instantiate DesktopPresentation(this, display)
    Pres->>TV: show() -> Full-screen Anodyne Desktop
    MainAct->>MainAct: Transition Phone to Virtual Controller Mode
    Note over MainAct: Phone renders virtual glass trackpad & keyboard
```

---

## 4. WebAssembly (WASM) Computation Subsystem

To guarantee responsiveness on 2GB RAM systems, CPU-intensive operations bypass the main JavaScript UI thread using a dedicated WebAssembly worker pool:

```text
web-apps/wasm_cores/
├── wasm_worker_pool.js          # Shared Worker thread pool orchestrator
├── sqlite_core.cpp / .js        # Relational database engine
├── pdfium_core.cpp / .js        # PDF parser & rasterizer
├── libarchive_core.cpp / .js    # Universal archive extractor (ZIP, TAR, 7Z)
├── imagemagick_core.cpp / .js   # Image manipulation engine
├── ffmpeg_core.js               # Audio/video transcode worker
├── tesseract_core.js            # Client-side OCR worker
└── transformers_core.js         # Small offline text embedding model
```

### Worker Pool Pipeline:
1. **Task Submission:** A PWA sends a job request with an `ArrayBuffer` payload to `wasm_worker_pool.js`.
2. **Zero-Copy Transfer:** Buffers are passed as Transferable Objects (`postMessage(msg, [msg.buffer])`) preventing memory duplication.
3. **WASM Execution:** The pre-initialized Emscripten C++ instance processes the data in its linear memory segment (`WebAssembly.Memory`).
4. **Result Resolution:** The worker posts the transformed buffer back to the PWA callback handler.

---

## 5. Security & Isolation Architecture

```mermaid
graph LR
    subgraph Boundary["Zero-Trust Security Perimeter"]
        direction TB
        SecBoot["1. TPM 2.0 PCR Sealing (PCR 0, 4, 7)"]
        Verity["2. dm-verity Immutable Root Tree"]
        NoNet["3. Zero Runtime CDN Dependencies"]
        SandboxedWeb["4. Sandboxed WebEngine / Isolated WebView"]
        SecBridge["5. Type-Checked IPC Gateway"]
    end

    SecBoot --> Verity
    Verity --> SandboxedWeb
    NoNet --> SandboxedWeb
    SandboxedWeb --> SecBridge
```

1. **Immutable Cryptographic Root (`dm-verity`):** The Linux root filesystem is mounted read-only and cryptographically verified at the block level against a SHA-256 hash tree.
2. **TPM 2.0 LUKS2 Key Binding:** User partitions are encrypted with AES-XTS. The encryption key is sealed in the TPM 2.0 hardware and only released if boot firmware, bootloader, and kernel integrity match known measurements (PCRs 0, 4, 7).
3. **Origin & Directory Isolation:**
   * Linux: Assets are resolved strictly via internal `anodyne://` scheme handler; local file browsing requires explicit user intent through the `Files` PWA.
   * Android: `allowFileAccess = false` and `allowContentAccess = false` prevent file exfiltration through injected HTML.
4. **Coordinate Clamping:** Touchpad/mouse coordinates received over wireless casting are sanitized and clamped between `[0.0, 1.0]` prior to dispatch, eliminating UI injection attacks.

---

## 6. Memory & Resource Optimization Model

To achieve fluid operation on 2GB RAM hardware, Anodyne uses a multi-tier memory management strategy:

$$\text{Total Virtual Memory} = \text{RAM}_{\text{Physical}} + 1.5 \times \text{RAM}_{\text{Physical}}\ (\text{zRAM zstd})$$

* **Aggressive Page Compression:** Setting `vm.swappiness = 150` directs the Linux kernel to swap idle anonymous memory pages into the zRAM pool using fast `zstd` compression rather than reclaiming active file caches.
* **WebView Dormancy:** Inactive tabs retain their DOM and JavaScript heap state, but animations and requestAnimationFrame loops are throttled to near-zero CPU consumption.
* **Purged Legacy Watchdogs:** All background monitoring is consolidated into event-driven C++ D-Bus and Qt signal slots, eliminating periodic Python polling daemons.
