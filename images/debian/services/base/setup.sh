#!/bin/bash
# Base service - Common system configuration for all images
# This script installs essential packages, RaspiOS kernel/firmware, and sets up basic system configuration

echo "====== BASE SERVICE ======"

# System update
echo "[BASE] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

# Install essential packages
echo "[BASE] Installing essential packages..."
apt install -y \
    curl \
    wget \
    sudo \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release \
    network-manager \
    systemd \
    bridge-utils \
    net-tools \
    iptables \
    parted \
    nmap \
    netcat-openbsd \
    dnsutils

# Install RaspiOS kernel and firmware
echo "[BASE] Installing Raspberry Pi kernel and firmware..."

# Remove old Debian kernel and firmware BEFORE installing RaspiOS packages
echo "  Removing old Debian kernel and firmware..."
apt purge -y 'linux-image-*' 'linux-headers-*' 'linux-kbuild-*' || true

# Add RaspiOS repository
install -m 0755 -d /etc/apt/keyrings
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

# Enable non-free repositories for WiFi firmware
echo "[BASE] Enabling non-free repositories for WiFi firmware..."
cat > /etc/apt/sources.list.d/debian-non-free.sources << 'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-backports
Components: main non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

# Install RaspiOS packages
apt update
apt install -y raspberrypi-archive-keyring --reinstall
apt install -y \
    linux-image-rpi-v8 \
    linux-image-rpi-2712 \
    linux-headers-rpi-v8 \
    linux-headers-rpi-2712 \
    raspi-firmware \
    firmware-brcm80211

# Install WiFi USB drivers (Debian repository)
echo "[BASE] Installing WiFi USB drivers..."
apt install -y \
    firmware-realtek \
    firmware-ralink \
    firmware-atheros \
    firmware-misc-nonfree \
    firmware-iwlwifi \
    wpasupplicant \
    wireless-tools \
    iw

apt upgrade -y

# System configuration
echo "[BASE] System configuration..."

# Timezone
timedatectl set-timezone Europe/Paris || true

# Locale
locale-gen fr_FR.UTF-8 || true

# Optimized network configuration for virtualization
cat > /etc/sysctl.d/99-network-tuning.conf << 'EOF'
# Network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Enable IP forwarding for containers/VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

# Install first-boot service for partition resize and network configuration
echo "[BASE] Installing first-boot services..."
if [ -f /etc/setupfiles/rpi-first-boot.sh ] && [ -f /etc/setupfiles/rpi-first-boot.service ]; then
    mv /etc/setupfiles/rpi-first-boot.sh /usr/local/bin/rpi-first-boot.sh
    chmod +x /usr/local/bin/rpi-first-boot.sh
    mv /etc/setupfiles/rpi-first-boot.service /etc/systemd/system/rpi-first-boot.service

    systemctl daemon-reload
    systemctl enable rpi-first-boot.service
    echo "  rpi-first-boot installed"
else
    echo "  Warning: rpi-first-boot files not found in setupfiles"
fi

# Install services-first-boot service (will be populated by other services)
echo "Installing services-first-boot service..."
if [ -f /etc/setupfiles/services-first-boot.sh ] && [ -f /etc/setupfiles/services-first-boot.service ]; then
    mv /etc/setupfiles/services-first-boot.sh /usr/local/bin/services-first-boot.sh
    chmod +x /usr/local/bin/services-first-boot.sh
    mv /etc/setupfiles/services-first-boot.service /etc/systemd/system/services-first-boot.service
    systemctl daemon-reload
    systemctl enable services-first-boot.service
    echo "  services-first-boot installed"
else
    echo "  Warning: services-first-boot files not found in setupfiles"
fi

# Install MOTD updater service
echo "Installing MOTD IP updater service..."
if [ -f /etc/setupfiles/update-motd-ip.sh ]; then
    mv /etc/setupfiles/update-motd-ip.sh /usr/local/bin/update-motd-ip.sh
    chmod +x /usr/local/bin/update-motd-ip.sh
    mv /etc/setupfiles/update-motd-ip.service /etc/systemd/system/update-motd-ip.service
    mv /etc/setupfiles/update-motd-ip.path /etc/systemd/system/update-motd-ip.path
    systemctl daemon-reload
    systemctl enable update-motd-ip.service
    systemctl enable update-motd-ip.path
    echo "  MOTD updater installed"
else
    echo "  Warning: update-motd-ip files not found in setupfiles"
fi

# Enable SSH and NetworkManager at boot
echo "[BASE] Enabling SSH and NetworkManager..."
systemctl enable NetworkManager
systemctl enable ssh

echo "====== BASE SERVICE COMPLETE ======"