#!/bin/bash
set -e

# ============================================================================
# Debian rootfs automatic configuration script for RaspiVirt-Incus
# Executed at first boot via cloud-init in QEMU
# ============================================================================

echo "======================================"
echo "Starting rootfs configuration"
echo "======================================"

# System update
echo "[1/8] Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install essential packages
echo "[2/8] Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    sudo \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release \
    bridge-utils \
    net-tools \
    iptables

# Install KVM for hardware virtualization
echo "[3/8] Installing KVM..."
apt-get install -y \
    qemu-system-aarch64 \
    qemu-kvm \
    qemu-utils \
    qemu-efi-aarch64

# Add Incus repository (Zabbly - official Incus repository)
echo "[4/8] Adding Incus repository..."
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.zabbly.com/key.asc | gpg --dearmor -o /etc/apt/keyrings/zabbly.gpg
cat > /etc/apt/sources.list.d/zabbly-incus-stable.list << 'EOF'
deb [signed-by=/etc/apt/keyrings/zabbly.gpg] https://pkgs.zabbly.com/incus/stable $(lsb_release -sc) main
EOF

# Install Incus and Incus UI (includes LXC fork)
echo "[5/8] Installing Incus and Incus UI..."
apt-get update
apt-get install -y \
    incus \
    incus-ui-canonical

# Configure bridge network br-wan
echo "[6/8] Configuring bridge network br-wan..."
# Create netplan configuration for br-wan
cat > /etc/netplan/99-br-wan.yaml << 'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
  bridges:
    br-wan:
      dhcp4: true
      dhcp6: true
      interfaces:
        - eth0
      parameters:
        stp: false
        forward-delay: 0
EOF

# System configuration
echo "[7/8] System configuration..."

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

# Enable required services at boot
echo "[8/8] Enabling services at boot..."
systemctl enable incus
systemctl enable incus-startup || true
systemctl enable ssh

# Cleanup
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# Create flag file to indicate setup is complete
echo "Finalizing..."
touch /root/setup-completed
date > /root/setup-completed

echo "======================================"
echo "Configuration completed successfully!"
echo "======================================"

# Automatic VM shutdown to continue the build
echo "Shutting down VM in 5 seconds..."
sleep 5
poweroff