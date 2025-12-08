#!/bin/bash
# Debian base image configuration

# Output image name
OUTPUT_IMAGE="debian-base.img"

# Final image size
IMAGE_SIZE="4G"

# RAM and CPU for QEMU
QEMU_RAM="4G"
QEMU_CPUS="4"

# Description
DESCRIPTION="Debian base with RaspiOS kernel"

# Base distribution
CLOUD=true
IMAGE_URL="https://cloud.debian.org/images/cloud/trixie-backports/daily/latest/debian-13-backports-genericcloud-arm64-daily.raw"

# Services to combine (base is always added automatically)
SERVICES="base"
