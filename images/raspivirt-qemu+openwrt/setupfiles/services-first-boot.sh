#!/bin/bash
set -e

echo "======================================"
echo "Services First Boot Initialization"
echo "======================================"

# 4. Configure network bridges with NetworkManager
echo "[1/2] Configuring network bridges..."

# Check if eth1 exists
if ip link show eth1 >/dev/null 2>&1; then
    echo "  eth1 detected - creating br-lan for internal LAN"

    # Create br-lan bridge with manual method (OpenWrt will manage DHCP)
    nmcli connection add type bridge ifname br-lan con-name br-lan \
        ipv4.method manual \
        ipv4.addresses 192.168.10.254/24 \
        ipv6.method manual \
        ipv6.addresses fd00:10:10::1/64 \
        bridge.stp no

    # Add eth1 to br-lan
    nmcli connection add type ethernet ifname eth1 con-name br-lan-slave-eth1 \
        master br-lan \
        slave-type bridge

    # br-lan will be managed by OpenWrt container (no NetworkManager DHCP)
    echo "  br-lan will be managed by OpenWrt container"

    # Restart br-lan connection
    nmcli connection modify "cloud-init eth1" connection.autoconnect no 2>/dev/null || true
    nmcli connection modify "Wired connection 2" connection.autoconnect no 2>/dev/null || true
    nmcli connection modify "br-lan" connection.autoconnect yes
    nmcli connection down "cloud-init eth1" 2>/dev/null || true
    nmcli connection down "Wired connection 2" 2>/dev/null || true
    nmcli connection up br-lan

    echo "  br-lan configured successfully:"
    echo "    Host IPv4: 192.168.10.254/24"
    echo "    Host IPv6: fd00:10:10::1/64"
    echo "    DHCP/DNS will be managed by OpenWrt container"
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
echo "[2/2] Initializing Incus..."

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

# Import OpenWrt image
echo "  Importing OpenWrt 24.10 image..."
incus image copy images:openwrt/24.10 local: --alias openwrt-24.10 2>/dev/null || echo "  Image already exists"

# Create OpenWrt container based on network configuration
if ip link show br-lan >/dev/null 2>&1; then
    echo "  Creating OpenWrt container as router (br-lan + br-wan)..."

    # Create container with custom profile for dual NICs
    incus profile create openwrt-router 2>/dev/null || true
    incus profile device remove openwrt-router eth0 2>/dev/null || true
    incus profile device remove openwrt-router eth1 2>/dev/null || true

    # eth0 on br-lan (LAN side - 192.168.10.1)
    incus profile device add openwrt-router eth0 nic \
        nictype=bridged \
        parent=br-lan \
        name=eth0

    # eth1 on br-wan (WAN side - DHCP)
    incus profile device add openwrt-router eth1 nic \
        nictype=bridged \
        parent=br-wan \
        name=eth1

    # Create container with router profile
    incus launch openwrt-24.10 openwrt --profile openwrt-router

    echo "  Waiting for OpenWrt container to start..."
    sleep 10

    # Configure OpenWrt network (LAN on eth0, WAN on eth1)
    # /etc/config/network configuration for ROUTER mode (br-lan exists)
    # eth0 = br-lan (LAN - 192.168.10.1/24, DHCP server)
    # eth1 = br-wan (WAN - DHCP client)
    cat << 'OPENWRT_NETWORK_ROUTER' | incus file push - openwrt/etc/config/network
config interface 'loopback'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'
	option device 'lo'

config interface 'lan'
	option device 'eth0'
	option proto 'static'
	option ipaddr '192.168.10.1'
	option netmask '255.255.255.0'
	list dns '1.1.1.1'
	list dns '1.0.0.1'

config interface 'wan'
	option device 'eth1'
	option proto 'dhcp'
	option peerdns '0'
	list dns '192.168.10.254'
	list dns_search 'lan'

config interface 'wan6'
	option device 'eth1'
	option proto 'dhcpv6'
	option reqaddress 'try'
	option reqprefix 'auto'
	option norelease '1'
OPENWRT_NETWORK_ROUTER

    # Restart network service in container
    incus exec openwrt -- /etc/init.d/network restart

    echo "  OpenWrt container configured as router:"
    echo "    LAN (eth0 on br-lan): 192.168.10.1/24"
    echo "    WAN (eth1 on br-wan): DHCP client"
    echo "    Web UI: http://192.168.10.1"
else
    echo "  Creating OpenWrt container as LAN client (br-wan only)..."

    # Create container on br-wan (uses default profile with br-wan)
    incus launch openwrt-24.10 openwrt

    echo "  Waiting for OpenWrt container to start..."
    sleep 10

    # Configure OpenWrt network (single interface on br-wan as LAN client)
    # /etc/config/network configuration for CLIENT mode (no br-lan)
    # eth0 = br-wan (DHCP client, considered as LAN since no routing needed)
    cat << 'OPENWRT_NETWORK_CLIENT' | incus file push - openwrt/etc/config/network
config interface 'loopback'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'
	option device 'lo'

config interface 'lan'
	option device 'eth0'
	option proto 'dhcp'
	option peerdns '0'
	list dns '1.1.1.1'
	list dns '1.0.0.1'
	list dns_search 'lan'

config interface 'lan6'
	option device 'eth0'
	option proto 'dhcpv6'
	option reqaddress 'try'
	option reqprefix 'auto'
	option norelease '1'
OPENWRT_NETWORK_CLIENT

    # Restart network service in container
    incus exec openwrt -- /etc/init.d/network restart

    echo "  OpenWrt container configured as LAN client:"
    echo "    LAN (eth0 on br-wan): DHCP client"
    echo "    Note: br-wan is treated as LAN (no routing needed)"
fi

echo "  OpenWrt container created successfully!"
echo "  Incus initialized successfully!"

# Disable this service for next boots
echo "Disabling services-first-boot service..."
systemctl disable services-first-boot.service
rm -f /etc/systemd/system/services-first-boot.service
rm -f /usr/local/bin/services-first-boot.sh

echo "======================================"
echo "Services initialization complete!"
echo "======================================"