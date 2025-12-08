# OpenWRT Service First-Boot Initialization
# Reconfigures br-lan to manual mode (OpenWRT manages DHCP, not NetworkManager)

echo "[OPENWRT] Reconfiguring network for OpenWRT..."

# Reconfigure br-lan from shared to manual if it exists (OpenWRT will manage DHCP)
if nmcli connection show br-lan >/dev/null 2>&1; then
    echo "  Reconfiguring br-lan from shared to manual mode (OpenWRT manages DHCP)"

    nmcli connection modify br-lan \
        ipv4.method manual \
        ipv4.addresses 192.168.10.254/24 \
        ipv6.method manual \
        ipv6.addresses fd00:10:10::ffff/64

    # Restart br-lan to apply changes
    nmcli connection down br-lan 2>/dev/null || true
    nmcli connection up br-lan

    echo "  br-lan reconfigured successfully:"
    echo "    Host IPv4: 192.168.10.254/24 (manual, no DHCP server)"
    echo "    Host IPv6: fd00:10:10::ffff/64 (manual)"
    echo "    DHCP/DNS will be managed by OpenWrt container"
fi

echo "[OPENWRT] Importing OpenWrt 24.10 image..."
incus image copy images:openwrt/24.10 local: --alias openwrt-24.10 2>/dev/null || echo "  Image already exists"

# Create OpenWrt container based on network configuration
if ip link show br-lan >/dev/null 2>&1; then
    echo "  Creating OpenWrt container as router (br-lan + br-wan)..."

    # Create container with custom profile for dual NICs
    incus profile create openwrt-router 2>/dev/null || true
    incus profile device remove openwrt-router root 2>/dev/null || true
    incus profile device remove openwrt-router eth0 2>/dev/null || true
    incus profile device remove openwrt-router eth1 2>/dev/null || true

    # Add root disk device
    incus profile device add openwrt-router root disk \
        path=/ \
        pool=default 2>/dev/null || true

    # eth1 on br-wan (WAN side - DHCP)
    incus profile device add openwrt-router eth0 nic \
        nictype=bridged \
        parent=br-wan \
        name=eth0

    # eth0 on br-lan (LAN side - 192.168.10.1)
    incus profile device add openwrt-router eth1 nic \
        nictype=bridged \
        parent=br-lan \
        name=eth1

    # Create container with router profile
    incus launch openwrt-24.10 openwrt --profile default --profile openwrt-router

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

config interface 'wan'
	option device 'eth0'
	option proto 'dhcp'
	option peerdns '0'
	list dns '192.168.10.254'
	list dns_search 'lan'

config interface 'wan6'
	option device 'eth0'
	option proto 'dhcpv6'
	option reqaddress 'try'
	option reqprefix 'auto'
	option norelease '1'

config interface 'lan'
	option device 'eth1'
	option proto 'static'
	option ipaddr '192.168.10.1'
	option netmask '255.255.255.0'
	option ip6addr 'fd00:10:10::1/64'
	list dns '1.1.1.1'
	list dns '1.0.0.1'
OPENWRT_NETWORK_ROUTER

    # Restart network service in container
    incus exec openwrt -- /etc/init.d/network restart

    echo "  OpenWrt container configured as router:"
    echo "    LAN (eth0 on br-lan): 192.168.10.1/24, fd00:10:10::1/64"
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
    incus exec openwrt -- opkg update
    incus exec openwrt -- opkg install bash

    echo "  OpenWrt container configured as LAN client:"
    echo "    LAN (eth0 on br-wan): DHCP client"
    echo "    Note: br-wan is treated as LAN (no routing needed)"
fi

echo "[OPENWRT] OpenWrt container created successfully!"