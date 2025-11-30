#!/bin/bash
# Configuration for "debian-generic" image

# Output image name
OUTPUT_IMAGE="rpi-debian-generic.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="4G"
QEMU_CPUS="2"

# Description
DESCRIPTION="Basic Debian ARM64 image without cloud-init (first-boot service)"