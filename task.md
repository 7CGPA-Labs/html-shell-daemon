# Task List - ZRAM Logic Integration & Legacy Purge

- [ ] Add zRAM hardware monitoring methods in C++ `ShellBridge.h` and `ShellBridge.cpp`
- [ ] Update Settings PWA to show real zRAM metrics (swappiness, algorithm, allocated capacity) via `window.sysContext`
- [ ] Add `vm.swappiness` configurations to the network routing or zRAM setup script (`scripts/setup-zram.sh`)
- [ ] Remove `src/memfusionconfig` declarations from `AnodyneOS.pro`
- [ ] Delete `src/memfusionconfig.h`, `src/memfusionconfig.cpp`, and `src/memfusion-watchdog.py`
- [ ] Verify build references are clean
