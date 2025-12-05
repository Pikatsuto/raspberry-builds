#!/bin/bash
set -e

echo "======================================"
echo "Services First Boot Initialization"
echo "======================================"

# 4. Configure network bridges with NetworkManager
echo "[1/3] Configuring network bridges..."

# Check if eth1 exists
if ip link show eth1 >/dev/null 2>&1; then
    echo "  eth1 detected - creating br-lan for internal LAN"

    # Create br-lan bridge with shared method (auto DHCP + NAT)
    nmcli connection add type bridge ifname br-lan con-name br-lan \
        ipv4.method shared \
        ipv4.addresses 192.168.10.254/24 \
        ipv6.method shared \
        ipv6.addresses fd00:10:10::1/64 \
        bridge.stp no

    # Add eth1 to br-lan
    nmcli connection add type ethernet ifname eth1 con-name br-lan-slave-eth1 \
        master br-lan \
        slave-type bridge

    # Configure NetworkManager's dnsmasq for custom DHCP settings
    echo "  Configuring DHCP server settings..."
    mkdir -p /etc/NetworkManager/dnsmasq-shared.d
    cat > /etc/NetworkManager/dnsmasq-shared.d/br-lan.conf << 'DNSMASQEOF'
# Interface to listen on
interface=br-lan

# Local domain name
domain=lan

# Expand hostnames with domain (host -> host.lan)
expand-hosts

# DHCPv4 configuration
dhcp-range=192.168.10.100,192.168.10.199,12h

# DHCPv6 configuration (Stateful DHCPv6)
enable-ra
dhcp-range=::100,::199,constructor:br-lan,ra-stateless,64,12h

# Upstream DNS servers IPv4: Cloudflare (for external queries)
server=1.1.1.1
server=1.0.0.1

# Upstream DNS servers IPv6: Cloudflare (for external queries)
server=2606:4700:4700::1111
server=2606:4700:4700::1001

# Provide local DNS server (this host) to DHCP clients
dhcp-option=6,192.168.10.254

# Domain name for DHCP clients
dhcp-option=15,lan

# Log DNS queries and DHCP requests
log-queries
log-dhcp
DNSMASQEOF

    # Restart the br-lan connection to apply dnsmasq config
    echo "  Restarting br-lan to apply DHCP configuration..."
    nmcli connection down br-lan 2>/dev/null || true
    sleep 2
    nmcli connection modify "cloud-init eth1" connection.autoconnect no 2>/dev/null || true
    nmcli connection modify "Wired connection 2" connection.autoconnect no 2>/dev/null || true
    nmcli connection modify "br-lan" connection.autoconnect yes
    nmcli connection down "cloud-init eth1" 2>/dev/null || true
    nmcli connection down "Wired connection 2" 2>/dev/null || true
    nmcli connection up br-lan

    echo "  br-lan configured successfully:"
    echo "    IPv4: 192.168.10.254/24"
    echo "    IPv6: fd00:10:10::1/64"
    echo "    DHCPv4: 192.168.10.100-192.168.10.199"
    echo "    DHCPv6: fd00:10:10::100-fd00:10:10::199"
    echo "    Local DNS: 192.168.10.254 (resolves *.lan hostnames)"
    echo "    Upstream DNS: Cloudflare (1.1.1.1, 1.0.0.1)"
    echo "    NAT enabled for both IPv4 and IPv6"
else
    echo "  eth1 not detected - skipping br-lan"
fi

# Create br-wan bridge (always create for WAN connectivity)
echo "  Creating br-wan for WAN connectivity"
nmcli connection add type bridge ifname br-wan con-name br-wan \
    ipv4.method auto \
    ipv6.method auto \
    bridge.stp no

# Add eth0 to br-wan
nmcli connection add type ethernet ifname eth0 con-name br-wan-slave-eth0 \
    master br-wan \
    slave-type bridge

nmcli connection modify "cloud-init eth0" connection.autoconnect no 2>/dev/null || true
nmcli connection modify "Wired connection 1" connection.autoconnect no 2>/dev/null || true
nmcli connection modify "br-wan" connection.autoconnect yes
nmcli connection down "cloud-init eth0" 2>/dev/null || true
nmcli connection down "Wired connection 1" 2>/dev/null || true
nmcli connection up br-wan

# Update MOTD
update-motd-ip.sh

echo "  br-wan bridge configured"

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

# Wait for network bridges to be up (created by rpi-first-boot.sh)
echo "  Waiting for network bridges..."
for i in {1..30}; do
    if ip link show br-wan >/dev/null 2>&1; then
        echo "  br-wan bridge is ready!"
        break
    fi
    echo "  Waiting... ($i/30)"
    sleep 1
done

# Check if br-lan exists (eth1 was detected)
if ip link show br-lan >/dev/null 2>&1; then
    echo "  br-lan detected - configuring dual-bridge setup"

    # Create Incus network for br-lan (default network)
    echo "  Creating Incus network using br-lan bridge..."
    incus network create br-lan \
        --type=bridge \
        parent=br-lan \
        ipv4.address=none \
        ipv6.address=none || echo "  Network already exists"

    # Create Incus network for br-wan (optional network)
    echo "  Creating Incus network using br-wan bridge..."
    incus network create br-wan \
        --type=bridge \
        parent=br-wan \
        ipv4.address=none \
        ipv6.address=none || echo "  Network already exists"

    # Configure default profile to use br-lan
    echo "  Configuring default profile to use br-lan..."
    incus profile device remove default eth0 2>/dev/null || true
    incus profile device add default eth0 nic \
        nictype=bridged \
        parent=br-lan

    echo "  Incus configured: br-lan (default), br-wan (optional)"
else
    echo "  br-lan not found - configuring single-bridge setup with br-wan"

    # Create Incus network for br-wan only
    echo "  Creating Incus network using br-wan bridge..."
    incus network create br-wan \
        --type=bridge \
        parent=br-wan \
        ipv4.address=none \
        ipv6.address=none || echo "  Network already exists"

    # Configure default profile to use br-wan
    echo "  Configuring default profile to use br-wan..."
    incus profile device remove default eth0 2>/dev/null || true
    incus profile device add default eth0 nic \
        nictype=bridged \
        parent=br-wan

    echo "  Incus configured: br-wan (default)"
fi

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