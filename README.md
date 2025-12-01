# RPI-Dev - Raspberry Pi Hybrid Image Builder

Automated build system for creating Raspberry Pi images with **Raspberry Pi OS hardware support** + **custom Debian ARM64 rootfs**.

[![Build Images](https://github.com/YOUR_USERNAME/rpi-dev/actions/workflows/build-images.yml/badge.svg)](https://github.com/YOUR_USERNAME/rpi-dev/actions/workflows/build-images.yml)
[![License](https://img.shields.io/badge/license-As--Is-blue.svg)](LICENSE)

---

## Why This Project?

The Raspberry Pi uses specialized hardware (RP1 chip) for critical I/O that requires kernel drivers not yet in mainline Linux. This project solves that by:

- ✅ Maintaining **full Raspberry Pi hardware support** (Ethernet, WiFi, GPIO, USB via RP1)
- ✅ Using **pure Debian ARM64** rootfs for a clean, standard environment
- ✅ Enabling **automatic kernel/firmware updates** via APT with proper pinning
- ✅ Supporting **custom image configurations** with automated builds via GitHub Actions

## Quick Start

### For Users: Download Pre-Built Images

1. Go to **[Releases](../../releases)**
2. Download the `.img.xz` file for your desired image
3. Flash to SD card or SSD:

```bash
xz -dc rpi-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

**⚠️ Replace `/dev/sdX` with your actual device (check with `lsblk`)**

### For Developers: Fork and Customize

1. **Fork this repository**
2. **Create your custom image**:
   ```bash
   cp -r images/raspivirt-incus images/my-custom-image
   vim images/my-custom-image/config.sh   # Configure image size, resources
   vim images/my-custom-image/setup.sh    # Add your packages and config
   ```
3. **Commit and push** - GitHub Actions automatically builds and releases your image!

## Available Images

| Image | Description | Size | Download |
|-------|-------------|------|----------|
| **[RaspiVirt-Incus](../../wiki/Image-RaspiVirt-Incus)** | Incus container/VM manager with KVM, web UI, and br-wan networking | 500 MB | [Latest](../../releases) |
| **[RaspiVirt-Incus+Docker](../../wiki/Image-RaspiVirt-Incus-Docker)** | RaspiVirt-Incus + Docker + Portainer + Watchtower | 700 MB | [Latest](../../releases) |

**[📖 Full image documentation in the Wiki](../../wiki)**

## Documentation

Complete documentation is available in the **[GitHub Wiki](../../wiki)**:

- **[🏠 Home](../../wiki/Home)** - Project overview and quick start
- **[⚙️ GitHub Actions](../../wiki/GitHub-Actions)** - Automated build system documentation
- **[📦 RaspiVirt-Incus](../../wiki/Image-RaspiVirt-Incus)** - Incus virtualization platform
- **[🐳 RaspiVirt-Incus+Docker](../../wiki/Image-RaspiVirt-Incus-Docker)** - Incus + Docker platform

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Download Base Images (RaspiOS + Debian)                  │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. QEMU Setup (Native ARM64)                                │
│    - Execute setup.sh in QEMU                               │
│    - Install RaspiOS kernel/firmware via APT                │
│    - Install custom packages and configuration              │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Merge (Partition-level)                                  │
│    - Keep RaspiOS boot partition (firmware)                 │
│    - Replace root partition with configured Debian          │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Compress with PiShrink                                   │
│    - Shrink filesystem and compress to .xz                  │
└─────────────────────────────────────────────────────────────┘
```

**[📖 See detailed architecture in the Wiki](../../wiki/Home#how-it-works)**

## Building Locally

Install dependencies:
```bash
sudo apt install -y qemu-system-aarch64 qemu-utils parted \
    e2fsprogs dosfstools rsync xz-utils genisoimage
```

Build an image:
```bash
# Build specific image
./bin/autobuild --image raspivirt-incus

# Build all images
./bin/autobuild --all-images

# List available images
./bin/autobuild --list-images
```

**[📖 See full build documentation in the Wiki](../../wiki/Home#building-locally)**

## Features

### Automated CI/CD
- ✅ **Daily builds** at 2:00 AM UTC with latest base images
- ✅ **Automatic releases** on push to main branch
- ✅ **Parallel builds** for multiple images
- ✅ **Pre-release testing** on feature branches

**[📖 See GitHub Actions documentation](../../wiki/GitHub-Actions)**

### Hardware Support
- ✅ Gigabit Ethernet (RP1)
- ✅ WiFi + Bluetooth
- ✅ GPIO (40 pins)
- ✅ USB 3.0 (RP1)
- ✅ PCIe (M.2 SSD)
- ✅ HDMI (dual 4K)
- ✅ Camera/DSI/CSI
- ✅ Hardware acceleration

### System Updates
Automatic kernel and firmware updates via APT:
```bash
sudo apt update && sudo apt upgrade -y
```

APT pinning ensures RaspiOS packages (kernel/firmware) update from RaspiOS repository while keeping Debian userspace packages from Debian.

## Project Structure

```
rpi-dev/
├── bin/
│   ├── autobuild                 # Automated build script
│   └── merge-debian-raspios.sh   # Merge script
├── images/                       # Image configurations
│   ├── raspivirt-incus/
│   └── raspivirt-incus+docker/
├── wiki/                         # Wiki documentation (auto-synced)
└── .github/
    └── workflows/
        ├── build-images.yml      # Multi-stage build workflow
        └── sync-wiki.yml         # Wiki synchronization
```

## Creating Custom Images

1. **Copy an existing image template**:
   ```bash
   cp -r images/raspivirt-incus images/my-image
   ```

2. **Configure** (`images/my-image/config.sh`):
   - `OUTPUT_IMAGE`: Filename
   - `IMAGE_SIZE`: Final size (e.g., "8G")
   - `QEMU_RAM`, `QEMU_CPUS`: Build resources

3. **Customize** (`images/my-image/setup.sh`):
   - Add package installations
   - Configure services
   - Apply custom settings

4. **Add files** to `setupfiles/`:
   - Configuration files
   - Scripts
   - Certificates

5. **Build**:
   ```bash
   ./bin/autobuild --image my-image
   ```

**[📖 See detailed customization guide in the Wiki](../../wiki/Home#creating-custom-images)**

## Releases

Pre-built images are automatically released via GitHub Actions:

- **Stable releases** (main branch) - Production-ready
- **Pre-releases** (other branches) - Experimental/testing
- **Daily builds** - Latest Debian/RaspiOS updates

**[⬇️ Download from Releases](../../releases)**

## Technical Details

- **Base OS**: Debian 13 (Trixie) ARM64
- **Kernel**: Raspberry Pi OS kernel (latest)
- **Build System**: GitHub Actions with 4-stage pipeline
- **Boot Mode**: Cloud-init or first-boot systemd service
- **Package Management**: APT with repository pinning

**[📖 See CLAUDE.md for complete technical documentation](CLAUDE.md)**

## Resources

- **[📖 Wiki](../../wiki)** - Complete documentation
- **[📦 Releases](../../releases)** - Download pre-built images
- **[🔧 Issues](../../issues)** - Report bugs or request features
- **[🚀 Actions](../../actions)** - View build status

### External Links
- [Raspberry Pi OS Downloads](https://www.raspberrypi.com/software/operating-systems/)
- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
- [Incus Documentation](https://linuxcontainers.org/incus/)
- [Docker Documentation](https://docs.docker.com/)

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `./bin/autobuild`
5. Submit a pull request

## License

This project is provided "as is" without warranty. Use at your own risk.

---

**Made with ❤️ for the Raspberry Pi community**