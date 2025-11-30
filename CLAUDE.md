# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains tooling for creating hybrid Raspberry Pi images that combine Raspberry Pi OS boot/firmware with custom Debian ARM64 root filesystems. The primary use case is running Debian on Raspberry Pi hardware (ARM64) while maintaining full hardware support. This is especially important for Raspberry Pi which uses the RP1 chip for critical I/O (Ethernet, GPIO, USB, etc.).

## Architecture

The project uses a partition-level merge approach:

1. **Boot partition (FAT32)**: Retained from Raspberry Pi OS to ensure Raspberry Pi firmware compatibility
2. **Root partition (ext4)**: Replaced with custom Debian ARM64 rootfs
3. **RaspiOS packages installed via APT**:
   - `raspberrypi-kernel` - Kernel, initramfs, and modules (including RP1 drivers)
   - `raspberrypi-bootloader` - Bootloader and config files for `/boot/firmware`
   - `libraspberrypi*` - VideoCore libraries
   - `firmware-brcm80211` - WiFi/Bluetooth firmware
4. **APT configuration**:
   - RaspiOS repository with APT pinning for kernel/firmware updates
   - Enables safe `apt upgrade` without breaking hardware support
5. **Preserved from RaspiOS**:
   - `/etc/fstab` - Partition mount configuration

The merge strategy ensures hardware compatibility while allowing a completely custom Debian userspace with automatic updates.

## Key Commands

### Multi-Image Management

The project supports multiple image configurations. Each image is defined in `images/<name>/`:

```bash
# List available images
./bin/autobuild --list-images

# Build a specific image
./bin/autobuild --image exemple

# Build all images
./bin/autobuild --all-images
```

Each image directory contains:
- `config.sh` - Build configuration (OUTPUT_IMAGE, IMAGE_SIZE, QEMU_RAM, QEMU_CPUS, DESCRIPTION)
- `setup.sh` - Setup script executed in QEMU during build
- `setupfiles/` - Files copied to `/root/setupfiles/` in the final image
- `cloudinit/` OR `first-boot/` - Boot configuration (choose one):
  - `cloudinit/` - Cloud-init mode (user-data, meta-data, seed.img auto-generated)
  - `first-boot/` - First-boot service mode (setup-runner.sh, setup-runner.service)

### Automated Build Process

The `autobuild` script automates the entire workflow:

1. Downloads base images (RaspiOS + Debian)
2. Creates `setup.iso` from the image's setup.sh and setupfiles/
3. Launches QEMU ARM64 with cloud-init + setup.iso
4. **`setup.sh` installs RaspiOS kernel/firmware packages in QEMU**
5. Waits for automatic setup completion and poweroff
6. Merges RaspiOS boot with Debian rootfs (pre-configured with RaspiOS packages)
7. Compresses with PiShrink

Common options:
- `--image NAME` - Build specific image
- `--all-images` - Build all images
- `--skip-download` - Use existing base images
- `--skip-qemu` - Skip QEMU setup (use existing Debian image)
- `--skip-compress` - Skip PiShrink compression

Examples:
```bash
# Build the exemple image
./bin/autobuild --image exemple

# Build all images without re-downloading base images
./bin/autobuild --all-images --skip-download

# Quick rebuild without QEMU setup
./bin/autobuild --image exemple --skip-qemu --skip-compress
```

### Creating a New Image

```bash
# 1. Copy exemple image
cp -r images/exemple images/myimage

# 2. Edit config
vim images/myimage/config.sh
# Set OUTPUT_IMAGE, IMAGE_SIZE, QEMU_RAM, QEMU_CPUS, DESCRIPTION

# 3. Customize setup
vim images/myimage/setup.sh
# Add package installations, configuration, etc.

# 4. Add custom files
cp my-config.txt images/myimage/setupfiles/

# 5. Build
./bin/autobuild --image myimage
```

### Manual Merge (Low-Level)

For direct control without autobuild:

```bash
./bin/merge-debian-raspios.sh <raspios-image> <debian-image>
```

Common options:
- `-o, --output FILE` - Output image name (default: `hybrid-debian-raspios.img`)
- `-s, --size SIZE` - Final image size (default: auto-calculated as Debian size + 1-2GB)
- `-k, --keep-kernel` - Use Debian kernel instead of RaspiOS kernel (not recommended - RP1 drivers missing)

Examples:
```bash
# Basic merge
./bin/merge-debian-raspios.sh 2025-11-24-raspios-trixie-arm64-lite.img debian-13-backports-genericcloud-arm64-daily.raw

# Custom output and size
./bin/merge-debian-raspios.sh -o rpi-custom.img -s 16G raspios-lite.img debian.raw
```

### Flashing to SD Card/SSD

```bash
sudo dd if=hybrid-debian-raspios.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

### Compressing Images

```bash
sudo pishrink.sh -z hybrid-debian-raspios.img hybrid-debian-raspios.img.xz
```

## Boot Configuration Modes

The autobuild system supports two boot configuration modes for first-boot setup:

### Mode 1: Cloud-Init (Legacy)

Uses cloud-init for initial system configuration. Each image has a `cloudinit/` directory:

```
images/<name>/cloudinit/
├── user-data   # Cloud-init user configuration (user creation, SSH keys, passwords)
├── meta-data   # Instance metadata (hostname, instance ID)
└── seed.img    # Auto-generated ISO containing user-data and meta-data
```

The `seed.img` is automatically regenerated during build. To manually regenerate:
```bash
genisoimage -output images/<name>/cloudinit/seed.img -volid cidata -joliet -rock \
    images/<name>/cloudinit/user-data \
    images/<name>/cloudinit/meta-data
```

**Note:** Cloud-init mode requires a Debian cloud image with cloud-init pre-installed.

### Mode 2: First-Boot Service (Recommended for Generic Images)

Uses a systemd service for initial configuration. Works with **any generic Debian ARM64 image** (no cloud-init required).

```
images/<name>/first-boot/
├── setup-runner.sh        # First-boot script (creates user, configures SSH, runs setup.sh)
└── setup-runner.service   # Systemd service that runs setup-runner.sh once
```

The autobuild script automatically:
1. Detects if an image uses `first-boot/` or `cloudinit/`
2. Injects `setup-runner.sh` and `setup-runner.service` into the Debian image
3. Enables the systemd service
4. Launches QEMU without cloud-init seed.img

**Key advantages:**
- Works with any generic Debian ARM64 image (not just cloud images)
- No cloud-init dependency
- Full control over initial configuration
- Service self-destructs after first boot

### Choosing a Boot Mode

When creating a new image:

**Use first-boot mode if:**
- You want to use a generic Debian ARM64 image (not a cloud image)
- You don't need cloud-init features
- You want minimal dependencies

**Use cloud-init mode if:**
- You're already using Debian cloud images
- You need advanced cloud-init features (network config, cloud metadata, etc.)
- You have existing cloud-init configurations

## Technical Constraints

### Why RaspiOS Kernel is Required

The Raspberry Pi kernel includes drivers for all Raspberry Pi hardware. For Raspberry Pi, this includes the RP1 southbridge chip for critical I/O (Ethernet, USB, GPIO). These drivers are not yet upstream in mainline Linux. Using the Debian kernel (`--keep-kernel`) will result in:
- No Ethernet connectivity
- Limited USB functionality
- No GPIO access
- Missing hardware accelerators

### RaspiOS Package Management

RaspiOS packages are installed during the **QEMU setup phase** (in `setup.sh`), not during the merge. This enables **automatic kernel and firmware updates** via `apt upgrade`:

**Installation process:**
1. `setup.sh` executes in QEMU ARM64 (native ARM execution)
2. Adds RaspiOS repository + APT pinning configuration
3. Installs RaspiOS kernel/firmware packages
4. Merge script simply copies the configured Debian rootfs

**Packages installed:**
- `raspberrypi-kernel` - Kernel + modules (`/boot/*`, `/lib/modules`)
- `raspberrypi-bootloader` - Bootloader files (`/boot/firmware`)
- `libraspberrypi0` + `libraspberrypi-bin` - VideoCore libraries
- `firmware-brcm80211` - WiFi/Bluetooth firmware

**APT configuration:**
- RaspiOS repository: `http://archive.raspberrypi.org/debian/ trixie main`
- APT pinning ensures RaspiOS packages are prioritized for kernel/firmware
- Debian packages remain default for all other software

**Repository files (kept in final image):**
- `/etc/apt/sources.list.d/raspi.list` - RaspiOS repository
- `/etc/apt/preferences.d/raspi-pin` - APT pinning configuration
- `/etc/apt/keyrings/raspberrypi.gpg` - Repository signing key

**Safe system updates:**
```bash
# Update all packages (Debian userspace + RaspiOS kernel/firmware)
sudo apt update
sudo apt upgrade -y

# RaspiOS packages will auto-update without breaking hardware support
```

**Why install in QEMU instead of during merge?**
- Simpler: No complex ARM64 chroot on x86_64 needed
- Native: Packages install in native ARM64 QEMU environment
- Faster: No QEMU user-mode overhead during merge
- Cleaner: Merge script just copies files, no package management

### Partition Layout Assumptions

The merge script expects:
- **RaspiOS image**: 2-partition layout (boot FAT32 + root ext4)
- **Debian image**: Either single partition or 2-partition layout where rootfs is on p1 or p2
- Auto-detection logic in `merge-debian-raspios.sh:222-228`

### Image Format Support

- **Input formats**: `.img`, `.img.xz` (RaspiOS), `.raw`, `.qcow2` (Debian - auto-converted)
- **Output format**: Always `.img` (raw disk image)
- Uses `qemu-img` for format detection and conversion

## Dependencies

Required packages (Debian/Ubuntu):
```bash
sudo apt install -y parted e2fsprogs dosfstools qemu-utils rsync xz-utils genisoimage qemu-system-aarch64
```

**Note:** `qemu-system-aarch64` is required for the autobuild system to run `setup.sh` in QEMU ARM64 where RaspiOS packages are installed.

## GitHub Actions CI/CD

The project includes automated builds via GitHub Actions (`.github/workflows/build-images.yml`):

- **Triggers**: Push to any branch, daily at 2:00 UTC, manual dispatch
- **Process**: Downloads base images, builds all images, creates releases
- **Releases**:
  - `main` branch → stable releases
  - Other branches → pre-releases
  - Tag format: `vYYYY-MM-DD-HHMM`
- **Assets**: All `.img.xz` files uploaded to GitHub Releases

See `.github/README.md` for detailed workflow documentation.

## Merge Process Stages

The merge script follows this 10-stage process:

1. Dependency verification
2. RaspiOS image preparation (decompress if `.xz`)
3. Debian image preparation (convert to raw if needed)
4. Size analysis and calculation
5. Output image creation (copy of RaspiOS)
6. Image resizing and partition expansion
7. Loop device mounting (both images)
8. Backup of RaspiOS fstab
9. Rootfs replacement:
   - Delete RaspiOS root
   - Rsync Debian root (with RaspiOS packages pre-installed from setup.sh)
   - Create `/boot/firmware` mount point
   - Restore fstab
10. Cleanup and finalization

Critical paths during merge:
- All operations use loop devices (`losetup -P`)
- Partition resizing uses `parted` + `resize2fs`
- Rootfs copy uses `rsync -aAXv` to preserve all attributes
- **RaspiOS packages already installed** in Debian image via `setup.sh` in QEMU
- No chroot or package installation during merge
- Temporary mounts use PID-based naming to avoid conflicts
