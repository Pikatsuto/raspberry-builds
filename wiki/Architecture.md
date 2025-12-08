# Architecture

Understanding how the Raspberry Pi Image Builder works under the hood.

## Overview

The build system creates hybrid images by combining:
- **Raspberry Pi OS** - Boot partition with firmware, bootloader, and config
- **Debian ARM64** - Root filesystem with full userspace
- **RaspiOS Packages** - Kernel and firmware installed via APT (with auto-update support)
- **Custom Services** - Modular components composed during build

The result is a Debian system with full Raspberry Pi hardware support and automatic kernel/firmware updates.

## Design Philosophy

### Why Hybrid Images?

**Problem**: Raspberry Pi uses proprietary firmware and the RP1 chip for I/O (Ethernet, USB, GPIO). Standard Debian ARM64 kernels lack these drivers.

**Solution**: Keep Raspberry Pi OS boot partition and kernel packages, but use Debian for everything else.

**Benefits**:
- Full hardware support (RP1, WiFi, Bluetooth, GPIO)
- Automatic kernel/firmware updates via `apt upgrade`
- Debian's package ecosystem and stability
- No manual kernel compilation or firmware management

### Why Install Packages in QEMU?

**Traditional Approach**:
- Merge images
- Chroot into ARM64 rootfs from x86_64 host
- Use qemu-user-static for emulation
- Install packages

**Our Approach**:
- Install packages in native ARM64 QEMU VM **before** merge
- Merge pre-configured Debian image with RaspiOS boot

**Advantages**:
- **Simpler**: No complex chroot setup
- **Faster**: Native ARM64 execution, no user-mode overhead
- **Cleaner**: Merge script just copies files, no package management
- **Reproducible**: Same environment every build

## Build Pipeline

### 4-Stage Process

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Download & Prepare                                 │
├─────────────────────────────────────────────────────────────┤
│ • Download RaspiOS Lite image                               │
│ • Download Debian cloud/generic ARM64 image                 │
│ • Parse service configuration                               │
│ • Resolve service dependencies                              │
│ • Combine setup scripts from all services                   │
│ • Create setup.iso (contains setup scripts + files)         │
│ • Generate cloud-init seed.img OR inject first-boot service │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: QEMU Setup (ARM64 VM)                              │
├─────────────────────────────────────────────────────────────┤
│ • Boot Debian ARM64 in QEMU                                 │
│ • Cloud-init or first-boot service creates user             │
│ • Mount setup.iso                                           │
│ • Execute combined setup.sh:                                │
│   - Add RaspiOS APT repository + pinning                    │
│   - Install RaspiOS kernel packages (raspberrypi-kernel)    │
│   - Install RaspiOS firmware packages                       │
│   - Install service packages (docker, incus, etc.)          │
│   - Copy configuration files to /etc/setupfiles/            │
│   - Copy first-boot scripts                                 │
│ • Auto-shutdown when complete                               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: Merge                                              │
├─────────────────────────────────────────────────────────────┤
│ • Call merge-debian-raspios.sh                              │
│ • Keep RaspiOS boot partition (FAT32):                      │
│   - bootloader, config.txt, cmdline.txt                     │
│ • Backup RaspiOS /etc/fstab                                 │
│ • Replace root partition with Debian (ext4):                │
│   - Delete RaspiOS rootfs                                   │
│   - rsync Debian rootfs (with RaspiOS packages installed)   │
│   - Restore RaspiOS fstab (correct partition UUIDs)         │
│   - Create /boot/firmware mount point                       │
│ • Resize root partition to fill image                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: Compress                                           │
├─────────────────────────────────────────────────────────────┤
│ • Run PiShrink to minimize filesystem                       │
│ • Compress with xz (parallel, level 6)                      │
│ • Generate checksums (SHA256)                               │
│ • Output: image-name.img.xz                                 │
└─────────────────────────────────────────────────────────────┘
```

## Partition Layout

### Before Merge

**RaspiOS Image**:
```
┌────────────────────┬──────────────────────┐
│ /dev/loop0p1       │ /dev/loop0p2         │
│ boot (FAT32)       │ root (ext4)          │
│ 512MB              │ ~2GB                 │
│ ================== │ ==================== │
│ • bootloader       │ • RaspiOS rootfs     │
│ • kernel           │ • (will be replaced) │
│ • firmware         │                      │
│ • config.txt       │                      │
└────────────────────┴──────────────────────┘
```

**Debian Image**:
```
┌────────────────────────────────────────────┐
│ /dev/loop1p1 (or p2, auto-detected)       │
│ root (ext4)                                │
│ ~2-4GB                                     │
│ ========================================== │
│ • Debian userspace                         │
│ • RaspiOS kernel packages (from QEMU)     │
│ • Service packages (from QEMU)            │
│ • /etc/setupfiles/ (configs)              │
│ • First-boot scripts                       │
└────────────────────────────────────────────┘
```

### After Merge

**Hybrid Image**:
```
┌────────────────────┬──────────────────────────────┐
│ /dev/mmcblk0p1     │ /dev/mmcblk0p2               │
│ boot (FAT32)       │ root (ext4)                  │
│ 512MB              │ 8GB (expanded)               │
│ ================== │ ============================ │
│ • RaspiOS bootload │ • Debian userspace           │
│ • RaspiOS kernel*  │ • RaspiOS kernel packages    │
│ • RaspiOS firmware │ • RaspiOS firmware packages  │
│ • config.txt       │ • RaspiOS fstab              │
│                    │ • /boot/firmware → p1        │
└────────────────────┴──────────────────────────────┘
    (kept from RaspiOS)   (replaced with Debian)

* Kernel files also in /boot/ and /lib/modules/ from APT packages
```

## Modular Service System

### Service Directory Structure

Each service is a self-contained module:

```
services/
└── <service-name>/
    ├── setup.sh              # Runs in QEMU (package installation)
    ├── first-boot/
    │   └── init.sh           # Runs on first boot (runtime config)
    ├── setupfiles/           # Static files → /etc/setupfiles/
    │   └── config.xyz
    ├── depends.sh            # Optional: dependencies
    └── motd.sh               # Optional: MOTD content
```

### Service Lifecycle

```
BUILD TIME (QEMU):
┌─────────────────────────────────────────────────┐
│ setup.sh                                        │
├─────────────────────────────────────────────────┤
│ • Install packages (apt install ...)            │
│ • Configure system settings                     │
│ • Create users/groups                           │
│ • Set up repositories                           │
│ • Copy setupfiles/ to /etc/setupfiles/          │
│ • Install first-boot/init.sh                    │
└─────────────────────────────────────────────────┘

FIRST BOOT (Raspberry Pi):
┌─────────────────────────────────────────────────┐
│ rpi-first-boot.service (one-time)               │
├─────────────────────────────────────────────────┤
│ • Expand root partition to fill SD card         │
│ • Set persistent network interface names        │
│ • Reboot                                        │
└─────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────┐
│ services-first-boot.service (one-time)          │
├─────────────────────────────────────────────────┤
│ • Execute base/first-boot/init.sh               │
│   - Configure network bridges (br-wan, br-lan)  │
│   - Set up DHCP server (if br-lan)              │
│ • Execute service/first-boot/init.sh            │
│   - Download images (HAOS, OpenWrt)             │
│   - Create containers/VMs                       │
│   - Detect and configure hardware               │
│   - Start services                              │
│ • Disable itself                                │
└─────────────────────────────────────────────────┘

RUNTIME:
┌─────────────────────────────────────────────────┐
│ Services running                                │
├─────────────────────────────────────────────────┤
│ • Docker containers                             │
│ • Incus VMs/containers                          │
│ • WiFi hotspot                                  │
│ • OpenWrt router                                │
│ • etc.                                          │
└─────────────────────────────────────────────────┘
```

### Service Dependency Resolution

Services can declare dependencies:

**Example**: `services/haos/depends.sh`
```bash
DEPENDS_ON="qemu"
```

**Build process**:
1. Parse requested services: `qemu+docker+haos`
2. Resolve dependencies:
   - `qemu` (no dependencies)
   - `docker` (no dependencies)
   - `haos` → requires `qemu`
3. Build order: `base` → `qemu` → `docker` → `haos`
4. Combine setup.sh from all services

### Service Composition

**Dynamic image example**: `debian/qemu+docker+haos`

**Process**:
1. Create temporary directory: `images/debian-qemu-docker-haos/`
2. Copy base config: `images/debian/config.sh`
3. Override variables:
   ```bash
   OUTPUT_IMAGE="debian-qemu-docker-haos.img"
   SERVICES="base qemu docker haos"
   ```
4. Combine setup scripts:
   ```bash
   cat services/base/setup.sh \
       services/qemu/setup.sh \
       services/docker/setup.sh \
       services/haos/setup.sh \
       > setup.sh
   ```
5. Merge setupfiles:
   ```bash
   cp -r services/base/setupfiles/* setupfiles/
   cp -r services/qemu/setupfiles/* setupfiles/
   cp -r services/docker/setupfiles/* setupfiles/
   cp -r services/haos/setupfiles/* setupfiles/
   ```
6. Inject first-boot scripts:
   ```bash
   # Aggregate all init.sh into services-first-boot.sh
   ```
7. Build image

## APT Repository Management

### Repository Configuration

**File**: `/etc/apt/sources.list.d/raspi.sources`
```
Types: deb
URIs: http://archive.raspberrypi.com/debian/
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/raspberrypi-archive-keyring.pgp
```

**File**: `/etc/apt/preferences.d/raspi-pin`
```
# Pin RaspiOS kernel and firmware packages
Package: raspberrypi-kernel raspberrypi-bootloader libraspberrypi* firmware-brcm80211
Pin: release o=Raspberry Pi Foundation
Pin-Priority: 1001

# Default to Debian for everything else
Package: *
Pin: release o=Debian
Pin-Priority: 500
```

### Update Behavior

```bash
sudo apt update
# Fetches package lists from:
# - Debian repositories (default)
# - RaspiOS repository (for kernel/firmware)

sudo apt upgrade
# Upgrades:
# - raspberrypi-kernel → from RaspiOS repo (priority 1001)
# - raspberrypi-bootloader → from RaspiOS repo (priority 1001)
# - libraspberrypi* → from RaspiOS repo (priority 1001)
# - firmware-brcm80211 → from RaspiOS repo (priority 1001)
# - All other packages → from Debian repos (priority 500)
```

**Result**: Kernel and firmware stay in sync with RaspiOS, userspace packages track Debian.

## Boot Modes

### Cloud-Init Mode (CLOUD=true)

**Use when**:
- Using Debian cloud images
- Need cloud-init features (network config, metadata, etc.)

**Files**:
- `cloudinit/user-data` - User creation, SSH config, runcmd
- `cloudinit/meta-data` - Instance ID, hostname
- `cloudinit/seed.img` - Auto-generated ISO (CIDATA volume)

**Boot process**:
1. QEMU mounts seed.img (cloud-init config)
2. QEMU mounts setup.iso (build scripts)
3. Cloud-init creates user and runs runcmd
4. runcmd mounts setup.iso and executes setup.sh
5. VM shuts down after setup

### First-Boot Service Mode (CLOUD=false)

**Use when**:
- Using generic Debian images
- Don't need cloud-init
- Want minimal dependencies

**Files**:
- `first-boot/setup-runner.sh` - Creates user, runs setup
- `first-boot/setup-runner.service` - Systemd one-shot service

**Boot process**:
1. Autobuild injects files into Debian image (before QEMU)
2. Autobuild enables systemd service via chroot
3. QEMU boots Debian
4. Systemd starts setup-runner.service
5. Service creates user, mounts setup.iso, runs setup.sh
6. Service disables itself
7. VM shuts down after setup

## Hardware Detection

### Detection Points

**1. Build Time (QEMU)**:
- Install packages needed for hardware detection
- Copy detection scripts to /etc/setupfiles/

**2. First Boot (Raspberry Pi)**:
- Detect network interfaces (eth0, eth1)
- Detect WiFi adapters (wlan0, wlan1)
- Detect USB Zigbee dongles
- Configure services based on detected hardware

### Network Interface Detection

**File**: `services/base/first-boot/init.sh`

```bash
# Detect eth1 (second NIC)
if ip link show eth1 >/dev/null 2>&1; then
    # Dual NIC mode
    # br-wan (eth0) - WAN with DHCP client
    # br-lan (eth1) - LAN with DHCP server + NAT
else
    # Single NIC mode
    # br-wan (eth0) - WAN with DHCP client
fi
```

**Result**:
- Single NIC: WAN only
- Dual NIC: WAN + LAN with DHCP/NAT

### WiFi Detection

**File**: `services/hotspot/first-boot/init.sh`

```bash
# Detect WiFi interfaces
wlan0_exists=$(ip link show wlan0 2>/dev/null)
wlan1_exists=$(ip link show wlan1 2>/dev/null)

if [[ -n "$wlan0_exists" && -n "$wlan1_exists" ]]; then
    # Dual-band: 2.4GHz on wlan0, 5GHz on wlan1
elif [[ -n "$wlan0_exists" ]]; then
    # Single-band: 5GHz on wlan0
fi

# Determine bridge
if ip link show br-lan >/dev/null 2>&1; then
    BRIDGE="br-lan"
else
    BRIDGE="br-wan"
fi
```

**Result**:
- Dual WiFi: 2.4GHz + 5GHz APs
- Single WiFi: 5GHz AP only
- Adapts to available bridge

### USB Zigbee Detection

**File**: `services/haos/first-boot/init.sh`

```bash
# Scan USB serial devices
for device in /dev/ttyUSB* /dev/ttyACM*; do
    device_info=$(udevadm info -q property -n "$device")

    # Check vendor for known Zigbee coordinators
    if echo "$device_info" | grep -qiE "(FTDI|Silicon_Labs|Texas_Instruments|dresden_elektronik|ITead|Sonoff)"; then
        # Extract USB IDs
        USB_VENDOR=$(echo "$device_info" | grep "ID_VENDOR_ID=" | cut -d'=' -f2)
        USB_PRODUCT=$(echo "$device_info" | grep "ID_MODEL_ID=" | cut -d'=' -f2)

        # Pass through to Home Assistant VM
        incus config device add haos zigbee-dongle usb \
            vendorid="$USB_VENDOR" \
            productid="$USB_PRODUCT" \
            required=false
    fi
done
```

**Result**: Zigbee coordinators automatically available in Home Assistant.

## Image Size Management

### Size Calculation

**Autobuild logic**:
```bash
# Debian image size
DEBIAN_SIZE=$(qemu-img info --output=json debian.raw | jq -r '.["virtual-size"]')

# Add overhead (1-2GB for services, temp files, expansion)
FINAL_SIZE=$((DEBIAN_SIZE + 2GB))

# Override with config.sh IMAGE_SIZE if specified
```

### Partition Expansion

**During merge** (`merge-debian-raspios.sh`):
1. Create output image with `IMAGE_SIZE`
2. Resize partition table
3. Expand root partition to fill available space
4. Resize ext4 filesystem

**On first boot** (`rpi-first-boot.sh`):
1. Expand root partition to fill SD card
2. Resize ext4 filesystem to match
3. Reboot to apply changes

**Result**: Image expands to fill entire SD card, regardless of size.

## Summary

The architecture uses:
- **Hybrid approach** - RaspiOS boot + Debian rootfs
- **QEMU ARM64** - Native package installation before merge
- **Modular services** - Composable image components
- **APT pinning** - Automatic kernel/firmware updates
- **Hardware detection** - Runtime configuration based on detected hardware
- **Two boot modes** - Cloud-init or first-boot service

This design provides:
- Full Raspberry Pi hardware support
- Safe automatic updates
- Easy customization
- Reproducible builds
- Team collaboration via version control

**Next**: [Learn about the build system](Build-System.md)