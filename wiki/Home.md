# RPI-Dev - Hybrid Raspberry Pi Images Builder

Welcome to the RPI-Dev wiki! This project automates the creation of hybrid Raspberry Pi images combining Raspberry Pi OS hardware support with custom Debian ARM64 root filesystems.

## Overview

RPI-Dev is an automated build system that creates ready-to-use Raspberry Pi images with full hardware compatibility and custom software configurations. The project addresses a common challenge: running pure Debian on Raspberry Pi while maintaining complete hardware support for critical components like the RP1 chip (Ethernet, USB, GPIO).

### Key Features

- **Automated Builds**: GitHub Actions automatically build all images daily and on every push
- **Full Hardware Support**: Maintains Raspberry Pi OS kernel and firmware for complete hardware compatibility
- **Pure Debian Userspace**: Uses official Debian ARM64 root filesystems for a clean, standard environment
- **Multi-Image Support**: Easy creation and management of multiple image configurations
- **Automatic Updates**: Built-in APT configuration enables safe kernel and firmware updates
- **QEMU Development**: Test and develop images in QEMU before flashing to hardware
- **CI/CD Integration**: Automated releases via GitHub Actions with compressed, ready-to-flash images

## Why This Project?

The Raspberry Pi uses specialized hardware that requires kernel drivers not yet available in mainline Linux:

- **RP1 Southbridge Chip**: Handles Ethernet, USB 2.0/3.0, GPIO, and other critical I/O
- **VideoCore GPU**: Provides hardware acceleration and display output
- **WiFi/Bluetooth**: Requires specific firmware blobs

Using a standard Debian kernel results in non-functional hardware. This project solves that by:

1. Using Raspberry Pi OS boot partition and kernel
2. Replacing the root filesystem with pure Debian
3. Installing RaspiOS packages via APT for automatic updates
4. Preserving hardware compatibility while gaining Debian's advantages

## How It Works

### Architecture

The project uses a **partition-level merge approach**:

1. **Boot Partition (FAT32)**: Retained from Raspberry Pi OS for firmware compatibility
2. **Root Partition (ext4)**: Replaced with custom Debian ARM64 rootfs
3. **RaspiOS Packages**: Installed via APT with repository pinning:
   - `raspberrypi-kernel` - Kernel, initramfs, and modules (including RP1 drivers)
   - `raspberrypi-bootloader` - Bootloader and firmware files
   - `libraspberrypi*` - VideoCore libraries
   - `firmware-brcm80211` - WiFi/Bluetooth firmware
4. **APT Configuration**: RaspiOS repository with pinning enables safe `apt upgrade`

### Build Process

```
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: Download Base Images                              │
│  ├─ Raspberry Pi OS Lite ARM64 (.img.xz)                   │
│  └─ Debian Generic Cloud ARM64 (.raw)                      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: QEMU Setup (Native ARM64 Execution)               │
│  ├─ Create setup.iso from image/setup.sh + setupfiles/     │
│  ├─ Launch QEMU ARM64 with Debian + setup.iso              │
│  ├─ Execute setup.sh (install packages, configure system)  │
│  ├─ Install RaspiOS kernel/firmware via APT                │
│  └─ Automatic shutdown when complete                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: Hybrid Image Creation                             │
│  ├─ Copy RaspiOS boot partition                            │
│  ├─ Replace root partition with configured Debian          │
│  ├─ Preserve /etc/fstab from RaspiOS                       │
│  └─ Resize to final image size                             │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: Compression                                        │
│  ├─ Shrink unused space with PiShrink                      │
│  └─ Compress to .img.xz (ready to flash)                   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### For Users: Download Pre-Built Images

The easiest way to use this project is to download pre-built images from [GitHub Releases](../../releases):

1. Go to the [Releases](../../releases) page
2. Download the `.img.xz` file for your desired image
3. Flash to SD card or SSD:
   ```bash
   xz -dc rpi-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   sync
   ```

### For Developers: Fork and Customize

Want to create your own custom images? It's easy:

1. **Fork this repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/rpi-dev.git
   cd rpi-dev
   ```

3. **Create a new image configuration**:
   ```bash
   # Copy an existing image as a template
   cp -r images/raspivirt-incus images/my-custom-image
   ```

4. **Edit the configuration** (`images/my-custom-image/config.sh`):
   ```bash
   OUTPUT_IMAGE="rpi-my-custom-image.img"
   IMAGE_SIZE="8G"
   QEMU_RAM="8G"
   QEMU_CPUS="4"
   DESCRIPTION="My custom Raspberry Pi image"
   ```

5. **Customize the setup script** (`images/my-custom-image/setup.sh`):
   - Add package installations
   - Configure services
   - Apply custom settings

6. **Add custom files** to `images/my-custom-image/setupfiles/`:
   - Configuration files
   - Scripts
   - SSH keys

7. **Commit and push**:
   ```bash
   git add images/my-custom-image/
   git commit -m "Add my custom image"
   git push origin main
   ```

8. **GitHub Actions automatically builds your image!**
   - Check the [Actions](../../actions) tab for build progress
   - Download from [Releases](../../releases) when complete

### Building Locally

If you prefer to build locally:

```bash
# Install dependencies
sudo apt install -y qemu-system-aarch64 qemu-utils parted \
    e2fsprogs dosfstools rsync xz-utils genisoimage

# Build a specific image
./bin/autobuild --image my-custom-image

# Or build all images
./bin/autobuild --all-images
```

## Image Directory Structure

Each image is defined in `images/<image-name>/`:

```
images/my-image/
├── config.sh              # Build configuration
│                          #  - OUTPUT_IMAGE: Final image filename
│                          #  - IMAGE_SIZE: Final image size (e.g., "8G")
│                          #  - QEMU_RAM: RAM for QEMU (e.g., "8G")
│                          #  - QEMU_CPUS: CPU cores for QEMU (e.g., "4")
│                          #  - DESCRIPTION: Image description
│
├── setup.sh               # Setup script executed in QEMU ARM64
│                          #  - Installs packages (RaspiOS kernel, software)
│                          #  - Configures system (users, services, etc.)
│                          #  - Runs in native ARM64 environment
│
├── setupfiles/            # Files copied to /root/setupfiles/ in image
│                          #  - Config files, scripts, certificates, etc.
│                          #  - Available to setup.sh during QEMU execution
│
└── cloudinit/             # Cloud-init configuration (for first boot)
    ├── user-data          # User configuration (users, SSH keys, passwords)
    ├── meta-data          # Instance metadata (hostname, instance-id)
    └── seed.img           # Auto-generated ISO (don't edit manually)
```

## Available Images

This repository includes the following pre-configured images:

- **[RaspiVirt-Incus](Image-RaspiVirt-Incus)**: Raspberry Pi virtualization platform with Incus container/VM manager
- **[RaspiVirt-Incus+Docker](Image-RaspiVirt-Incus-Docker)**: RaspiVirt-Incus plus Docker for container orchestration

See individual image pages for detailed documentation.

## Automatic Updates

Images built with this system support automatic kernel and firmware updates via APT:

```bash
# On your Raspberry Pi
sudo apt update
sudo apt upgrade -y
```

The APT pinning configuration ensures RaspiOS packages (kernel, firmware) are updated from the RaspiOS repository while all other packages use Debian repositories. This maintains hardware compatibility while keeping the system up-to-date.

## Documentation

- **[GitHub Actions Workflow](GitHub-Actions)**: Detailed documentation of the automated build system
- **[RaspiVirt-Incus Image](Image-RaspiVirt-Incus)**: Virtualization platform with Incus
- **[RaspiVirt-Incus+Docker Image](Image-RaspiVirt-Incus-Docker)**: Incus + Docker platform
- **[Main README](../README.md)**: Complete project documentation with manual build instructions

## Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](../../issues)
- **Discussions**: Ask questions in [GitHub Discussions](../../discussions)
- **Documentation**: Check the [README](../README.md) and [CLAUDE.md](../CLAUDE.md) for technical details

## License

This project is provided "as is" without warranty. Use at your own risk.