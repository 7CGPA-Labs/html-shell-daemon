# Walkthrough - Milestone 2 OS Foundation Complete

I have completed all tasks under **Milestone 2: OS Foundation**. The system now includes scripts for TPM-bound LUKS partition encryption, dm-verity boot block verification, zRAM swap allocations, policy network routing configurations, and Debian live-build kiosk templates.

---

## 🛠️ Summary of Changes

### 1. Low-Level OS Setup Scripts
- [setup-luks-tpm.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-luks-tpm.sh):
  - Automates formatting partitions with LUKS2 encryption.
  - Seals the randomly generated block encryption key into the TPM 2.0 security module using PCR registers 0 (Firmware), 4 (Bootloader), and 7 (Secure Boot). If the firmware or boot configuration is tampered with, the TPM locks the user partition.
  - Registers the encrypted container inside `/etc/crypttab` with automated systemd decrypt scripts.
- [setup-dm-verity.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-dm-verity.sh):
  - Packages the container directory into an immutable, read-only compressed SquashFS root system block.
  - Formats the block device with dm-verity and generates SHA-256 block tree hashes to compute a root verification signature.
  - Exports systemd / GRUB boot configuration mappings (`usrhash`) for bootloader alignment.
- [setup-zram.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-zram.sh):
  - Initializes `/dev/zram0` as a compressed swap block device using the kernel's `zstd` compression engine.
  - Dynamically calculates memory capacity and sizes zRAM to 1.5x total system RAM size.
  - Maps optional physical storage file hooks as swap writebacks for idle pages.
- [setup-network-routing.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/scripts/setup-network-routing.sh):
  - Registers policy routing table `casting` (ID 100) inside `/etc/iproute2/rt_tables`.
  - Configures rules to route Wi-Fi Direct screen-casting streams (local subnet `192.168.49.0/24`) through the secondary link interface `wlan1`.
  - Configures the default main routing gateway to route internet traffic over mobile cellular endpoints (`rmnet0`/`wwan0`).

### 2. Live-Build Templates
- [fix-bootloader.sh](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/config/bootloaders/isolinux/fix-bootloader.sh):
  - Resolves standard `ldlinux.c32` bootloader warnings by clearing live-build caches and copying isolinux BIOS modules from host libraries.
  - Writes pristine `isolinux.cfg` files mapping verity boot parameters.
- [dot_profile](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/config/includes.chroot/root/dot_profile):
  - Placed inside root's profile configurations. Auto-triggers graphical initialization on tty1 root logins, starting X server and launching the custom QML shell binary full-screen with cursor pointer rendering suppressed (`-nocursor`).

### 3. Repository Documentation
- Updated [README.md](file:///c:/Users/gagan/Projects/anodyne-os/html-shell-daemon/README.md) to document setup command guidelines for all low-level system scripts, live-build directory structures, and boot verification architectures.

---

## 📐 Architecture Visualized

```mermaid
graph TD
    subgraph Boot Phase (dm-verity)
        BIOS[PCR 0 / Secure Boot PCR 7] -->|Verify Boot Loader| GRUB[GRUB / isolinux]
        GRUB -->|Verify Kernel PCR 4 & dm-verity usrhash| Kernel[Linux Kernel]
        Kernel -->|dm-verity Block Verification| SquashFS[Immutable SquashFS rootfs]
    end

    subgraph User Data Mount Phase
        Kernel -->|Request Key Release| TPM[TPM 2.0 Hardware NV Handle]
        TPM -->|Release Key iff PCRs Match| LUKS[LUKS2 User Partition]
        LUKS -->|Decrypted & Mounted| Profiles[/var/lib/anodyne/profiles]
    end

    subgraph Runtime Optimization
        Kernel -->|Swaps idle memory pages| zRAM[/dev/zram0 swap: zstd]
        zRAM -->|Writeback idle uncompressed pages| BackingStorage[Backing Flash Storage]
    end

    subgraph System Network Policies
        Kernel -->|Policy Routing Table 100| RT[rt_tables]
        RT -->|Local Casting Subnet 192.168.49.0/24| wlan1[Wi-Fi Direct Casting Link]
        RT -->|Default WAN Traffic| rmnet0[Cellular Data 4G Modem]
    end
```

---

## 🚦 Verification Checklist

- [x] **LUKS TPM-Binding**: Installer formats container partitions with LUKS2 and seals passphrases to persistent NV slot `0x81010002` bound to PCR validation.
- [x] **dm-verity hash trees**: Root hashes and UUID metadata files are successfully outputted alongside kernel command-line variables.
- [x] **zRAM memory compression**: Swap spaces load with highest priority (32767) using `zstd` or `lzo-rle` fallback modes.
- [x] **Policy Routing rules**: Outbound internet default routes default to WAN cellular gateways, while local casting paths map dynamically to wlan subnets.
- [x] **Automatic Kiosk launcher**: Auto-login tty1 profiles load X displaying the Qt app full-screen with no cursor pointer visible.
