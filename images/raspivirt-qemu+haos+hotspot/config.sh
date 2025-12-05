#!/bin/bash
# Configuration for "raspivirt-qemu+haos+hotspot" image

# Output image name
OUTPUT_IMAGE="rpi-raspivirt-qemu+haos+hotspot.img"

# Final image size
IMAGE_SIZE="2G"

# RAM and CPU for QEMU
QEMU_RAM="8G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Home automation platform with Incus virtualization, auto-deployed Home Assistant OS VM, and WiFi hotspot on Raspberry Pi"
