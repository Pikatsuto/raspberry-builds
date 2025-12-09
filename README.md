# Raspberry Pi Image Builder

**Build, customize, and maintain production-ready Raspberry Pi images with ease.**

> A modular automated build system for creating custom Raspberry Pi OS images with full hardware support, automatic updates, and service composition.

## Why This Project?

Building and maintaining custom Raspberry Pi images is traditionally complex and error-prone. This project solves that by providing:

- **Easy Image Creation** - Build custom images with a single command
- **Modular Service System** - Compose images from reusable service components
- **Automatic Hardware Support** - Full Raspberry Pi hardware compatibility maintained automatically
- **CI/CD Integration** - Automated builds and releases via GitHub Actions
- **Auto-Detection** - Network interfaces, WiFi adapters, and USB devices automatically configured
- **Safe Updates** - `apt upgrade` works without breaking hardware support
- **Share & Maintain** - Version control your image configurations, share with your team

## Key Features

### Modular Service Composition

Build images by combining service modules:

```bash
# Base Debian image
./bin/autobuild --image debian

# Debian + Incus + Docker
./bin/autobuild --image debian/qemu+docker

# Full stack: Incus + Docker + OpenWrt + Home Assistant + WiFi Hotspot
./bin/autobuild --image debian/qemu+docker+openwrt+hotspot+haos
```

Available services:
- **qemu** - Incus container/VM platform with KVM acceleration
- **docker** - Docker Engine with Portainer and Watchtower
- **haos** - Home Assistant OS in an Incus VM
- **openwrt** - OpenWrt router in an Incus container
- **hotspot** - WiFi access point (2.4GHz/5GHz)

### Automatic Hardware Detection

- **Network Interfaces** - Dual NIC? Automatic bridge configuration (br-wan + br-lan)
- **WiFi Adapters** - Dual-band WiFi? Auto-configures 2.4GHz + 5GHz access points
- **Zigbee Dongles** - USB Zigbee coordinators auto-passed to Home Assistant VM
- **Adaptive Configuration** - Services adapt to available hardware

### GitHub Actions CI/CD

- **Automated Builds** - Daily builds or on-demand via GitHub Actions
- **Multi-Stage Pipeline** - Parallel builds for faster releases
- **Automatic Releases** - Compressed images uploaded to GitHub Releases
- **Branch Strategy** - Stable releases on main, pre-releases on test/preview branches

### Safe System Updates

RaspiOS kernel and firmware packages are integrated via APT with pinning:

```bash
# Update everything safely
sudo apt update && sudo apt upgrade -y
```

Kernel, firmware, and WiFi/Bluetooth drivers update from RaspiOS repositories while all other packages update from Debian - no manual intervention required.

## Quick Start

### Prerequisites

```bash
sudo apt install -y parted e2fsprogs dosfstools qemu-utils rsync \
                    xz-utils genisoimage qemu-system-aarch64
```

### Build Your First Image

```bash
# Clone the repository
git clone https://github.com/Pikatsuto/raspberry-builds.git
cd raspberry-builds

# Build a base Debian image
./bin/autobuild --image debian

# Or build with services
./bin/autobuild --image debian/qemu+docker

# Flash to SD card
sudo dd if=debian-*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### Create a Custom Image

```bash
# Copy the base configuration
cp -r images/debian images/myproject

# Edit configuration
vim images/myproject/config.sh
# Set OUTPUT_IMAGE, IMAGE_SIZE, SERVICES, etc.

# Customize setup
vim images/myproject/services/base/setup.sh
# Add your package installations

# Build
./bin/autobuild --image myproject
```

## Documentation

- [Getting Started](wiki/Getting-Started.md) - Installation, first build, flashing
- [Architecture](wiki/Architecture.md) - How the build system works
- [Build System](wiki/Build-System.md) - Autobuild options, multi-stage pipeline
- [Service System](wiki/Services.md) - Creating and using service modules
- [GitHub Actions](wiki/GitHub-Actions.md) - CI/CD setup and workflows
- [Hardware Detection](wiki/Hardware-Detection.md) - Auto-configuration features
- [FAQ](wiki/FAQ.md) - Common questions and troubleshooting

## Use Cases

### Home Server
Build a Raspberry Pi home server with Docker, Portainer, and automatic hardware support.

### IoT Gateway
Create an IoT gateway with Home Assistant, Zigbee coordinator auto-detection, and dual WiFi AP.

### Network Router
Build a custom router with OpenWrt in a container, dual NIC bridge configuration, and WiFi hotspot.

### Development Platform
Create reproducible development environments with Incus containers/VMs and Docker.

### Team Deployment
Version control image configurations, build via CI/CD, deploy identical images across multiple devices.

## How It Works

1. **Base Images** - Downloads Raspberry Pi OS (boot/firmware) + Debian ARM64 (rootfs)
2. **Service Composition** - Combines setup scripts from selected services
3. **QEMU Build** - Installs packages in ARM64 QEMU VM, including RaspiOS kernel/firmware
4. **Merge** - Keeps RaspiOS boot partition, replaces root with configured Debian
5. **Compress** - PiShrink + xz compression for minimal image size

The result is a Debian ARM64 userspace with full Raspberry Pi hardware support and automatic updates.

## Project Status

**Current Support:**
- Raspberry Pi 4/5 (ARM64)
- Debian 13 (Trixie) ARM64
- Automatic hardware detection (network, WiFi, USB Zigbee)

**In Development:**
- Additional distribution support (Ubuntu, Fedora, Alpine)
- Expanded hardware detection (storage, audio, camera)

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues** - [GitHub Issues](https://github.com/Pikatsuto/raspberry-builds/issues)
- **Discussions** - [GitHub Discussions](https://github.com/Pikatsuto/raspberry-builds/discussions)
- **Wiki** - [Documentation Wiki](https://github.com/Pikatsuto/raspberry-builds/wiki)

---

**Built with** Raspberry Pi OS + Debian ARM64 + QEMU + GitHub Actions