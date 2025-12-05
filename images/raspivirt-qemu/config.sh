#!/bin/bash
# Configuration for "raspivirt-qemu" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-qemu.img"

# Final image size
IMAGE_SIZE="6G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Base virtualization platform with Incus container/VM manager, KVM support, and bridged networking on Raspberry Pi"
