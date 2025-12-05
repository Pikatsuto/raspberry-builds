#!/bin/bash
set -e

echo "======================================"
echo "Services First Boot Initialization"
echo "======================================"

# Wait for internet connectivity
echo "[1/3] Waiting for internet connectivity..."
MAX_WAIT=300  # 5 minutes maximum
WAIT_TIME=0
INTERVAL=5

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Try to ping Google DNS and Cloudflare DNS
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        echo "  Internet connectivity established!"
        break
    fi
    echo "  Waiting for internet... ($WAIT_TIME/$MAX_WAIT seconds)"
    sleep $INTERVAL
    WAIT_TIME=$((WAIT_TIME + INTERVAL))
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "  ERROR: Internet connectivity timeout after $MAX_WAIT seconds"
    echo "  Services initialization skipped - you can run this manually later"
    exit 1
fi

# Initialize Incus
echo "[2/3] Initializing Incus..."

# Wait for Incus to be ready (max 30 seconds)
echo "  Waiting for Incus to be ready..."
for i in {1..30}; do
    if incus info >/dev/null 2>&1; then
        echo "  Incus is ready!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 1
done

# Initialize Incus with minimal config
incus admin init --minimal
incus config set core.https_address :8443

# Apply netplan configuration and create br-wan bridge
netplan apply || true

# Create Incus bridge network using the system br-wan bridge (passthrough mode)
echo "  Creating Incus network using br-wan bridge..."
incus network create br-wan \
    --type=bridge \
    parent=br-wan \
    ipv4.address=none \
    ipv6.address=none || echo "  Network already exists"

# Attach the bridge to the default profile
incus profile device add default eth0 nic \
    nictype=bridged \
    parent=br-wan 2>/dev/null || echo "  Device already attached"

echo "  Incus initialized successfully!"

# Initialize Docker containers
echo "[3/3] Initializing Docker containers..."

# Create Portainer
echo "  Creating Portainer container..."
docker volume create portainer_data
docker run -d \
    -p 8000:8000 -p 9443:9443 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    -l hidden=true \
    portainer/portainer-ce:lts

# Create Watchtower
echo "  Creating Watchtower container..."
docker run -d \
    --name watchtower \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -l hidden=true \
    -e WATCHTOWER_SCHEDULE="0 0 4 * * *" \
    --restart always \
    containrrr/watchtower

echo "  Docker containers initialized successfully!"

# Disable this service for next boots
echo "Disabling services-first-boot service..."
systemctl disable services-first-boot.service
rm -f /etc/systemd/system/services-first-boot.service
rm -f /usr/local/bin/services-first-boot.sh

echo "======================================"
echo "Services initialization complete!"
echo "======================================"