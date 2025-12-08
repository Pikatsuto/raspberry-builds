# HAOS Service First-Boot Initialization
# Downloads and creates Home Assistant OS VM in Incus

echo "[HAOS] Downloading Home Assistant OS..."
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
rm -rf metadata.yaml metadata.tar.gz rootfs.img

# Create HAOS VM with specified configuration
echo "[HAOS] Creating HAOS VM..."
incus init haos-aarch64-16.3 haos --vm

# Configure VM resources
echo "  Configuring VM resources (2 CPUs, 4GB RAM, 24GB disk)..."
incus config set haos limits.cpu=2
incus config set haos limits.memory=4GB
incus config device override haos root size=24GB

# Disable Secure Boot (HAOS doesn't support it)
echo "  Disabling Secure Boot..."
incus config set haos security.secureboot=false

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

echo "[HAOS] HAOS VM created and started successfully!"
echo "  Access Home Assistant at: http://<vm-ip>:8123"