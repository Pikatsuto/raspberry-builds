# Build System

Complete reference for the autobuild system and image creation.

## Autobuild Command

The `autobuild` script orchestrates the entire build process.

### Basic Usage

```bash
./bin/autobuild --image <image-name>
```

### Image Formats

**Physical directory format**:
```bash
./bin/autobuild --image debian
# Uses images/debian/config.sh
```

**Dynamic service composition**:
```bash
./bin/autobuild --image debian/qemu+docker+haos
# Uses images/debian/config.sh + combines services
```

### Common Options

```bash
# Build specific image
./bin/autobuild --image debian

# Build all images from .github/images.txt
./bin/autobuild --all-images

# List available images
./bin/autobuild --list-images

# Skip base image downloads (use cached)
./bin/autobuild --image debian --skip-download

# Skip QEMU setup (use existing Debian image)
./bin/autobuild --image debian --skip-qemu

# Skip compression
./bin/autobuild --image debian --skip-compress

# Clean previous builds
./bin/autobuild --image debian --clean
```

### Combined Options

```bash
# Quick rebuild without downloads or compression
./bin/autobuild --image debian --skip-download --skip-compress

# Rebuild with new setup scripts, skip downloads
./bin/autobuild --image debian --skip-download --clean
```

## Build Stages

### Stage 1: Download & Prepare

**Actions**:
- Download RaspiOS Lite image (if not cached)
- Download Debian ARM64 image (if not cached)
- Parse image configuration (config.sh)
- Resolve service dependencies
- Combine setup.sh from all services
- Merge setupfiles/ directories
- Create setup.iso with combined configuration
- Generate cloud-init seed.img OR inject first-boot service

**Outputs**:
- `raspios-lite.img` (in distro directory)
- `debian-arm64.raw` (in distro directory)
- `setup.iso` (in image directory)
- `seed.img` (in cloudinit/ directory, if CLOUD=true)

**Environment Variables**:
```bash
RASPIOS_URL="https://downloads.raspberrypi.org/..."
IMAGE_URL="https://cloud.debian.org/..."  # from config.sh
CLOUD=true  # or false, from config.sh
SERVICES="base qemu docker"  # from config.sh or dynamic
```

### Stage 2: QEMU Setup

**Actions**:
- Convert Debian image to raw format (if qcow2)
- Launch QEMU ARM64 VM:
  - RAM: QEMU_RAM (from config.sh)
  - CPUs: QEMU_CPUS (from config.sh)
  - Disk: Debian image
  - CD-ROM 1: seed.img (if cloud-init mode)
  - CD-ROM 2: setup.iso
- Wait for setup completion (VM auto-shutdown)
- Monitor progress via QEMU serial console

**QEMU Configuration**:
```bash
qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a72 \
    -m $QEMU_RAM \
    -smp $QEMU_CPUS \
    -drive file=debian.raw,format=raw,if=virtio \
    -drive file=seed.img,format=raw,if=virtio,readonly=on \  # cloud-init
    -drive file=setup.iso,format=raw,if=virtio,readonly=on \
    -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
    -nographic \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0
```

**Inside QEMU**:
1. Cloud-init or first-boot service creates user
2. Setup script mounts setup.iso
3. Executes combined setup.sh:
   - Adds RaspiOS repository
   - Installs RaspiOS kernel/firmware
   - Installs service packages
   - Copies setupfiles to /etc/setupfiles/
   - Installs first-boot scripts
4. Shuts down VM

**Timeout**: 30 minutes (configurable via `QEMU_TIMEOUT`)

### Stage 3: Merge

**Actions**:
- Call `merge-debian-raspios.sh`
- Keep RaspiOS boot partition (FAT32)
- Replace RaspiOS root with Debian root
- Restore RaspiOS fstab (for correct partition UUIDs)
- Resize root partition to IMAGE_SIZE

**Merge Process** (10 sub-stages):
1. Dependency verification
2. RaspiOS preparation (decompress if .xz)
3. Debian preparation (convert to raw if needed)
4. Size analysis
5. Output image creation (copy of RaspiOS)
6. Image resizing
7. Loop device mounting
8. Backup RaspiOS fstab
9. **Rootfs replacement**:
   - Delete RaspiOS root
   - Rsync Debian root with `-aAXv` (preserve all attributes)
   - Create `/boot/firmware` mount point
   - Restore fstab
10. Cleanup

**Output**: `<image-name>.img`

### Stage 4: Compress

**Actions**:
- Run PiShrink to minimize filesystem
- Compress with xz (parallel, level 6)
- Generate SHA256 checksum

**PiShrink**:
```bash
pishrink.sh -z <image>.img <image>.img.xz
# -z: Compress with xz after shrinking
```

**Output**: `<image-name>.img.xz`

## Configuration Files

### Image Configuration (config.sh)

**Location**: `images/<distro>/config.sh` or `images/<image-name>/config.sh`

**Required Variables**:
```bash
# Output filename
OUTPUT_IMAGE="debian-base.img"

# Final image size (supports K, M, G suffixes)
IMAGE_SIZE="8G"

# QEMU resources
QEMU_RAM="8G"
QEMU_CPUS="4"

# Boot mode (true = cloud-init, false = first-boot service)
CLOUD=true

# Base distribution image URL
IMAGE_URL="https://cloud.debian.org/images/cloud/trixie-backports/daily/latest/debian-13-backports-genericcloud-arm64-daily.raw"

# Services to include (space-separated)
SERVICES="base qemu docker"

# Description (optional, for documentation)
DESCRIPTION="Debian with Incus and Docker"
```

**Optional Variables**:
```bash
# Custom RaspiOS URL (default: RaspiOS Lite trixie)
RASPIOS_URL="https://downloads.raspberrypi.org/..."

# QEMU timeout in seconds (default: 1800 = 30 minutes)
QEMU_TIMEOUT=3600

# Skip PiShrink compression
SKIP_PISHRINK=false
```

### Service Configuration

Each service directory contains:

**setup.sh** (required):
```bash
#!/bin/bash
set -e

# Install packages
apt update
apt install -y package1 package2

# Configure system
systemctl enable service1
```

**first-boot/init.sh** (optional):
```bash
#!/bin/bash
set -e

# Runtime configuration
# Detect hardware, create containers, etc.
```

**depends.sh** (optional):
```bash
# Declare dependencies
DEPENDS_ON="qemu"
```

**motd.sh** (optional):
```bash
# MOTD content
cat <<'EOF'
Service UI: https://raspberry-ip:9000
Username: admin
EOF
```

**setupfiles/** (optional):
- Static configuration files
- Copied to /etc/setupfiles/ during build

## Build Artifacts

### Directory Structure

```
images/
└── debian/                       # Distribution directory
    ├── config.sh                 # Base configuration
    ├── cloudinit/                # Cloud-init mode
    │   ├── user-data
    │   ├── meta-data
    │   └── seed.img              # Auto-generated
    ├── services/                 # Service modules
    │   ├── base/
    │   ├── qemu/
    │   └── docker/
    ├── raspios-lite.img          # Downloaded RaspiOS (cached)
    ├── debian-arm64.raw          # Downloaded Debian (cached)
    └── debian-qemu-docker/       # Dynamic image (created during build)
        ├── config.sh             # Generated from base + overrides
        ├── setup.sh              # Combined from services
        ├── setup.iso             # Generated
        ├── setupfiles/           # Merged from services
        ├── debian-qemu-docker.img      # Final image
        └── debian-qemu-docker.img.xz   # Compressed
```

### Artifact Persistence

**Persistent** (cached between builds):
- `raspios-lite.img` - RaspiOS base image
- `debian-arm64.raw` - Debian base image (modified by QEMU)
- Final `.img` and `.img.xz` files

**Temporary** (cleaned with `--clean`):
- Dynamic image directories (e.g., `debian-qemu-docker/`)
- `setup.iso`
- `seed.img` (regenerated each build)

**Skip Downloads**:
```bash
# Use cached base images
./bin/autobuild --image debian --skip-download
```

**Skip QEMU**:
```bash
# Use existing configured Debian image (skip setup in QEMU)
./bin/autobuild --image debian --skip-qemu
```

## Service Dependency Resolution

### Dependency Declaration

**Example**: Home Assistant requires Incus

**File**: `images/debian/services/haos/depends.sh`
```bash
DEPENDS_ON="qemu"
```

### Resolution Algorithm

**Input**: `debian/qemu+docker+haos`

**Process**:
1. Parse services: `qemu`, `docker`, `haos`
2. Resolve dependencies:
   - `qemu`: no dependencies
   - `docker`: no dependencies
   - `haos`: depends on `qemu` (already in list)
3. Remove duplicates
4. Order by dependencies: `base` → `qemu` → `docker` → `haos`

**Output**: `SERVICES="base qemu docker haos"`

### Build Order

Services are built in dependency order:

1. **base** (always first)
2. Dependencies (e.g., `qemu` for `haos`)
3. Requested services

**Setup script combination**:
```bash
{
  cat services/base/setup.sh
  cat services/qemu/setup.sh
  cat services/docker/setup.sh
  cat services/haos/setup.sh
} > combined-setup.sh
```

## Merge Process Details

### Partition Operations

**1. RaspiOS Boot Partition** (kept):
```bash
# Mount as read-only (no changes)
mount -o ro /dev/loop0p1 /mnt/raspios-boot
```

**2. RaspiOS Root Partition** (backed up, then replaced):
```bash
# Backup fstab only
cp /mnt/raspios-root/etc/fstab /tmp/raspios-fstab

# Delete entire rootfs
rm -rf /mnt/raspios-root/*
```

**3. Debian Root Partition** (source):
```bash
# Rsync to RaspiOS root
rsync -aAXv /mnt/debian-root/ /mnt/raspios-root/

# Preserve attributes:
# -a: archive mode (recursive, preserve permissions, times, symlinks)
# -A: preserve ACLs
# -X: preserve extended attributes
# -v: verbose
```

**4. Restore RaspiOS fstab**:
```bash
# RaspiOS fstab has correct partition UUIDs
cp /tmp/raspios-fstab /mnt/raspios-root/etc/fstab
```

**5. Create boot mount point**:
```bash
# Ensure /boot/firmware exists for boot partition
mkdir -p /mnt/raspios-root/boot/firmware
```

### Size Calculation

**Automatic sizing**:
```bash
# Get Debian image virtual size
DEBIAN_SIZE=$(qemu-img info --output=json debian.raw | jq -r '.["virtual-size"]')

# Add overhead (1-2GB)
AUTO_SIZE=$((DEBIAN_SIZE + 2 * 1024 * 1024 * 1024))

# Use IMAGE_SIZE from config if larger
FINAL_SIZE=$(max $AUTO_SIZE $IMAGE_SIZE)
```

**Manual override**:
```bash
./bin/merge-debian-raspios.sh raspios.img debian.raw -s 16G
```

### Partition Expansion

**During merge**:
```bash
# Resize partition table
parted /dev/loop0 resizepart 2 100%

# Resize ext4 filesystem
e2fsck -f /dev/loop0p2
resize2fs /dev/loop0p2
```

**On first boot** (rpi-first-boot.sh):
```bash
# Expand to fill entire SD card
parted /dev/mmcblk0 resizepart 2 100%
resize2fs /dev/mmcblk0p2
reboot
```

## Troubleshooting Builds

### QEMU Won't Boot

**Symptoms**: QEMU hangs at boot

**Causes**:
- Missing UEFI firmware
- Wrong image format
- Insufficient RAM

**Solutions**:
```bash
# Install UEFI firmware
sudo apt install qemu-efi-aarch64

# Check image format
qemu-img info debian.raw

# Increase RAM in config.sh
QEMU_RAM="8G"
```

### QEMU Timeout

**Symptoms**: Build fails with "QEMU timeout"

**Causes**:
- Slow network (downloading packages)
- Insufficient resources
- Stuck on interactive prompt

**Solutions**:
```bash
# Increase timeout
QEMU_TIMEOUT=3600  # 1 hour

# Increase resources
QEMU_RAM="8G"
QEMU_CPUS="4"

# Check QEMU logs
cat qemu-*.log
```

### Merge Fails

**Symptoms**: Error during merge stage

**Causes**:
- Insufficient disk space
- Corrupted images
- Partition layout mismatch

**Solutions**:
```bash
# Check disk space
df -h

# Re-download base images
rm images/debian/raspios-lite.img images/debian/debian-arm64.raw
./bin/autobuild --image debian

# Check partition layout
fdisk -l raspios.img
fdisk -l debian.raw
```

### Image Won't Boot

**Symptoms**: Raspberry Pi won't boot image

**Causes**:
- Corrupted SD card
- Wrong fstab UUIDs
- Missing boot files

**Solutions**:
```bash
# Verify image integrity
sha256sum image.img.xz

# Check SD card
sudo badblocks -v /dev/sdX

# Re-flash image
xz -dc image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

## Advanced Usage

### Custom RaspiOS Version

```bash
# In config.sh
RASPIOS_URL="https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-24/2024-11-24-raspios-trixie-arm64-lite.img.xz"
```

### Custom Debian Version

```bash
# In config.sh
IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-arm64.raw"
```

### Parallel Builds

```bash
# Build multiple images in parallel
./bin/autobuild --image debian &
./bin/autobuild --image debian/qemu+docker &
wait
```

**Warning**: Ensure sufficient RAM and disk space for parallel builds.

### CI/CD Integration

See [GitHub Actions](GitHub-Actions.md) for automated builds.

## Next Steps

- [Learn about available services](Services.md)
- [Create a custom image](Custom-Images.md)
- [Set up CI/CD](GitHub-Actions.md)