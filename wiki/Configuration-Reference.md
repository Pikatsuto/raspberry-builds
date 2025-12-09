# Configuration Reference

Quick reference for configuration files.

## config.sh

Image configuration file.

**Location**: `images/<name>/config.sh`

**Required**:
```bash
OUTPUT_IMAGE="image-name.img"
IMAGE_SIZE="8G"
QEMU_RAM="4G"
QEMU_CPUS="4"
CLOUD=true  # or false
IMAGE_URL="https://..."
SERVICES="base service1 service2"
```

**Optional**:
```bash
DESCRIPTION="Image description"
RASPIOS_URL="https://..."
QEMU_TIMEOUT=1800
```

## Service Files

See [Services - Creating Custom Services](Services/#creating-custom-services) for detailed templates and best practices.

**Quick reference**:
- `setup.sh`: Runs in QEMU, installs packages
- `first-boot/init.sh`: Runs on first boot, detects hardware
- `depends.sh`: Declares service dependencies
- `motd.sh`: MOTD banner content

## Network Configuration (on Raspberry Pi)

### Static IP
```bash
sudo nmcli con mod br-wan ipv4.addresses "192.168.1.100/24"
sudo nmcli con mod br-wan ipv4.gateway "192.168.1.1"
sudo nmcli con mod br-wan ipv4.dns "8.8.8.8"
sudo nmcli con mod br-wan ipv4.method manual
sudo nmcli con up br-wan
```

### WiFi Hotspot

See [Hardware Detection - WiFi Adapters](Hardware-Detection/#wifi-adapters) for detailed configuration.

**Quick edit**: `/etc/hostapd/hostapd-5ghz.conf` (SSID, password), then `sudo systemctl restart hostapd-5ghz`

## APT Configuration

See [Architecture - APT Repository Management](Architecture/#apt-repository-management) for full details on repository configuration and update behavior.

**Files**: `/etc/apt/sources.list.d/raspi.sources` and `/etc/apt/preferences.d/raspi-pin`

For detailed explanations see:
- [Build System](Build-System.md)
- [Services](Services.md)
- [Architecture](Architecture.md)