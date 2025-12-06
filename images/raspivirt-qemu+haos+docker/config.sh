#!/bin/bash
# Configuration for "raspivirt-qemu+haos+docker" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-qemu+haos+docker.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Home automation platform with Incus virtualization, Docker Engine, and auto-deployed Home Assistant OS VM on Raspberry Pi"
