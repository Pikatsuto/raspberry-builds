# Hardware Auto-Detection

The build system automatically detects and configures hardware on first boot.

## Supported Hardware

### Network Interfaces

**Ethernet (eth0, eth1)**

**Detection**:
- Scans for eth0 and eth1 during first boot
- Executed by: `services/base/first-boot/init.sh`

**Configuration**:

| Configuration | Bridge Setup | IP Assignment |
|---------------|--------------|---------------|
| Single NIC (eth0 only) | br-wan on eth0 | DHCP client |
| Dual NIC (eth0 + eth1) | br-wan on eth0<br>br-lan on eth1 | br-wan: DHCP client<br>br-lan: 192.168.10.254/24 |

**br-lan features** (when created):
- DHCP server (192.168.10.1-100)
- DNS forwarder (dnsmasq)
- NAT to br-wan
- Gateway for internal services

**Example detection log**:
```bash
# Check first-boot logs
sudo journalctl -u services-first-boot | grep "Network"

# Output:
# Detected eth0 and eth1
# Created br-wan on eth0 (WAN)
# Created br-lan on eth1 (LAN)
# DHCP server enabled on br-lan
```

---

### WiFi Adapters

**Wireless interfaces (wlan0, wlan1)**

**Detection**:
- Scans for wlan0 and wlan1 during first boot
- Executed by: `services/hotspot/first-boot/init.sh`

**Configuration**:

| Configuration | Access Point Setup |
|---------------|-------------------|
| No WiFi | Hotspot service disabled |
| Single WiFi (wlan0) | 5GHz AP on wlan0 |
| Dual WiFi (wlan0 + wlan1) | 2.4GHz AP on wlan0<br>5GHz AP on wlan1 |

**Access Point defaults**:
- SSID: `RaspberryPi-5G` or `RaspberryPi-2.4G`
- Password: `raspberry`
- Bridge: br-lan (if exists) or br-wan

**Bridge selection logic**:
```bash
if br-lan exists:
    attach WiFi AP to br-lan (LAN network)
else:
    attach WiFi AP to br-wan (WAN network)
```

**Example detection log**:
```bash
sudo journalctl -u services-first-boot | grep "WiFi"

# Output:
# Detected wlan0 and wlan1
# Configured 2.4GHz AP on wlan0 (RaspberryPi-2.4G)
# Configured 5GHz AP on wlan1 (RaspberryPi-5G)
# Attached to br-lan
```

**Customization**:
Edit `/etc/setupfiles/hostapd-5ghz.conf` or `hostapd-2.4ghz.conf`:
```ini
ssid=MyCustomSSID
wpa_passphrase=MySecurePassword
```

Then restart:
```bash
sudo systemctl restart hostapd-5ghz
```

---

### USB Zigbee Coordinators

**USB serial devices for Zigbee/Z-Wave**

**Detection**:
- Scans `/dev/ttyUSB*` and `/dev/ttyACM*`
- Matches vendor IDs for known Zigbee coordinators
- Executed by: `services/haos/first-boot/init.sh`

**Supported vendors**:
- dresden elektronik (ConBee/ConBee II)
- Texas Instruments (CC2652, CC1352)
- Silicon Labs (EFR32)
- ITead (Sonoff Zigbee dongles)
- FTDI-based coordinators

**Configuration**:
- USB device passed through to Home Assistant VM
- Uses vendor/product ID matching (survives USB port changes)
- Non-required passthrough (VM starts even if dongle unplugged)

**Example detection log**:
```bash
sudo journalctl -u services-first-boot | grep -i zigbee

# Output:
# Detected Zigbee coordinator: ConBee II
# USB Vendor: 1cf1, Product: 0030
# Passed through to Home Assistant VM (haos)
```

**Manual passthrough**:
```bash
# List USB devices
lsusb

# Pass through manually
incus config device add haos my-zigbee usb \
    vendorid=1cf1 \
    productid=0030
```

**Verification**:
```bash
# Check HAOS VM devices
incus config show haos

# Should show:
# devices:
#   zigbee-dongle:
#     productid: "0030"
#     type: usb
#     vendorid: 1cf1
```

---

## Detection Sequence

### First Boot Timeline

**1. rpi-first-boot.service** (runs once, before network)
- Expand root partition to fill SD card
- Set persistent network interface names (eth0, eth1, wlan0, wlan1)
- Reboot

**2. After reboot: services-first-boot.service** (runs once)

**Stage 1: Base network setup** (`base/first-boot/init.sh`)
- Detect eth0, eth1
- Create br-wan (always)
- Create br-lan (if eth1 exists)
- Configure DHCP server on br-lan
- Enable NAT

**Stage 2: Service initialization** (service-specific init.sh)
- qemu: Configure Incus networks
- docker: Start Portainer, Watchtower
- haos: Download HAOS image, create VM, detect Zigbee dongles
- openwrt: Download OpenWrt image, create container
- hotspot: Detect WiFi adapters, configure hostapd

**3. Normal boot**
- All services running
- Hardware configured
- Ready for use

**Total first-boot time**: 3-10 minutes (depends on services, network speed)

---

## Manual Hardware Configuration

### Add Network Bridge Manually

```bash
# Create bridge
sudo nmcli con add type bridge con-name br-custom ifname br-custom

# Add interface to bridge
sudo nmcli con add type bridge-slave con-name eth2 ifname eth2 master br-custom

# Set IP
sudo nmcli con mod br-custom ipv4.addresses 192.168.20.1/24
sudo nmcli con mod br-custom ipv4.method manual

# Bring up
sudo nmcli con up br-custom
```

### Add WiFi AP Manually

```bash
# Create hostapd config
sudo tee /etc/hostapd/hostapd-custom.conf <<EOF
interface=wlan2
driver=nl80211
ssid=MyCustomAP
hw_mode=a
channel=36
ieee80211n=1
ieee80211ac=1
wmm_enabled=1
wpa=2
wpa_passphrase=MyPassword
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

# Create systemd service
sudo tee /etc/systemd/system/hostapd-custom.service <<EOF
[Unit]
Description=Custom WiFi AP
After=network.target

[Service]
ExecStart=/usr/sbin/hostapd /etc/hostapd/hostapd-custom.conf

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl enable hostapd-custom
sudo systemctl start hostapd-custom
```

### Pass USB Device to VM Manually

```bash
# List USB devices
lsusb
# Example output: Bus 001 Device 003: ID 10c4:ea60 Silicon Labs CP210x

# Pass through
incus config device add haos my-device usb \
    vendorid=10c4 \
    productid=ea60
```

---

## Hardware Detection Logs

### View Detection Logs

**First-boot service**:
```bash
sudo journalctl -u services-first-boot
```

**Specific hardware type**:
```bash
# Network detection
sudo journalctl -u services-first-boot | grep -i "network\|eth\|bridge"

# WiFi detection
sudo journalctl -u services-first-boot | grep -i "wifi\|wlan\|hostapd"

# USB detection
sudo journalctl -u services-first-boot | grep -i "usb\|zigbee\|dongle"
```

**All hardware events**:
```bash
sudo journalctl -u services-first-boot --no-pager
```

---

## Disabling Auto-Detection

### Disable Network Bridge Auto-Creation

Edit `/etc/setupfiles/rpi-first-boot.sh`:

```bash
# Comment out bridge creation
# create_bridges
```

Then delete and recreate first-boot service to apply changes (before first boot).

### Disable WiFi Hotspot

```bash
# Disable hostapd services
sudo systemctl disable hostapd-5ghz
sudo systemctl disable hostapd-2.4ghz
sudo systemctl stop hostapd-5ghz
sudo systemctl stop hostapd-2.4ghz
```

### Disable USB Passthrough

Edit `services/haos/first-boot/init.sh` and comment out the USB detection section before building.

---

## Future Hardware Detection

**Planned** (in development):
- Storage devices (auto-mount USB drives)
- Audio devices (auto-configure ALSA/PulseAudio)
- Camera modules (CSI/USB cameras)
- GPIO devices (I2C, SPI peripherals)

**Contributions welcome!** See [CONTRIBUTING.md](../CONTRIBUTING.md).

---

## Next Steps

- [Learn about creating custom services](Services.md)
- [Troubleshoot hardware issues](Troubleshooting.md)
- [Configure GitHub Actions CI/CD](GitHub-Actions.md)