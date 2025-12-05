#!/bin/bash
# Configuration for "raspivirt-qemu+docker" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-qemu+docker.img"

# Final image size
IMAGE_SIZE="2G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Complete virtualization and containerization platform combining Incus containers/VMs with Docker Engine on Raspberry Pi"
