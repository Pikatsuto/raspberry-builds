#!/bin/bash
# Configuration for "raspivirt-incus+docker" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-incus+docker.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Raspberry Pi image with Incus, KVM virtualization and br-wan bridge"
