# Available Images

Pre-configured images available for download and their use cases.

## Official Images

All images available in [GitHub Releases](https://github.com/Pikatsuto/raspberry-builds/releases).

### debian-base

**Description**: Minimal Debian 13 (Trixie) with RaspiOS kernel and firmware

**Services included**:
- base (RaspiOS kernel, NetworkManager, SSH)

**Size**: ~512MB compressed

**RAM required**: 2GB minimum

**Use cases**:
- Minimal Debian installation
- Custom development base
- Learning/testing Raspberry Pi

**Default login**:
- Username: `pi`
- Password: `raspberry`

**Download**:
```bash
wget https://github.com/Pikatsuto/raspberry-builds/releases/latest/download/debian-base.img.xz
```

---

### debian-qemu-docker

**Description**: Debian with Incus virtualization and Docker Engine

**Services included**:
- base
- qemu (Incus + KVM)
- docker (Docker Engine + Portainer + Watchtower)

**Size**: ~4-5GB compressed

**RAM required**: 4GB minimum (8GB recommended)

**Use cases**:
- Container host (Docker + Incus)
- Development platform
- Microservices deployment
- VM/container testing

**Access**:
- Portainer: `https://raspberry-ip:9443`
- Incus: `incus list` (SSH)

**Download**:
```bash
wget https://github.com/Pikatsuto/raspberry-builds/releases/latest/download/debian-qemu-docker.img.xz
```

---

### debian-qemu-openwrt-hotspot

**Description**: Debian with OpenWrt router and WiFi hotspot

**Services included**:
- base
- qemu (Incus)
- openwrt (OpenWrt container)
- hotspot (WiFi AP)

**Size**: ~3-4GB compressed

**RAM required**: 4GB minimum

**Hardware required**:
- Dual NIC (eth0 + eth1) or single NIC
- WiFi adapter(s) for hotspot

**Use cases**:
- Network router/firewall
- WiFi access point
- VPN gateway
- Network segmentation

**Access**:
- OpenWrt LuCI: `http://192.168.10.1`
- WiFi SSID: `RaspberryPi-5G` (password: `raspberry`)

**Download**:
```bash
wget https://github.com/Pikatsuto/raspberry-builds/releases/latest/download/debian-qemu-openwrt-hotspot.img.xz
```

---

### debian-qemu-docker-openwrt-hotspot-haos (Full Stack)

**Description**: Complete home automation and network platform

**Services included**:
- base
- qemu (Incus + KVM)
- docker (Docker Engine + Portainer)
- openwrt (OpenWrt router)
- hotspot (WiFi AP)
- haos (Home Assistant OS)

**Size**: ~6-8GB compressed

**RAM required**: 8GB (Raspberry Pi 5 8GB recommended)

**Hardware required**:
- Dual NIC (eth0 + eth1) recommended
- WiFi adapter(s) for hotspot
- Optional: Zigbee/Z-Wave USB dongle

**Use cases**:
- Complete home automation gateway
- Network router + WiFi + smart home
- All-in-one Raspberry Pi solution

**Access**:
- Home Assistant: `http://raspberry-ip:8123`
- Portainer: `https://raspberry-ip:9443`
- OpenWrt LuCI: `http://192.168.10.1`
- WiFi SSID: `RaspberryPi-5G`

**Download**:
```bash
wget https://github.com/Pikatsuto/raspberry-builds/releases/latest/download/debian-qemu-docker-openwrt-hotspot-haos.img.xz
```

---

## Image Comparison

| Feature | base | qemu-docker | qemu-openwrt-hotspot | Full Stack |
|---------|------|-------------|----------------------|------------|
| Debian OS | ✅ | ✅ | ✅ | ✅ |
| RaspiOS Kernel | ✅ | ✅ | ✅ | ✅ |
| Network Bridges | ✅ | ✅ | ✅ | ✅ |
| SSH | ✅ | ✅ | ✅ | ✅ |
| Incus (VMs/containers) | ❌ | ✅ | ✅ | ✅ |
| Docker | ❌ | ✅ | ❌ | ✅ |
| Portainer | ❌ | ✅ | ❌ | ✅ |
| OpenWrt Router | ❌ | ❌ | ✅ | ✅ |
| WiFi Hotspot | ❌ | ❌ | ✅ | ✅ |
| Home Assistant | ❌ | ❌ | ❌ | ✅ |
| Zigbee Auto-detect | ❌ | ❌ | ❌ | ✅ |
| Minimum RAM | 2GB | 4GB | 4GB | 8GB |
| Compressed Size | ~512MB | ~700MB | ~750MB | ~750MB |

---

## Release Channels

### Stable (main branch)

**Recommended for production use**

- Tested and verified
- No pre-release flag
- Downloaded from latest release

**Download**:
```bash
# Latest stable
wget https://github.com/Pikatsuto/raspberry-builds/releases/latest/download/<image-name>.img.xz
```

### Test (test branch)

**For testing new features**

- Pre-release builds
- May contain bugs
- Use for testing only

**Download**:
```bash
# Browse releases and select test build
# URL: https://github.com/Pikatsuto/raspberry-builds/releases
```

### Preview (preview branch)

**Experimental builds**

- Bleeding-edge features
- Unstable
- Use at your own risk

---

## Daily Builds

**Automatic daily builds** at 2:00 AM UTC

**Tag format**: `daily-YYYY-MM-DD`

**Purpose**:
- Captures latest base image updates
- Tests build system
- Provides fresh images daily

**Download**:
```bash
# Today's build
wget https://github.com/Pikatsuto/raspberry-builds/releases/download/daily-2024-12-08/<image-name>.img.xz
```

**Note**: Daily builds overwrite previous daily release. Download and archive if needed.

---

## Installation

### 1. Download Image

Choose image from above, download via browser or wget.

**Verify checksum**:
```bash
sha256sum <image-name>.img.xz
# Compare with .sha256 file from release
```

### 2. Flash to SD Card

**Linux**:
```bash
xz -dc <image-name>.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

**macOS**:
```bash
xz -dc <image-name>.img.xz | sudo dd of=/dev/rdiskX bs=4m
sync
```

**Windows**:
- Use [Balena Etcher](https://www.balena.io/etcher/)
- Select `.img.xz` file
- Select SD card
- Flash

### 3. Boot Raspberry Pi

- Insert SD card
- Connect Ethernet (recommended for first boot)
- Power on
- Wait 3-5 minutes for first-boot setup
- Find IP address from router or MOTD on login

---

## Customization After Installation

All images can be customized post-installation:

**Update system**:
```bash
sudo apt update && sudo apt upgrade -y
```

**Install additional packages**:
```bash
sudo apt install <package-name>
```

**Add Docker containers** (if Docker image):
```bash
docker run -d <container-image>
# Or use Portainer web UI
```

**Create Incus containers/VMs** (if qemu image):
```bash
incus launch images:alpine mycontainer
incus launch images:debian myvm --vm
```

---

## Building Custom Images

Don't see the image you need? Build your own!

**See**: [Creating Custom Images](Custom-Images.md)

**Quick example**:
```bash
git clone https://github.com/Pikatsuto/raspberry-builds.git
cd raspberry-builds

# Build custom combination
./bin/autobuild --image debian/qemu+docker+haos

# Or create entirely custom image
cp -r images/debian images/myproject
vim images/myproject/config.sh
./bin/autobuild --image myproject
```

---

## Support

**Issues with images**:
- [Report bug](https://github.com/Pikatsuto/raspberry-builds/issues/new?template=bug_report.md)
- [Request feature](https://github.com/Pikatsuto/raspberry-builds/issues/new?template=feature_request.md)
- [Ask question](https://github.com/Pikatsuto/raspberry-builds/discussions)

**Image documentation**:
- [Getting Started](Getting-Started.md)
- [FAQ](FAQ.md)
- [Troubleshooting](Troubleshooting.md)