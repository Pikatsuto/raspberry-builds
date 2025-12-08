#!/bin/bash
# Docker service - Install Docker CE

echo "====== DOCKER SERVICE ======"

echo "[DOCKER] Installing Docker..."
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
systemctl stop docker

usermod -aG docker pi
mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf << 'EOF'
[Service]
Environment=DOCKER_MIN_API_VERSION=1.25
EOF

# Enable Docker services at boot
echo "[DOCKER] Enabling Docker services..."
systemctl enable docker
systemctl enable containerd

echo "====== DOCKER SERVICE COMPLETE ======"