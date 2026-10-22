# Milestone Task List - Project Anodyne OS

For the full detailed roadmap and architecture specifications, see [MILESTONES.md](file:///home/gagan/Projects/WebOS-Appliance/docs/MILESTONES.md).

## Current Phase: Milestone 6 (Miracast & Remote Display Convergence)

- [x] **Milestone 1: Core Shell & UI/UX Foundations**
  - [x] Minimalist QML Shell, TopBar, and App Drawer
  - [x] In-memory tabbed multitasking app registry
  - [x] Core PWAs (Homepage, Files, Settings) with offline Web Awesome vector assets
  - [x] Global Spotlight command search palette (`Ctrl+Space`)
- [x] **Milestone 2: Hardened Appliance OS Foundation & Telemetry**
  - [x] TPM 2.0 PCR-bound LUKS2 storage partition
  - [x] Immutable dm-verity read-only root hash tree
  - [x] Compressed zRAM with zstd engine and vm.swappiness=150
  - [x] Linux kernel telemetry bridge in C++ `ShellBridge`
  - [x] Legacy MemFusion codebase purge
- [x] **Milestone 3: Android DeX-like Desktop Container Pivot**
  - [x] Native Kotlin Android host container (`Anodyne-Desktop-Android`)
  - [x] Hardware-accelerated WebView desktop container
  - [x] `AndroidSysContext` native JS bridge
  - [x] `DesktopPresentation` secondary display manager
- [x] **Milestone 4: Dual-Bridge Convergence, Dynamic Menus & WASM Cores**
  - [x] Unified single-file PWA assets across both repositories
  - [x] Dual-runtime bridge protocol (`window.anodyneIPC`)
  - [x] Dynamic TopBar application menus registered by PWAs
  - [x] Tab context menu (Reload, Duplicate, Close, Close Others)
  - [x] Dirty-tab unsaved changes prompt dialog
  - [x] WebAssembly computation worker pool
- [x] **Milestone 5: Codebase Sanitization & Non-Touchscreen Refinement**
  - [x] Stripped out `/tmp/touchscreen_detected` C++ file watcher
  - [x] Removed QML `MultiPointTouchArea` touch scaling heuristics
  - [x] Removed touch status visual indicators from `TopBar.qml`
  - [x] Clean compilation and GitHub Actions CI pass
- [/] **Milestone 6: Miracast & Remote Display Convergence**
  - [x] `DisplayManager.DisplayListener` external display detection
  - [x] Remote server IPC foundation (`DesktopRemoteServer.kt`)
  - [ ] Mobile virtual trackpad & controller mode on primary screen
  - [ ] WebRTC wireless video streaming pipeline fallback
  - [ ] Clamped remote pointer navigation
- [ ] **Milestone 7: Production Release & Packaging**
  - [ ] Automated live-build hybrid ISO generation
  - [ ] Signed Android APK/AAB distribution
  - [ ] Offline factory powerwash utility
  - [ ] Automated end-to-end integration test suite
