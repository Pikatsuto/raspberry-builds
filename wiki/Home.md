# Raspberry Pi Image Builder - Documentation

Welcome to the Raspberry Pi Image Builder documentation! This system makes it easy to build, customize, and maintain production-ready Raspberry Pi images.

## What is This?

A modular automated build system that creates custom Raspberry Pi OS images by:
- Combining Raspberry Pi OS firmware with Debian ARM64
- Installing packages via QEMU ARM64 emulation
- Composing images from reusable service modules
- Automating builds via GitHub Actions CI/CD
- Auto-detecting and configuring hardware

## Quick Links

### Getting Started
- [Installation & First Build](Getting-Started.md)
- [Flashing Images to SD Cards](Getting-Started/#flashing-to-sd-card)
- [First Boot & Login](Getting-Started/#first-boot)

### Core Concepts
- [Architecture Overview](Architecture.md)
- [Build System](Build-System.md)
- [Service System](Services.md)

### Advanced Topics
- [Creating Custom Images](Custom-Images.md)
- [Creating Custom Services](Custom-Services.md)
- [GitHub Actions CI/CD](GitHub-Actions.md)
- [Hardware Auto-Detection](Hardware-Detection.md)

### Reference
- [Available Images](Available-Images.md)
- [Available Services](Available-Services.md)
- [Command Reference](Command-Reference.md)
- [Configuration Reference](Configuration-Reference.md)

### Help
- [FAQ](FAQ.md)
- [Troubleshooting](Troubleshooting.md)
- [GitHub Issues](https://github.com/Pikatsuto/raspberry-builds/issues)

## Why Use This?

### Easy to Build
```bash
# One command to build a custom image
./bin/autobuild --image debian/qemu+docker+haos
```

### Easy to Maintain
- Version control your image configurations
- Automated builds via GitHub Actions
- Safe `apt upgrade` - kernel and firmware update automatically

### Easy to Share
- Share image configurations with your team
- Reproducible builds across environments
- Pre-built images in GitHub Releases

### Easy to Customize
- Modular service system
- Add your own services
- Full control over packages and configuration

## Key Features

- **Modular Services** - Compose images from qemu, docker, haos, openwrt, hotspot
- **Auto-Detection** - Network interfaces, WiFi, Zigbee dongles
- **CI/CD Ready** - GitHub Actions for automated builds
- **Safe Updates** - RaspiOS kernel via APT with pinning
- **Full Hardware Support** - RP1 drivers, WiFi, Bluetooth, GPIO

## What Can You Build?

- **Home Server** - Docker + Portainer + Watchtower
- **IoT Gateway** - Home Assistant + Zigbee auto-detection
- **Network Router** - OpenWrt + WiFi hotspot + dual NIC
- **Virtualization Platform** - Incus containers and VMs
- **Custom Appliance** - Your own service modules

## Architecture at a Glance

```
RaspiOS Boot Partition (FAT32)     Debian Rootfs (ext4)
├── bootloader                     ├── /bin, /usr, /etc (Debian)
├── kernel                         ├── RaspiOS kernel packages (via APT)
├── firmware                       ├── Your services
└── config.txt                     └── Auto-hardware detection
         ↓                                    ↓
         └────────── Merged Image ───────────┘
```

## Support

- Raspberry Pi 4/5 (ARM64)
- Debian 13 (Trixie) ARM64
- Additional distributions in development

## Next Steps

1. [Install dependencies and build your first image](Getting-Started.md)
2. [Understand how the build system works](Architecture.md)
3. [Explore available services](Available-Services.md)
4. [Create your own custom image](Custom-Images.md)

---

**Happy Building!**