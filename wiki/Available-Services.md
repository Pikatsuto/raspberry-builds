# Available Services

Quick reference for service modules. See [Services Guide](Services.md) for creating custom services.

## Service List

### base
**Always included** - RaspiOS kernel, NetworkManager, SSH, network bridges
- Location: `images/debian/services/base/`

### qemu
**Incus virtualization** - Containers and VMs with KVM
- Dependencies: None
- Command: `./bin/autobuild --image debian/qemu`

### docker
**Docker Engine** - Portainer + Watchtower
- Dependencies: None
- Access: `https://raspberry-ip:9443` (Portainer)
- Command: `./bin/autobuild --image debian/docker`

### haos
**Home Assistant OS** - VM with Zigbee auto-detect
- Dependencies: qemu
- Access: `http://raspberry-ip:8123`
- Command: `./bin/autobuild --image debian/qemu+haos`

### openwrt
**OpenWrt router** - Container with advanced routing
- Dependencies: qemu
- Access: `http://192.168.10.1` (LuCI)
- Command: `./bin/autobuild --image debian/qemu+openwrt`

### hotspot
**WiFi access point** - Auto-detects wlan0/wlan1
- Dependencies: None
- SSID: `RaspberryPi-5G` (password: `raspberry`)
- Command: `./bin/autobuild --image debian/hotspot`

## Resource Requirements

| Service | RAM | Disk | Special Hardware |
|---------|-----|------|------------------|
| base | 500MB | 2GB | - |
| qemu | +100MB | +500MB | - |
| docker | +200MB | +1GB | - |
| haos | +4GB | +32GB | Optional: USB Zigbee |
| openwrt | +100MB | +500MB | Optional: Dual NIC |
| hotspot | +50MB | +100MB | WiFi adapter |

## Common Combinations

```bash
# Home server
./bin/autobuild --image debian/docker

# Virtualization platform
./bin/autobuild --image debian/qemu+docker

# Network router + WiFi
./bin/autobuild --image debian/qemu+openwrt+hotspot

# Home automation
./bin/autobuild --image debian/qemu+haos

# Full stack (requires 8GB RAM)
./bin/autobuild --image debian/qemu+docker+openwrt+hotspot+haos
```

## Service Details

For detailed information:
- [Service architecture](Services.md)
- [Creating custom services](Services/#creating-custom-services)
- [Hardware detection](Hardware-Detection.md)
- [Pre-built images](Available-Images.md)