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

# 2. Disable cloud-init networking (netplan will take over)
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

# 4. Initialize Incus
echo "[4/5] Initializing Incus..."

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

mv /root/99-br-wan.yaml /etc/netplan/99-br-wan.yaml
rm -f /etc/netplan/50-cloud-init.yaml 2>/dev/null || true
netplan generate || true

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

# 5. Disable this service for next boots
echo "[5/5] Disabling first-boot service..."
systemctl disable rpi-first-boot.service
rm -f /etc/systemd/system/rpi-first-boot.service
rm -f /usr/local/bin/rpi-first-boot.sh

echo "======================================"
echo "First boot configuration complete!"
echo "Rebooting in 5 seconds..."
echo "======================================"
sleep 5
reboot