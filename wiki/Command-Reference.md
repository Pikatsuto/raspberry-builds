# Command Reference

Quick reference for build commands.

## autobuild

Main build script.

### Basic Usage

```bash
./bin/autobuild --image <name>
```

### Options

```bash
--image <name>          Build specific image
--all-images            Build all images from .github/images.txt
--list-images           List available images
--skip-download         Use cached base images
--skip-qemu             Skip QEMU setup
--skip-compress         Skip PiShrink compression
--clean                 Clean previous build artifacts
```

### Examples

See [Build System - Autobuild Command](Build-System/#autobuild-command) for comprehensive examples and options.

## merge-debian-raspios.sh

Low-level merge script (called by autobuild).

### Usage

```bash
./bin/merge-debian-raspios.sh <raspios-image> <debian-image> [options]
```

### Options

```bash
-o, --output <file>     Output image name
-s, --size <size>       Final image size (e.g., 16G)
-k, --keep-kernel       Use Debian kernel (not recommended)
```

### Examples

```bash
# Basic merge
./bin/merge-debian-raspios.sh raspios.img debian.raw

# Custom output and size
./bin/merge-debian-raspios.sh raspios.img debian.raw -o custom.img -s 16G
```

## Flashing Commands

```bash
# Decompress and flash
xz -dc image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync

# Flash uncompressed
sudo dd if=image.img of=/dev/sdX bs=4M status=progress conv=fsync

# Sync
sync
```

## System Commands (on Raspberry Pi)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Check first-boot logs
sudo journalctl -u services-first-boot

# Check service status
sudo systemctl status docker
incus list

# Network info
ip addr show
nmcli con show
```

See [Build System](Build-System.md) for detailed usage.