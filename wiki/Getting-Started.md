# Getting Started

This guide will walk you through installing dependencies, building your first image, and flashing it to an SD card.

## Prerequisites

### System Requirements

- **OS**: Linux (Debian/Ubuntu recommended)
- **RAM**: 8GB minimum (16GB recommended for QEMU builds)
- **Disk**: 20GB free space per image
- **CPU**: x86_64 with virtualization support (for QEMU ARM64 emulation)

### Required Packages

Install build dependencies:

```bash
sudo apt update
sudo apt install -y \
    parted \
    e2fsprogs \
    dosfstools \
    qemu-utils \
    rsync \
    xz-utils \
    genisoimage \
    qemu-system-aarch64 \
    qemu-efi-aarch64
```

**Package purposes:**
- `parted`, `e2fsprogs`, `dosfstools` - Partition and filesystem tools
- `qemu-utils` - Image format conversion
- `rsync` - Efficient file copying
- `xz-utils` - Compression/decompression
- `genisoimage` - Create ISO images for setup scripts
- `qemu-system-aarch64` - ARM64 emulation for native package installation

### Optional: PiShrink

For image compression (automatically downloaded if not present):

```bash
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin/
```

## Installation

Clone the repository:

```bash
git clone https://github.com/Pikatsuto/raspberry-builds.git
cd raspberry-builds
```

## Building Your First Image

### Option 1: Base Debian Image

Build a minimal Debian image with RaspiOS kernel:

```bash
./bin/autobuild --image debian
```

This will:
1. Download Raspberry Pi OS Lite and Debian 13 cloud images
2. Launch QEMU ARM64 VM
3. Install RaspiOS kernel and firmware packages
4. Merge RaspiOS boot with Debian rootfs
5. Compress the final image

**Output**: `debian-base.img.xz` (approximately 2-3GB compressed)

**Build time**: 15-30 minutes (depending on internet speed and CPU)

### Option 2: Image with Services

Build an image with Docker and Incus:

```bash
./bin/autobuild --image debian/qemu+docker
```

Available service combinations:
- `debian/qemu+docker` - Incus + Docker Engine
- `debian/qemu+haos` - Incus + Home Assistant OS
- `debian/qemu+openwrt+hotspot` - Incus + OpenWrt + WiFi AP
- `debian/qemu+docker+openwrt+hotspot+haos` - Full stack

### Build Options

Speed up subsequent builds:

```bash
# Skip base image downloads (use cached)
./bin/autobuild --image debian --skip-download

# Skip QEMU setup (use existing Debian image)
./bin/autobuild --image debian --skip-qemu

# Skip compression
./bin/autobuild --image debian --skip-compress

# Build all images defined in .github/images.txt
./bin/autobuild --all-images

# List available images
./bin/autobuild --list-images
```

## Flashing to SD Card

### Find Your SD Card Device

```bash
# Before inserting SD card
lsblk

# Insert SD card, then run again
lsblk

# Look for the new device (e.g., /dev/sdc, /dev/mmcblk0)
```

**Warning**: Double-check the device name! Using the wrong device will destroy data.

### Flash the Image

Decompress and flash in one command:

```bash
# If image is compressed (.xz)
xz -dc debian-base.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync

# If image is already decompressed (.img)
sudo dd if=debian-base.img of=/dev/sdX bs=4M status=progress conv=fsync
```

Replace `/dev/sdX` with your SD card device.

Sync and eject:

```bash
sync
sudo eject /dev/sdX
```

## First Boot

### Default Credentials

**Username**: `pi`
**Password**: `raspberry`

**Important**: Change the default password immediately after first login!

```bash
passwd
```

### Network Configuration

**Default**: DHCP on br-wan bridge. IP displayed in MOTD on login.

**Static IP**: See [Configuration Reference - Static IP](Configuration-Reference/#static-ip)

### First Boot Process

**Duration**: 3-5 minutes for automatic setup (partition resize, hardware detection, service initialization).

**Details**: See [Hardware Detection - Detection Sequence](Hardware-Detection/#detection-sequence) for complete timeline and monitoring commands.

## Accessing Services

Services display access information in the MOTD (Message of the Day) on login.

### Docker + Portainer

```
Portainer UI: https://<raspberry-ip>:9443
Username: admin
Password: (set on first access)
```

### Home Assistant OS

```
Home Assistant: http://<raspberry-ip>:8123
(First boot setup takes 5-10 minutes)
```

### OpenWrt

```
OpenWrt LuCI: http://192.168.10.1
Username: root
Password: (none - set on first access)
```

### WiFi Hotspot

If WiFi adapters detected:

```
SSID: RaspberryPi-5G (or RaspberryPi-2.4G)
Password: raspberry
```

## Verifying the Build

### Check Kernel

```bash
uname -r
# Should show: 6.6.x-rpi-v8 or 6.6.x-rpi-2712
```

### Check RaspiOS Packages

```bash
dpkg -l | grep raspberrypi
# Should show:
# - raspberrypi-kernel
# - raspberrypi-bootloader
# - libraspberrypi0
```

### Test Hardware

```bash
# Check WiFi/Bluetooth firmware
dmesg | grep brcmfmac

# Check RP1 drivers (Raspberry Pi 5)
lsmod | grep rp1

# List USB devices
lsusb

# Check network bridges
ip link show
# Should show: br-wan, and br-lan if dual NIC
```

## Updating the System

Safe system updates:

```bash
sudo apt update
sudo apt upgrade -y
```

RaspiOS kernel and firmware packages update from the RaspiOS repository, while all other packages update from Debian repositories. No special handling required.

## Next Steps

- [Learn about the architecture](Architecture.md)
- [Explore available services](Available-Services.md)
- [Create a custom image](Custom-Images.md)
- [Set up GitHub Actions for automated builds](GitHub-Actions.md)

## Troubleshooting

For common issues and solutions, see:
- [Troubleshooting - Build Issues](Troubleshooting/#build-issues)
- [Troubleshooting - Boot Issues](Troubleshooting/#boot-issues)
- [Troubleshooting - Service Issues](Troubleshooting/#service-issues)
- [FAQ](FAQ.md)
- [Open an issue](https://github.com/Pikatsuto/raspberry-builds/issues)