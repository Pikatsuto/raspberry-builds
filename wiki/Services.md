# Services

Complete guide to available services and creating custom ones.

## Available Services

### base (Always Included)

**Purpose**: Essential system configuration for all images

**Packages**:
- `raspberrypi-kernel` - RaspiOS kernel with RP1 drivers
- `raspberrypi-bootloader` - Boot firmware
- `firmware-brcm80211` - WiFi/Bluetooth firmware
- `NetworkManager` - Network management
- `openssh-server` - SSH access
- Essential utilities

**Configuration**:
- RaspiOS APT repository + pinning
- Network bridges (br-wan, br-lan if dual NIC)
- SSH enabled
- MOTD with IP addresses

**First-boot actions**:
- Partition resize to fill SD card
- Network interface name persistence
- Bridge configuration based on detected NICs

---

### qemu

**Purpose**: Incus container/VM platform with KVM acceleration

**Dependencies**: None

**Packages**:
- `qemu-kvm` - KVM virtualization
- `incus` - Container/VM manager
- `incus-tools` - Management utilities

**Configuration**:
- Incus initialization with default profile
- Network bridges: br-wan (WAN), br-lan (LAN if dual NIC)
- Storage pool: default (dir backend)

**First-boot actions**:
- Create br-lan and br-wan bridges (if not exist)
- Configure Incus network integration
- Enable IP forwarding and NAT

**Use cases**:
- Run VMs (Home Assistant, OpenWrt)
- Create containers for isolated services
- Development environments

---

### docker

**Purpose**: Docker Engine with Portainer and Watchtower

**Dependencies**: None

**Packages**:
- `docker-ce` - Docker Engine
- `docker-ce-cli` - Docker CLI
- `containerd.io` - Container runtime

**Configuration**:
- Docker installed from official repository
- User `pi` added to `docker` group

**First-boot actions**:
- Deploy Portainer (web UI for Docker)
- Deploy Watchtower (automatic container updates)
- Configure bridge networking

**Services deployed**:
- **Portainer**: `https://raspberry-ip:9443`
- **Watchtower**: Automatic updates for containers

**Use cases**:
- Run containerized applications
- Manage containers via web UI
- Auto-update containers

---

### haos

**Purpose**: Home Assistant OS in an Incus VM

**Dependencies**: `qemu` (Incus required)

**Packages**: None (VM image downloaded at first boot)

**First-boot actions**:
- Download Home Assistant OS image (latest stable)
- Create Incus VM named `haos`
- Allocate resources (2 vCPUs, 4GB RAM, 24GB disk)
- Configure network bridge (br-lan or br-wan)
- Detect and pass through USB Zigbee coordinators
- Start VM

**Zigbee auto-detection**:
- Scans `/dev/ttyUSB*` and `/dev/ttyACM*`
- Detects ConBee, CC2652, Sonoff, Silicon Labs dongles
- Passes through via USB vendor/product ID

**Access**:
- Home Assistant: `http://raspberry-ip:8123`
- First boot setup takes 5-10 minutes

**Use cases**:
- Home automation platform
- Zigbee/Z-Wave integration
- IoT device management

---

### openwrt

**Purpose**: OpenWrt router in an Incus container

**Dependencies**: `qemu` (Incus required)

**Packages**: None (container image downloaded at first boot)

**First-boot actions**:
- Download OpenWrt rootfs image
- Create Incus container named `openwrt`
- Allocate resources (1 vCPUs, 1GB RAM, 24GB disk)
- Configure network: eth0 → br-wan, eth1 → br-lan
- Set static IP: `192.168.10.1/24`
- Start container

**Network configuration**:
- WAN: br-wan (DHCP client)
- LAN: br-lan (192.168.10.1, DHCP server)

**Access**:
- LuCI web UI: `http://192.168.10.1`
- SSH: `ssh root@192.168.10.1`

**Use cases**:
- Advanced routing and firewall
- VPN server/client
- QoS and traffic shaping
- Network monitoring

---

### hotspot

**Purpose**: WiFi access point (2.4GHz/5GHz)

**Dependencies**: None

**Packages**:
- `hostapd` - WiFi access point daemon

**Configuration files**:
- `hostapd-5ghz.conf` - 5GHz AP config
- `hostapd-2.4ghz.conf` - 2.4GHz AP config

**First-boot actions**:
- Detect WiFi interfaces (wlan0, wlan1)
- Configure hostapd based on detected adapters:
  - Dual WiFi: 2.4GHz (wlan0) + 5GHz (wlan1)
  - Single WiFi: 5GHz (wlan0)
- Attach to br-lan (if exists) or br-wan
- Disable NetworkManager management of WiFi
- Start hostapd services

**Default credentials**:
- SSID: `RaspberryPi-WIFI`
- Password: `raspberry`

**Use cases**:
- WiFi access for IoT devices
- Guest network
- Extend network coverage

---

## Service Combination Examples

### Minimal Development Platform
```bash
./bin/autobuild --image debian
```
- Base Debian with RaspiOS kernel
- SSH access
- Network bridges

### Docker Host
```bash
./bin/autobuild --image debian/docker
```
- Docker Engine
- Portainer web UI
- Watchtower auto-updates

### Virtualization Platform
```bash
./bin/autobuild --image debian/qemu
```
- Incus containers/VMs
- KVM acceleration

### Home Automation Gateway
```bash
./bin/autobuild --image debian/qemu+haos
```
- Home Assistant OS VM
- Zigbee dongle auto-detection
- Web UI on port 8123

### Network Router + WiFi AP
```bash
./bin/autobuild --image debian/qemu+openwrt+hotspot
```
- OpenWrt routing
- Dual-band WiFi hotspot
- Advanced firewall/QoS

### Full Stack
```bash
./bin/autobuild --image debian/qemu+docker+openwrt+hotspot+haos
```
- All services combined
- Ideal for Raspberry Pi 5 with 8GB RAM

---

## Creating Custom Services

### Service Directory Structure

```
images/debian/services/myservice/
├── setup.sh              # Required: package installation (runs in QEMU)
├── first-boot/
│   └── init.sh           # Optional: runtime config (runs on first boot)
├── setupfiles/           # Optional: static files → /etc/setupfiles/
│   ├── config.conf
│   └── script.sh
├── depends.sh            # Optional: dependencies
└── motd.sh               # Optional: MOTD content
```

### setup.sh (Package Installation)

Executed in QEMU ARM64 during build.

**Template**:
```bash
#!/bin/bash
set -e

# Install packages
apt update
apt install -y package1 package2

# Configure system
systemctl enable my-service

# Copy files
cp /etc/setupfiles/config.conf /etc/my-service/
```

**Best practices**:
- Use `set -e` to exit on errors
- Install packages from Debian repositories when possible
- Add custom repositories if needed
- Enable systemd services that should start at boot
- Don't start services (no network in QEMU)

### first-boot/init.sh (Runtime Configuration)

Executed on first boot on Raspberry Pi.

**Template**:
```bash
#!/bin/bash
set -e

# Detect hardware
if ip link show eth1 >/dev/null 2>&1; then
    BRIDGE="br-lan"
else
    BRIDGE="br-wan"
fi

# Download resources
wget https://example.com/resource.tar.gz -O /tmp/resource.tar.gz

# Create containers/VMs
incus launch images:alpine mycontainer

# Configure services
systemctl start my-service
```

**Best practices**:
- Detect hardware and adapt configuration
- Download large files here (not in setup.sh)
- Create containers/VMs
- Start services
- Use `/etc/setupfiles/` for configuration files

### depends.sh (Dependencies)

Declare dependencies on other services.

**Example**:
```bash
# myservice depends on qemu
DEPENDS_ON="qemu"
```

**Dependency resolution**:
- Dependencies are automatically included
- Build order is adjusted to satisfy dependencies

### motd.sh (Message of the Day)

Display service information on login.

**Example**:
```bash
cat <<'EOF'
My Service UI: https://raspberry-ip:8080
Username: admin
Password: (set on first access)
EOF
```

### setupfiles/ (Static Files)

Static configuration files copied to `/etc/setupfiles/`.

**Access in scripts**:
```bash
# In setup.sh or first-boot/init.sh
cp /etc/setupfiles/myconfig.conf /etc/my-service/
```

---

## Service Development Workflow

### 1. Create Service Directory

```bash
mkdir -p images/debian/services/myservice/first-boot
mkdir -p images/debian/services/myservice/setupfiles
```

### 2. Write setup.sh

```bash
cat > images/debian/services/myservice/setup.sh <<'EOF'
#!/bin/bash
set -e

apt update
apt install -y nginx

systemctl enable nginx
EOF

chmod +x images/debian/services/myservice/setup.sh
```

### 3. Write first-boot/init.sh (Optional)

```bash
cat > images/debian/services/myservice/first-boot/init.sh <<'EOF'
#!/bin/bash
set -e

# Configure nginx with custom config
cp /etc/setupfiles/nginx.conf /etc/nginx/sites-available/default
systemctl restart nginx
EOF

chmod +x images/debian/services/myservice/first-boot/init.sh
```

### 4. Add Configuration Files (Optional)

```bash
cat > images/debian/services/myservice/setupfiles/nginx.conf <<'EOF'
server {
    listen 80;
    root /var/www/html;
    index index.html;
}
EOF
```

### 5. Add MOTD (Optional)

```bash
cat > images/debian/services/myservice/motd.sh <<'EOF'
cat <<'MOTD'
Nginx: http://raspberry-ip/
MOTD
EOF

chmod +x images/debian/services/myservice/motd.sh
```

### 6. Test Service

```bash
# Build image with your service
./bin/autobuild --image debian/myservice

# Flash and boot
sudo dd if=debian-myservice.img of=/dev/sdX bs=4M status=progress

# Check logs on first boot
sudo journalctl -u services-first-boot
```

### 7. Debug Issues

**QEMU stage issues**:
```bash
# Check QEMU logs
cat images/debian-myservice/qemu-*.log

# Manually test in QEMU
./bin/autobuild --image debian/myservice --skip-compress
```

**First-boot stage issues**:
```bash
# On Raspberry Pi, check logs
sudo journalctl -u services-first-boot -f

# Check service status
sudo systemctl status myservice
```

---

## Service Best Practices

### Package Installation
- Install in `setup.sh`, not `first-boot/init.sh`
- Use official Debian repositories when possible
- Pin package versions if stability critical

### Resource Downloads
- Download large files in `first-boot/init.sh`
- Don't download in `setup.sh` (slows QEMU)
- Cache downloads in `/var/cache/` if appropriate

### Hardware Detection
- Always detect hardware in `first-boot/init.sh`
- Adapt configuration based on detection
- Fail gracefully if hardware missing

### Error Handling
- Use `set -e` to exit on errors
- Log errors to journald
- Provide helpful error messages

### Network Configuration
- Use existing bridges (br-wan, br-lan)
- Don't create new bridges unless necessary
- Check bridge existence before use

### Security
- Don't hardcode passwords in scripts
- Use strong default passwords (prompt user to change)
- Enable firewall if service exposed

---

## Next Steps

- [Create a custom image with your service](Custom-Images.md)
- [Learn about hardware auto-detection](Hardware-Detection.md)
- [Set up CI/CD for automated builds](GitHub-Actions.md)