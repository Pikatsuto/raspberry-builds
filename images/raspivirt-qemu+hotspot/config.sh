#!/bin/bash
# Configuration for "raspivirt-qemu+hotspot" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-qemu+hotspot.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Base virtualization platform with Incus container/VM manager, KVM support, bridged networking, and WiFi hotspot on Raspberry Pi"
