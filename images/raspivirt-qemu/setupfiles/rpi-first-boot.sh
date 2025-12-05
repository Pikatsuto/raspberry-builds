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
echo "[2/2] Disabling cloud-init networking..."
mkdir -p /etc/cloud/cloud.cfg.d/
cat > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg << 'CLOUDEOF'
network: {config: disabled}
CLOUDEOF
echo "  Cloud-init networking disabled"

# 3. Resize root partition to use all available space
echo "[3/3] Resizing root partition..."

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

# Disable this service for next boots
echo "Disabling first-boot service..."
systemctl disable rpi-first-boot.service
rm -f /etc/systemd/system/rpi-first-boot.service
rm -f /usr/local/bin/rpi-first-boot.sh
systemctl enable services-first-boot.service

echo "======================================"
echo "First boot configuration complete!"
echo "Rebooting in 5 seconds..."
echo "======================================"
sleep 5
reboot