# Hotspot Service First-Boot Initialization
# Configures WiFi Access Point with interface detection

echo "[HOTSPOT] Configuring WiFi Access Point..."

# Detect WiFi interfaces
WLAN0_EXISTS=false
WLAN1_EXISTS=false

if ip link show wlan0 >/dev/null 2>&1; then
    WLAN0_EXISTS=true
fi

if ip link show wlan1 >/dev/null 2>&1; then
    WLAN1_EXISTS=true
fi

# Determine which bridge to use for WiFi
if ip link show br-lan >/dev/null 2>&1; then
    WIFI_BRIDGE="br-lan"
    echo "  br-lan detected - WiFi will use br-lan"
else
    WIFI_BRIDGE="br-wan"
    echo "  br-lan not found - WiFi will use br-wan"
fi

# Configure hostapd based on available interfaces
if [[ "$WLAN0_EXISTS" == true && "$WLAN1_EXISTS" == true ]]; then
    echo "  wlan0 and wlan1 detected - dual-band configuration"
    echo "    wlan0: 2.4GHz"
    echo "    wlan1: 5GHz"

    # Disable NetworkManager management of both interfaces
    nmcli device set wlan0 managed no 2>/dev/null || true
    nmcli device set wlan1 managed no 2>/dev/null || true

    # Configure 2.4GHz on wlan0
    if [ -f /etc/hostapd/hostapd-2.4ghz.conf ]; then
        sed -i "s/^interface=.*/interface=wlan0/" /etc/hostapd/hostapd-2.4ghz.conf
        if grep -q "^bridge=" /etc/hostapd/hostapd-2.4ghz.conf; then
            sed -i "s/^bridge=.*/bridge=${WIFI_BRIDGE}/" /etc/hostapd/hostapd-2.4ghz.conf
        else
            sed -i "/^interface=wlan0/a bridge=${WIFI_BRIDGE}" /etc/hostapd/hostapd-2.4ghz.conf
        fi
        echo "  Updated hostapd-2.4ghz.conf: wlan0 → ${WIFI_BRIDGE}"
    fi

    # Configure 5GHz on wlan1
    if [ -f /etc/hostapd/hostapd-5ghz.conf ]; then
        sed -i "s/^interface=.*/interface=wlan1/" /etc/hostapd/hostapd-5ghz.conf
        sed -i "s/^bridge=.*/bridge=${WIFI_BRIDGE}/" /etc/hostapd/hostapd-5ghz.conf
        echo "  Updated hostapd-5ghz.conf: wlan1 → ${WIFI_BRIDGE}"
    fi

    # Enable and start both services
    systemctl enable --now hostapd-2.4ghz.service 2>/dev/null || echo "  Warning: Failed to start hostapd-2.4ghz"
    systemctl enable --now hostapd-5ghz.service 2>/dev/null || echo "  Warning: Failed to start hostapd-5ghz"

    echo "  WiFi Access Point configured:"
    echo "    Bridge: ${WIFI_BRIDGE}"
    echo "    2.4GHz: enabled on wlan0"
    echo "    5GHz: enabled on wlan1"

elif [ "$WLAN0_EXISTS" == true ]; then
    echo "  wlan0 detected (single interface) - 5GHz configuration"

    # Disable NetworkManager management of wlan0
    nmcli device set wlan0 managed no 2>/dev/null || true

    # Configure 5GHz on wlan0
    if [ -f /etc/hostapd/hostapd-5ghz.conf ]; then
        sed -i "s/^interface=.*/interface=wlan0/" /etc/hostapd/hostapd-5ghz.conf
        sed -i "s/^bridge=.*/bridge=${WIFI_BRIDGE}/" /etc/hostapd/hostapd-5ghz.conf
        echo "  Updated hostapd-5ghz.conf: wlan0 → ${WIFI_BRIDGE}"
    fi

    # Enable and start 5GHz service only
    systemctl enable --now hostapd-5ghz.service 2>/dev/null || echo "  Warning: Failed to start hostapd-5ghz"
    systemctl disable hostapd-2.4ghz.service 2>/dev/null || true

    echo "  WiFi Access Point configured:"
    echo "    Bridge: ${WIFI_BRIDGE}"
    echo "    5GHz: enabled on wlan0"
    echo "    2.4GHz: disabled (no wlan1)"

else
    echo "  No WiFi interface detected - skipping WiFi AP configuration"
fi

echo "[HOTSPOT] WiFi Access Point configuration complete!"