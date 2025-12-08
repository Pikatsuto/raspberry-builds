#!/bin/bash
# QEMU service - Install QEMU/KVM + Incus for container/VM hosting

echo "====== QEMU SERVICE ======"

# Install KVM for hardware virtualization (without GUI dependencies)
echo "[QEMU] Installing KVM..."
apt install -y --no-install-recommends \
    qemu-system-aarch64 \
    qemu-kvm \
    qemu-utils \
    qemu-efi-aarch64
usermod -aG kvm pi

# Add Incus repository (Zabbly - official Incus repository)
echo "[QEMU] Adding Incus repository..."
curl -fsSL https://pkgs.zabbly.com/key.asc | gpg --show-keys --fingerprint
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc
sh -c 'cat <<EOF > /etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc

EOF'

# Install Incus and Incus UI (includes LXC fork)
echo "[QEMU] Installing Incus and Incus UI..."
apt update
apt install -y --no-install-recommends \
    incus \
    incus-ui-canonical

usermod -aG incus pi
usermod -aG incus-admin pi
mkdir -p /etc/systemd/system/incus.service.d
cat > /etc/systemd/system/incus.service.d/override.conf << 'EOF'
[Unit]
Requires=incus-lxcfs.service incus.socket
EOF

# Enable Incus services at boot
echo "[QEMU] Enabling Incus services..."
systemctl enable incus
systemctl enable incus-startup || true

echo "====== QEMU SERVICE COMPLETE ======"