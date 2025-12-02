#!/bin/bash
set -e

echo "======================================"
echo "Services First Boot Initialization"
echo "======================================"

# Wait for internet connectivity
echo "[1/2] Waiting for internet connectivity..."
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

echo "  Incus initialized successfully!"

wget https://github.com/home-assistant/operating-system/releases/download/16.3/haos_generic-aarch64-16.3.qcow2.xz
unxz haos_generic-aarch64-16.3.qcow2.xz
mv haos_generic-aarch64-16.3.qcow2 rootfs.img

cat << EOF > metadata.yaml
architecture: aarch64
creation_date: 1732636800
properties:
  description: Home Assistant OS 16.3 ARM64
  os: haos
  release: "16.3"
EOF

tar -czf metadata.tar.gz metadata.yaml
incus image import metadata.tar.gz rootfs.img --alias haos-aarch64-16.3
rm -rf metadata.yaml metadata.tar.gz haos_generic-aarch64-16.3.qcow2

# Create HAOS VM with specified configuration
echo "  Creating HAOS VM..."
incus init haos-aarch64-16.3 haos --vm

# Configure VM resources
echo "  Configuring VM resources (2 CPUs, 4GB RAM, 24GB disk)..."
incus config set haos limits.cpu=2
incus config set haos limits.memory=4GB
incus config device override haos root size=24GB

# Disable Secure Boot (HAOS doesn't support it)
echo "  Disabling Secure Boot..."
incus config set haos security.secureboot=false

# Note: eth0 is already on br-wan via the default profile

# Enable auto-start on boot
echo "  Enabling auto-start on boot..."
incus config set haos boot.autostart=true

# Detect and passthrough Zigbee dongle
echo "  Detecting Zigbee dongle..."
ZIGBEE_DEVICE=""

# Check for common Zigbee USB dongles
for device in /dev/ttyUSB* /dev/ttyACM*; do
    if [ -e "$device" ]; then
        # Check if it's a known Zigbee coordinator device
        # Look for common vendor IDs (Conbee, TI CC2652, Silicon Labs, etc.)
        DEVICE_INFO=$(udevadm info -q property -n "$device" 2>/dev/null || true)

        if echo "$DEVICE_INFO" | grep -qiE "(FTDI|Silicon_Labs|Texas_Instruments|dresden_elektronik|ITead|Sonoff)"; then
            ZIGBEE_DEVICE="$device"
            echo "  Found Zigbee dongle: $ZIGBEE_DEVICE"

            # Get USB device path for Incus passthrough
            USB_BUS=$(echo "$DEVICE_INFO" | grep -oP 'ID_PATH=.*usb-\K[^:]+' | head -1)
            USB_VENDOR=$(echo "$DEVICE_INFO" | grep -oP 'ID_VENDOR_ID=\K.*' | head -1)
            USB_PRODUCT=$(echo "$DEVICE_INFO" | grep -oP 'ID_MODEL_ID=\K.*' | head -1)

            if [ -n "$USB_VENDOR" ] && [ -n "$USB_PRODUCT" ]; then
                echo "  USB Vendor ID: $USB_VENDOR"
                echo "  USB Product ID: $USB_PRODUCT"

                # Add USB device passthrough to VM
                echo "  Adding USB passthrough to HAOS VM..."
                incus config device add haos zigbee-dongle usb \
                    vendorid="$USB_VENDOR" \
                    productid="$USB_PRODUCT" \
                    required=false 2>/dev/null || echo "  USB device already added or not available"
            fi
            break
        fi
    fi
done

if [ -z "$ZIGBEE_DEVICE" ]; then
    echo "  No Zigbee dongle detected (you can add it manually later)"
fi

# Start the HAOS VM
echo "  Starting HAOS VM..."
incus start haos

echo "  HAOS VM created and started successfully!"
echo "  Access Home Assistant at: http://<vm-ip>:8123"

# Disable this service for next boots
echo "Disabling services-first-boot service..."
systemctl disable services-first-boot.service
rm -f /etc/systemd/system/services-first-boot.service
rm -f /usr/local/bin/services-first-boot.sh

echo "======================================"
echo "Services initialization complete!"
echo "======================================"