#!/bin/bash
set -e

# ============================================================================
# Debian rootfs automatic configuration script
# Executed at first boot via cloud-init in QEMU
# ============================================================================

echo "======================================"
echo "Starting rootfs configuration"
echo "======================================"

# System update
echo "[1/5] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install essential packages
echo "[2/5] Installing packages..."
apt-get install -y \
    vim \
    git \
    curl \
    wget \
    htop \
    tmux \
    rsync \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release

# System configuration
echo "[3/5] System configuration..."

# Timezone
timedatectl set-timezone Europe/Paris || true

# Locale
locale-gen fr_FR.UTF-8 || true

# Optimized network configuration
cat > /etc/sysctl.d/99-network-tuning.conf << 'EOF'
# Network optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
EOF

# Cleanup
echo "[4/5] Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# Create flag file to indicate setup is complete
echo "[5/5] Finalizing..."
touch /root/setup-completed
date > /root/setup-completed

echo "======================================"
echo "Configuration completed successfully!"
echo "======================================"

# Automatic VM shutdown to continue the build
echo "Shutting down VM in 5 seconds..."
sleep 5
poweroff