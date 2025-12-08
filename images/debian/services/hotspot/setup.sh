#!/bin/bash
# Hotspot service - Install WiFi hotspot (hostapd)

echo "====== HOTSPOT SERVICE ======"

echo "[HOTSPOT] Installing hostapd..."
apt install -y hostapd

# Install hostapd configuration files (will be configured at first boot)
echo "[HOTSPOT] Installing hostapd configuration files..."
if [ -f /etc/setupfiles/hostapd-5ghz.conf ]; then
    mkdir -p /etc/hostapd
    mv /etc/setupfiles/hostapd-5ghz.conf /etc/hostapd/hostapd-5ghz.conf
    mv /etc/setupfiles/hostapd-2.4ghz.conf /etc/hostapd/hostapd-2.4ghz.conf
    mv /etc/setupfiles/hostapd-5ghz.service /etc/systemd/system/hostapd-5ghz.service
    mv /etc/setupfiles/hostapd-2.4ghz.service /etc/systemd/system/hostapd-2.4ghz.service
    systemctl daemon-reload
    echo "  Hostapd configuration files installed (will be configured at first boot)"
else
    echo "  Warning: hostapd files not found in setupfiles"
fi

echo "====== HOTSPOT SERVICE COMPLETE ======"