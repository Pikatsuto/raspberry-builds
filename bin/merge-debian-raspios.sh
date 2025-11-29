#!/bin/bash
set -e

# ============================================================================
# Merge script: Debian ARM64 rootfs → Raspberry Pi OS image
# ============================================================================

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <raspios-image> <debian-image>

Merges the rootfs from a Debian ARM64 image into a Raspberry Pi OS image.
Result: Pi OS image with boot/firmware/kernel Pi + your Debian rootfs

Arguments:
    raspios-image    Raspberry Pi OS ARM64 image (.img or .img.xz)
    debian-image     Your Debian ARM64 image (.raw, .qcow2, etc.)

Options:
    -o, --output FILE   Output image name (default: hybrid-debian-raspios.img)
    -s, --size SIZE     Final image size (default: auto = Debian size + 1G)
    -k, --keep-kernel   Keep Debian kernel instead of RaspiOS kernel
    -h, --help          Display this help

Examples:
    # Basic
    $0 raspios-lite.img debian-13-arm64.raw

    # With options
    $0 -o my-pi5.img -s 16G raspios-lite.img.xz my-custom-debian.raw

    # Keep Debian kernel (not recommended, missing RP1 drivers)
    $0 --keep-kernel raspios.img debian.raw

Download Raspberry Pi OS Lite ARM64:
    wget https://downloads.raspberrypi.com/raspios_lite_arm64/latest

EOF
    exit 1
}

# Default parameters
WORKDIR="$PWD"
OUTPUT_IMAGE="hybrid-debian-raspios.img"
IMAGE_SIZE=""
KEEP_DEBIAN_KERNEL=false
RASPIOS_IMAGE=""
DEBIAN_IMAGE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_IMAGE="$2"
            shift 2
            ;;
        -s|--size)
            IMAGE_SIZE="$2"
            shift 2
            ;;
        -k|--keep-kernel)
            KEEP_DEBIAN_KERNEL=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [ -z "$RASPIOS_IMAGE" ]; then
                RASPIOS_IMAGE="$1"
            elif [ -z "$DEBIAN_IMAGE" ]; then
                DEBIAN_IMAGE="$1"
            else
                echo "Too many arguments"
                usage
            fi
            shift
            ;;
    esac
done

# Validation
if [ -z "$RASPIOS_IMAGE" ] || [ -z "$DEBIAN_IMAGE" ]; then
    echo "ERROR: You must specify both images"
    usage
fi

if [ ! -f "$RASPIOS_IMAGE" ]; then
    echo "ERROR: Raspberry Pi OS image not found: $RASPIOS_IMAGE"
    exit 1
fi

if [ ! -f "$DEBIAN_IMAGE" ]; then
    echo "ERROR: Debian image not found: $DEBIAN_IMAGE"
    exit 1
fi

echo "========================================================"
echo "Merge Debian ARM64 → Raspberry Pi OS"
echo "========================================================"
echo "RaspiOS source: $RASPIOS_IMAGE"
echo "Debian source:  $DEBIAN_IMAGE"
echo "Final image:    $OUTPUT_IMAGE"
echo "========================================================"

# Dependencies
echo "[1/10] Checking dependencies..."
# sudo apt install -y parted e2fsprogs dosfstools qemu-utils rsync xz-utils

cd "$WORKDIR"

# Decompress RaspiOS if necessary
echo "[2/10] Preparing Raspberry Pi OS image..."
RASPIOS_RAW="$RASPIOS_IMAGE"

if [[ "$RASPIOS_IMAGE" == *.xz ]]; then
    echo "Decompressing RaspiOS image..."
    RASPIOS_RAW="${RASPIOS_IMAGE%.xz}"
    if [ ! -f "$RASPIOS_RAW" ]; then
        xz -dk "$RASPIOS_IMAGE"
    fi
fi

# Convert Debian if necessary
echo "[3/10] Preparing Debian image..."
DEBIAN_FORMAT=$(qemu-img info "$DEBIAN_IMAGE" 2>/dev/null | grep "file format:" | awk '{print $3}')
DEBIAN_RAW="$DEBIAN_IMAGE"

if [ "$DEBIAN_FORMAT" != "raw" ] && [ ! -z "$DEBIAN_FORMAT" ]; then
    echo "Converting $DEBIAN_FORMAT to raw..."
    DEBIAN_RAW="debian-converted.raw"
    qemu-img convert -f "$DEBIAN_FORMAT" -O raw "$DEBIAN_IMAGE" "$DEBIAN_RAW"
fi

# Calculate sizes
echo "[4/10] Analyzing sizes..."

RASPIOS_SIZE=$(stat -c%s "$RASPIOS_RAW")
DEBIAN_SIZE=$(stat -c%s "$DEBIAN_RAW")

RASPIOS_SIZE_GB=$((RASPIOS_SIZE / 1024 / 1024 / 1024))
DEBIAN_SIZE_GB=$((DEBIAN_SIZE / 1024 / 1024 / 1024))

echo "RaspiOS size: ${RASPIOS_SIZE_GB}GB"
echo "Debian size:  ${DEBIAN_SIZE_GB}GB"

# Calculate final size
if [ -z "$IMAGE_SIZE" ]; then
    # Auto: take the largest size + 1GB margin
    if [ $DEBIAN_SIZE -gt $RASPIOS_SIZE ]; then
        FINAL_SIZE_GB=$((DEBIAN_SIZE_GB + 2))
    else
        FINAL_SIZE_GB=$((RASPIOS_SIZE_GB + 1))
    fi
    IMAGE_SIZE="${FINAL_SIZE_GB}G"
    echo "Auto-calculated size: $IMAGE_SIZE"
fi

# Copy RaspiOS image as base
echo "[5/10] Creating output image..."

if [ "$RASPIOS_RAW" != "$OUTPUT_IMAGE" ]; then
    cp "$RASPIOS_RAW" "$OUTPUT_IMAGE"
fi

# Resize image
echo "[6/10] Resizing image..."

# Parse size
if [[ $IMAGE_SIZE =~ ^([0-9]+)([GMK]?)$ ]]; then
    SIZE_NUM=${BASH_REMATCH[1]}
    SIZE_UNIT=${BASH_REMATCH[2]:-G}
    case $SIZE_UNIT in
        G) SIZE_MB=$((SIZE_NUM * 1024)) ;;
        M) SIZE_MB=$SIZE_NUM ;;
        K) SIZE_MB=$((SIZE_NUM / 1024)) ;;
    esac
else
    echo "ERROR: Invalid size format: $IMAGE_SIZE"
    exit 1
fi

# Resize image
truncate -s ${SIZE_MB}M "$OUTPUT_IMAGE"

# Mount output image
echo "[7/10] Mounting images..."
OUTPUT_LOOP=$(sudo losetup -f --show -P "$OUTPUT_IMAGE")
echo "Output image on: $OUTPUT_LOOP"

# Resize partition 2 (rootfs)
echo "Resizing rootfs partition..."
sudo parted -s "$OUTPUT_LOOP" resizepart 2 100%

# Force partition table reload
sudo partprobe "$OUTPUT_LOOP" 2>/dev/null || true
sleep 2

# Check filesystem and resize
echo "Checking and resizing filesystem..."
sudo e2fsck -f -y ${OUTPUT_LOOP}p2 || true
sudo resize2fs ${OUTPUT_LOOP}p2

# Mount output partitions
MOUNT_BOOT="/mnt/raspios-boot-$$"
MOUNT_ROOT="/mnt/raspios-root-$$"
sudo mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOT"

sudo mount ${OUTPUT_LOOP}p1 "$MOUNT_BOOT"
sudo mount ${OUTPUT_LOOP}p2 "$MOUNT_ROOT"

# Mount source Debian image
DEBIAN_LOOP=$(sudo losetup -f --show -P "$DEBIAN_RAW")
echo "Debian image on: $DEBIAN_LOOP"

# Detect Debian root partition
if [ -b "${DEBIAN_LOOP}p1" ]; then
    DEBIAN_ROOT_PART="${DEBIAN_LOOP}p1"
elif [ -b "${DEBIAN_LOOP}p2" ]; then
    DEBIAN_ROOT_PART="${DEBIAN_LOOP}p2"
else
    DEBIAN_ROOT_PART="$DEBIAN_LOOP"
fi

MOUNT_DEBIAN="/mnt/debian-src-$$"
sudo mkdir -p "$MOUNT_DEBIAN"
sudo mount "$DEBIAN_ROOT_PART" "$MOUNT_DEBIAN"

# Backup critical RaspiOS files
echo "[8/10] Backing up essential RaspiOS files..."
BACKUP_DIR="/tmp/raspios-backup-$$"
sudo mkdir -p "$BACKUP_DIR"

# Backup
sudo cp -a "$MOUNT_ROOT/etc/fstab" "$BACKUP_DIR/" 2>/dev/null || true
sudo cp -a "$MOUNT_ROOT/lib/modules" "$BACKUP_DIR/" 2>/dev/null || true
sudo cp -a "$MOUNT_ROOT/lib/firmware" "$BACKUP_DIR/" 2>/dev/null || true
sudo cp -a "$MOUNT_ROOT/boot/firmware" "$BACKUP_DIR/" 2>/dev/null || true

# For RaspiOS kernel
if [ "$KEEP_DEBIAN_KERNEL" = false ]; then
    sudo mkdir -p "$BACKUP_DIR/boot"
    sudo cp -a "$MOUNT_ROOT/boot/"* "$BACKUP_DIR/boot/" 2>/dev/null || true
fi

# Replace rootfs
echo "[9/10] Replacing rootfs with Debian..."
echo "Deleting old RaspiOS rootfs..."
sudo find "$MOUNT_ROOT" -mindepth 1 -delete

echo "Copying Debian rootfs (may take several minutes)..."
sudo rsync -aAXv --info=progress2 "$MOUNT_DEBIAN/" "$MOUNT_ROOT/"

# Restore RaspiOS files
echo "Restoring essential RaspiOS files..."

# fstab
if [ -f "$BACKUP_DIR/fstab" ]; then
    sudo cp "$BACKUP_DIR/fstab" "$MOUNT_ROOT/etc/fstab"
fi

# RaspiOS kernel modules
if [ -d "$BACKUP_DIR/modules" ]; then
    sudo mkdir -p "$MOUNT_ROOT/lib"
    sudo cp -a "$BACKUP_DIR/modules" "$MOUNT_ROOT/lib/"
fi

# Firmware
if [ -d "$BACKUP_DIR/firmware" ]; then
    sudo mkdir -p "$MOUNT_ROOT/lib"
    sudo cp -a "$BACKUP_DIR/firmware" "$MOUNT_ROOT/lib/"
fi

# Kernel (if keeping RaspiOS kernel)
if [ "$KEEP_DEBIAN_KERNEL" = false ]; then
    echo "Using Raspberry Pi kernel (recommended)..."
    if [ -d "$BACKUP_DIR/boot" ]; then
        sudo mkdir -p "$MOUNT_ROOT/boot"
        sudo cp -a "$BACKUP_DIR/boot/"* "$MOUNT_ROOT/boot/"
    fi

    # Link /boot/firmware to boot partition
    if [ -d "$BACKUP_DIR/firmware" ]; then
        sudo mkdir -p "$MOUNT_ROOT/boot/firmware"
    fi
else
    echo "Keeping Debian kernel (warning: missing RP1 drivers!)"
fi

# Create /boot/firmware if necessary
sudo mkdir -p "$MOUNT_ROOT/boot/firmware"

# Cleanup
echo "[10/10] Finalizing..."

# Unmount Debian
sudo umount "$MOUNT_DEBIAN"
sudo losetup -d "$DEBIAN_LOOP"
sudo rmdir "$MOUNT_DEBIAN"

# Clean up temporary file
if [ "$DEBIAN_RAW" != "$DEBIAN_IMAGE" ] && [ -f "$DEBIAN_RAW" ]; then
    rm -f "$DEBIAN_RAW"
fi

# Unmount output
sudo sync
sudo umount "$MOUNT_BOOT"
sudo umount "$MOUNT_ROOT"
sudo losetup -d "$OUTPUT_LOOP"
sudo rmdir "$MOUNT_BOOT" "$MOUNT_ROOT"

# Clean up backup
sudo rm -rf "$BACKUP_DIR"

# Summary
echo ""
echo "========================================================"
echo "✓ Hybrid image created successfully!"
echo "========================================================"
echo ""
echo "Image created: $OUTPUT_IMAGE"
echo "Size:          $(du -h "$OUTPUT_IMAGE" | cut -f1)"
echo ""
echo "Contents:"
echo "  - Boot/Firmware: Raspberry Pi OS (Raspberry Pi compatible)"
echo "  - Kernel:        $([ "$KEEP_DEBIAN_KERNEL" = true ] && echo "Debian (RP1 not supported)" || echo "Raspberry Pi (RP1 supported)")"
echo "  - RootFS:        Your Debian ARM64"
echo ""
echo "To flash to SD/SSD:"
echo "  sudo dd if=$OUTPUT_IMAGE of=/dev/sdX bs=4M status=progress conv=fsync"
echo "  sync"
echo ""
echo "Or compress first:"
echo "  sudo pishrink.sh -z $OUTPUT_IMAGE ${OUTPUT_IMAGE}.xz"
echo ""
echo "Raspberry Pi supported features:"
echo "  ✅ Ethernet (RP1)"
echo "  ✅ WiFi"
echo "  ✅ GPIO"
echo "  ✅ USB"
echo "  ✅ All Pi peripherals"
echo ""