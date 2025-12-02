#!/bin/bash
set -e

echo "======================================"
echo "Raspberry Pi First Boot Configuration"
echo "======================================"

# 1. Enable classic network names (eth0, wlan0)
echo "[1/4] Enabling classic network interface names..."
if [ -f /boot/firmware/cmdline.txt ]; then
    if ! grep -q "net.ifnames=0" /boot/firmware/cmdline.txt; then
        sed -i 's/$/ net.ifnames=0 biosdevname=0/' /boot/firmware/cmdline.txt
        echo "  Added net.ifnames=0 to cmdline.txt"
    else
        echo "  Already configured"
    fi
fi

# 2. Disable cloud-init networking (NetworkManager will take over)
echo "[2/4] Disabling cloud-init networking..."
mkdir -p /etc/cloud/cloud.cfg.d/
cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg << 'CLOUDEOF'
network: {config: disabled}
CLOUDEOF
echo "  Cloud-init networking disabled"

# 3. Resize root partition to use all available space
echo "[3/4] Resizing root partition..."

# Detect root device and partition
ROOT_PART=$(findmnt -n -o SOURCE /)
ROOT_DEV=$(lsblk -no pkname "$ROOT_PART")
PART_NUM=$(echo "$ROOT_PART" | grep -o '[0-9]*$')

echo "  Root partition: $ROOT_PART"
echo "  Root device: /dev/$ROOT_DEV"
echo "  Partition number: $PART_NUM"

# Expand partition to use all available space
echo "  Expanding partition..."
parted /dev/$ROOT_DEV ---pretend-input-tty <<PARTED
resizepart
$PART_NUM
Yes
100%
PARTED

# Resize filesystem
echo "  Resizing filesystem..."
resize2fs "$ROOT_PART"

echo "  Partition resized successfully!"

# 4. Configure network bridges with NetworkManager
echo "[4/4] Configuring network bridges..."

# Delete cloud-init default connections if they exist
nmcli connection delete "cloud-init eth0" 2>/dev/null || true
nmcli connection delete "cloud-init eth1" 2>/dev/null || true
nmcli connection delete "Wired connection 1" 2>/dev/null || true
nmcli connection delete "Wired connection 2" 2>/dev/null || true

# Check if eth1 exists
if ip link show eth1 >/dev/null 2>&1; then
    echo "  eth1 detected - creating br-lan for internal LAN"

    # Create br-lan bridge with static IP
    nmcli connection add type bridge ifname br-lan con-name br-lan \
        ipv4.method manual \
        ipv4.addresses 192.168.10.254/24 \
        ipv6.method disabled \
        bridge.stp no

    # Add eth1 to br-lan
    nmcli connection add type ethernet ifname eth1 con-name br-lan-slave-eth1 \
        master br-lan \
        slave-type bridge

    # Deploy dnsmasq configuration for br-lan
    if [ -f /root/setupfiles/dnsmasq-br-lan.conf ]; then
        cp /root/setupfiles/dnsmasq-br-lan.conf /etc/dnsmasq.d/br-lan.conf
        # Stop default dnsmasq if running
        systemctl stop dnsmasq 2>/dev/null || true
        systemctl disable dnsmasq 2>/dev/null || true
        # Enable and start dnsmasq
        systemctl enable dnsmasq
        systemctl start dnsmasq
        echo "  br-lan DHCP server configured (192.168.10.100-199)"
    fi

    # Configure NAT masquerade for Internet access from br-lan to br-wan
    echo "  Configuring NAT masquerade (br-lan → br-wan)..."

    # Enable IP forwarding (already in sysctl but ensure it's active now)
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Add iptables rules for NAT
    iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o br-wan -j MASQUERADE
    iptables -A FORWARD -i br-lan -o br-wan -j ACCEPT
    iptables -A FORWARD -i br-wan -o br-lan -m state --state RELATED,ESTABLISHED -j ACCEPT

    # Save iptables rules for persistence
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4

    # Create systemd service to restore iptables on boot
    cat > /etc/systemd/system/iptables-restore.service << 'IPTABLESEOF'
[Unit]
Description=Restore iptables rules
After=NetworkManager.service
Before=incus.service

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
IPTABLESEOF

    systemctl daemon-reload
    systemctl enable iptables-restore.service

    echo "  NAT masquerade configured for Internet access"

    echo "  br-lan configured with IP 192.168.10.254"
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

echo "  br-wan bridge configured"

# Disable this service for next boots
echo "Disabling first-boot service..."
systemctl disable rpi-first-boot.service
rm -f /etc/systemd/system/rpi-first-boot.service
rm -f /usr/local/bin/rpi-first-boot.sh

echo "======================================"
echo "First boot configuration complete!"
echo "Rebooting in 5 seconds..."
echo "======================================"
sleep 5
reboot