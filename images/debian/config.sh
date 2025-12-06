#!/bin/bash
# Configuration for "raspivirt-qemu" image

# Output image name
OUTPUT_IMAGE="rpi-debian.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Base virtualization platform with Incus container/VM manager, KVM support, and bridged networking on Raspberry Pi"
