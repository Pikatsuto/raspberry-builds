#!/bin/bash
set -e

# ============================================================================
# Debian rootfs automatic configuration script
# Executed at first boot via first-boot service in QEMU
# ============================================================================

echo "======================================"
echo "Starting rootfs configuration"
echo "======================================"

# System update
echo "[1/5] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

# Install essential packages
echo "[2/5] Installing essential packages..."
apt install -y \
    curl \
    wget \
    sudo \
    openssh-server \
    ca-certificates \
    gnupg \
    systemd \
    net-tools \
    parted

# Install RaspiOS kernel and firmware
echo "[3/5] Installing Raspberry Pi kernel and firmware..."

# Remove old Debian kernel and firmware BEFORE installing RaspiOS packages
echo "Removing old Debian kernel and firmware..."
apt purge -y 'linux-image-*' 'linux-headers-*' 'linux-kbuild-*' || true

# Add RaspiOS repository
mkdir -p /etc/apt/keyrings
curl -fsSL http://archive.raspberrypi.com/debian/raspberrypi.gpg.key | gpg --dearmor -o /usr/share/keyrings/raspberrypi-archive-keyring.pgp

cat > /etc/apt/sources.list.d/raspi.sources << 'EOF'
Types: deb
URIs: http://archive.raspberrypi.com/debian/
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/raspberrypi-archive-keyring.pgp
EOF

# Configure APT pinning
cat > /etc/apt/preferences.d/raspi-pin << 'EOF'
# Pin RaspiOS packages for kernel/firmware/bootloader
Package: raspberrypi-kernel raspberrypi-bootloader libraspberrypi* firmware-brcm80211
Pin: release o=Raspberry Pi Foundation
Pin-Priority: 1001

# Default Debian packages
Package: *
Pin: release o=Debian
Pin-Priority: 500
EOF

# Install RaspiOS packages
apt update
apt install -y \
    linux-image-rpi-v8 \
    linux-image-rpi-2712 \
    linux-headers-rpi-v8 \
    linux-headers-rpi-2712 \
    raspi-firmware \
    firmware-brcm80211

# System configuration
echo "[4/5] System configuration..."

# Timezone
timedatectl set-timezone Europe/Paris || true

# Locale
locale-gen fr_FR.UTF-8 || true

# Enable services
echo "[5/5] Enabling services..."
systemctl enable ssh

# Cleanup
echo "Cleaning up..."
apt autoremove -y
apt clean
rm -rf /var/lib/apt/lists/*

# Create flag file to indicate setup is complete
echo "Finalizing..."
touch /root/setup-completed
date > /root/setup-completed

echo "======================================"
echo "Configuration completed successfully!"
echo "======================================"

poweroff