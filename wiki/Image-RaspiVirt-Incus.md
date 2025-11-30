# RaspiVirt-Incus Image

**RaspiVirt-Incus** is a Raspberry Pi image optimized for running containers and virtual machines using [Incus](https://linuxcontainers.org/incus/), the modern LXC/LXD fork. This image provides a complete virtualization platform with KVM support, bridged networking, and the Incus web UI.

## Overview

RaspiVirt-Incus transforms your Raspberry Pi into a powerful virtualization host capable of running:
- **System containers** (LXC) - Lightweight, fast containers with full OS isolation
- **Application containers** - OCI-compatible containers
- **Virtual machines** - KVM-accelerated VMs with full hardware virtualization

### Key Features

- **Incus Container Manager**: Modern LXC/LXD fork with active development
- **Incus Web UI**: Built-in web interface for easy management (port 8443)
- **KVM Virtualization**: Hardware-accelerated virtual machines on ARM64
- **Bridged Networking**: `br-wan` bridge for direct network access to containers/VMs
- **Automatic Updates**: RaspiOS kernel + Debian packages via APT
- **First-Boot Configuration**: Automatic partition resize and network setup
- **Classic Network Names**: Uses `eth0` instead of `enp*` for predictable naming

## Image Specifications

- **Image Name**: `rpi-raspivirt-incus.img.xz`
- **Base OS**: Debian 13 (Trixie) ARM64
- **Kernel**: Raspberry Pi OS kernel (with RP1 drivers)
- **Image Size**: ~1.5 GB (expands on first boot)
- **Compressed Size**: ~500MB (xz compressed)

### Build Configuration

From `images/raspivirt-incus/config.sh`:
```bash
OUTPUT_IMAGE="rpi-raspivirt-incus.img"
IMAGE_SIZE="4G"
QEMU_RAM="8G"
QEMU_CPUS="4"
DESCRIPTION="Raspberry Pi image with Incus, KVM virtualization and br-wan bridge"
```

## Installed Software

### Core System
- **Debian 13 (Trixie)** - Latest Debian stable
- **Raspberry Pi Kernel** - Full hardware support (RP1, WiFi, Bluetooth)
  - `linux-image-rpi-v8` - Raspberry Pi 3/4/5 kernel
  - `linux-image-rpi-2712` - Raspberry Pi 5 optimized kernel
  - `linux-headers-rpi-v8` - Kernel headers for module compilation
  - `linux-headers-rpi-2712` - Pi 5 kernel headers
  - `raspi-firmware` - Bootloader and firmware
  - `firmware-brcm80211` - WiFi/Bluetooth firmware

### Virtualization Stack
- **Incus** - Container and VM manager
  - `incus` - Core daemon and CLI
  - `incus-ui-canonical` - Official web UI
- **KVM/QEMU** - Hardware virtualization
  - `qemu-system-aarch64` - ARM64 system emulator
  - `qemu-kvm` - KVM acceleration support
  - `qemu-utils` - Image utilities
  - `qemu-efi-aarch64` - UEFI firmware for VMs

### Networking
- **systemd-networkd** - Network management
- **netplan.io** - Network configuration
- **bridge-utils** - Bridge utilities
- **net-tools** - Classic networking tools (ifconfig, route)
- **iptables** - Firewall and NAT

### System Utilities
- **curl**, **wget** - Download tools
- **sudo** - Privilege escalation
- **openssh-server** - Remote access
- **parted** - Partition management
- **ca-certificates**, **gnupg** - Security and package verification

## Network Configuration

### br-wan Bridge

The image uses a **bridged network configuration** (`br-wan`) that allows containers and VMs to appear as physical devices on your network.

#### Netplan Configuration (`/etc/netplan/99-br-wan.yaml`)

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
  bridges:
    br-wan:
      interfaces: [eth0]
      dhcp4: true
      dhcp6: true
```

#### How It Works

```
Internet
    ↓
Your Router (DHCP)
    ↓
┌─────────────────────────────────┐
│  Raspberry Pi                   │
│  ┌───────────────────────────┐  │
│  │  br-wan (Bridge)          │  │ ← Gets IP from router
│  │   ├─ eth0 (Physical NIC) │  │
│  │   ├─ Container 1          │  │ ← Gets IP from router
│  │   ├─ Container 2          │  │ ← Gets IP from router
│  │   └─ VM 1                 │  │ ← Gets IP from router
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Advantages**:
- Containers/VMs get IPs directly from your router
- No NAT required
- Containers/VMs accessible from your LAN
- Simplified networking

### Incus Network Integration

Incus is configured to use the `br-wan` bridge in **passthrough mode**:
- Incus network name: `br-wan`
- Parent device: `br-wan` (system bridge)
- IPv4/IPv6: Disabled (managed by external DHCP)
- All containers/VMs attach to `br-wan` by default

## First-Boot Process

The image uses a **two-stage first-boot process** to configure the system:

### Stage 1: rpi-first-boot (Before Network)

Runs on first boot before network is configured.

**Script**: `/usr/local/bin/rpi-first-boot.sh`

**Actions**:
1. **Enable classic network names**:
   - Adds `net.ifnames=0 biosdevname=0` to `/boot/firmware/cmdline.txt`
   - Results in `eth0`, `wlan0` instead of `enp*`, `wlp*`
2. **Disable cloud-init networking**:
   - Creates `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`
   - Prevents cloud-init from managing network (netplan takes over)
3. **Resize root partition**:
   - Detects root partition
   - Expands to use full SD card/SSD
   - Resizes ext4 filesystem
4. **Deploy netplan configuration**:
   - Moves `99-br-wan.yaml` to `/etc/netplan/`
   - Generates netplan configuration
5. **Self-destruct**:
   - Disables systemd service
   - Deletes service file and script
   - Reboots system

### Stage 2: services-first-boot (After Network)

Runs after reboot when network is available.

**Script**: `/usr/local/bin/services-first-boot.sh`

**Actions**:
1. **Wait for internet connectivity**:
   - Pings 8.8.8.8 and 1.1.1.1
   - Timeout: 5 minutes
   - Required for Incus initialization
2. **Initialize Incus**:
   - Minimal initialization: `incus admin init --minimal`
   - Configure HTTPS UI: `incus config set core.https_address :8443`
   - Apply netplan (creates `br-wan` bridge)
   - Create Incus network using `br-wan`
   - Attach `br-wan` to default profile
3. **Self-destruct**:
   - Disables systemd service
   - Deletes service file and script

**Why Two Stages?**
- Stage 1 runs **before network** to resize partition and configure network
- Stage 2 runs **after network** to initialize services requiring internet access
- Ensures proper ordering of operations

## MOTD IP Updater

The image includes a dynamic **Message of the Day (MOTD)** that displays network information on login.

**Script**: `/usr/local/bin/update-motd-ip.sh`

**Triggers**:
- On boot (`update-motd-ip.service`)
- On network changes (`update-motd-ip.path` monitors `/etc/netplan/`)

**Displayed Information**:
- System hostname
- IP addresses (IPv4/IPv6)
- Network interfaces
- Incus web UI URL (https://IP:8443)

## User Configuration

### Default User

- **Username**: `pi`
- **Password**: `raspberry`
- **Sudo**: Passwordless (`NOPASSWD:ALL`)
- **Groups**: `sudo`, `kvm`, `incus`, `incus-admin`

**Cloud-Init Configuration** (`cloudinit/user-data`):
```yaml
users:
  - name: pi
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    lock_passwd: false

chpasswd:
  list: |
    pi:raspberry
  expire: false

ssh_pwauth: true
```

### Security Recommendations

After first boot, **immediately**:
1. Change the default password: `passwd pi`
2. Add SSH keys: `ssh-copy-id pi@<raspberry-pi-ip>`
3. Disable password authentication: Edit `/etc/ssh/sshd_config`
4. Configure Incus authentication (see below)

## Incus Configuration

### Accessing Incus Web UI

1. Get Raspberry Pi IP address: `ip addr show br-wan`
2. Open browser: `https://<raspberry-pi-ip>:8443`
3. Accept self-signed certificate
4. Create admin account on first login

### Basic Incus Commands

```bash
# Check Incus status
incus info

# List containers/VMs
incus list

# Launch a container (gets IP from br-wan/DHCP)
incus launch images:debian/13 mycontainer

# Launch a VM
incus launch images:debian/13 myvm --vm

# Access container console
incus exec mycontainer -- bash

# Stop container
incus stop mycontainer

# Delete container
incus delete mycontainer
```

### Creating a Container with DHCP

```bash
# Launch Debian container
incus launch images:debian/13 web1

# Check assigned IP (from your router)
incus list

# Container is accessible from your LAN
ping <container-ip>
ssh user@<container-ip>
```

### Creating a Virtual Machine

```bash
# Launch Ubuntu VM with 2GB RAM, 2 CPUs
incus launch images:ubuntu/22.04 vm1 --vm \
    -c limits.memory=2GB \
    -c limits.cpu=2

# Access VM console
incus console vm1

# Access VM via SSH (after VM gets DHCP IP)
ssh user@<vm-ip>
```

### Network Configuration

The default profile uses `br-wan`:
```bash
# View default profile
incus profile show default

# Example output:
# devices:
#   eth0:
#     nictype: bridged
#     parent: br-wan
#     type: nic
```

All containers/VMs automatically get network access through `br-wan`.

## System Optimization

### Network Tuning (`/etc/sysctl.d/99-network-tuning.conf`)

```bash
# Increased network buffer sizes for better performance
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Enable IP forwarding for containers/VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

### Timezone and Locale

- **Timezone**: Europe/Paris (configurable in `setup.sh`)
- **Locale**: `fr_FR.UTF-8` (configurable in `setup.sh`)

## Package Management

### APT Repositories

The image includes both **Debian** and **RaspiOS** repositories:

**Debian** (`/etc/apt/sources.list`):
```
deb http://deb.debian.org/debian trixie main contrib non-free
```

**RaspiOS** (`/etc/apt/sources.list.d/raspi.sources`):
```
Types: deb
URIs: http://archive.raspberrypi.com/debian/
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/raspberrypi-archive-keyring.pgp
```

**Incus** (`/etc/apt/sources.list.d/zabbly-incus-stable.sources`):
```
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: trixie
Components: main
Signed-By: /etc/apt/keyrings/zabbly.asc
```

### APT Pinning (`/etc/apt/preferences.d/raspi-pin`)

```
# Pin RaspiOS packages for kernel/firmware/bootloader
Package: raspberrypi-kernel raspberrypi-bootloader libraspberrypi* firmware-brcm80211
Pin: release o=Raspberry Pi Foundation
Pin-Priority: 1001

# Default Debian packages
Package: *
Pin: release o=Debian
Pin-Priority: 500
```

This ensures:
- Kernel and firmware come from RaspiOS (hardware compatibility)
- All other packages come from Debian (stability and security)

### Safe System Updates

```bash
# Update all packages (Debian + RaspiOS kernel/firmware)
sudo apt update
sudo apt upgrade -y

# Auto-upgrade without prompts
sudo apt full-upgrade -y
```

The pinning configuration prevents accidental kernel changes while allowing safe updates.

## Use Cases

### Home Lab Server
- Run multiple containers for different services
- Host web servers, databases, development environments
- Isolated environments for testing

### Development Environment
- Create disposable development containers
- Test across multiple Linux distributions
- Develop and test ARM64 applications

### Network Services
- DNS server (Pi-hole in container)
- VPN server (WireGuard/OpenVPN)
- Home automation (Home Assistant)

### Education and Learning
- Learn containerization and virtualization
- Experiment with different Linux distributions
- Practice system administration

## Customization

### Modifying the Image

1. **Fork this repository**
2. **Edit configuration** (`images/raspivirt-incus/config.sh`):
   - Change image size
   - Adjust QEMU resources
3. **Customize setup script** (`images/raspivirt-incus/setup.sh`):
   - Add packages
   - Change timezone/locale
   - Install additional software
4. **Add custom files** (`images/raspivirt-incus/setupfiles/`):
   - Configuration files
   - Scripts
   - Certificates
5. **Modify cloud-init** (`images/raspivirt-incus/cloudinit/user-data`):
   - Change default user
   - Add SSH keys
   - Modify passwords
6. **Commit and push** - GitHub Actions builds automatically

### Example Modifications

#### Add Additional Packages

Edit `setup.sh` around line 20:
```bash
apt install -y \
    curl \
    wget \
    sudo \
    openssh-server \
    vim \
    htop \
    docker.io  # Add Docker
```

#### Change Default User

Edit `cloudinit/user-data`:
```yaml
users:
  - name: admin  # Change username
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    lock_passwd: false

chpasswd:
  list: |
    admin:securepassword  # Change password
```

#### Adjust Image Size

Edit `config.sh`:
```bash
IMAGE_SIZE="16G"  # Increase to 16GB
```

## Troubleshooting

### Incus Web UI Not Accessible

**Check Incus status**:
```bash
sudo systemctl status incus
```

**Verify HTTPS listener**:
```bash
incus config get core.https_address
# Should show: :8443
```

**Check firewall** (if enabled):
```bash
sudo iptables -L -n | grep 8443
```

### Containers Not Getting IP Addresses

**Verify br-wan bridge**:
```bash
ip addr show br-wan
# Should show an IP address
```

**Check netplan**:
```bash
sudo netplan status
```

**Verify Incus network**:
```bash
incus network show br-wan
```

### First Boot Not Completing

**Check logs**:
```bash
# Check rpi-first-boot service
journalctl -u rpi-first-boot.service

# Check services-first-boot service
journalctl -u services-first-boot.service
```

**Common issues**:
- No internet connectivity (services-first-boot requires internet)
- DHCP not available on network
- Network cable not connected

### Partition Not Resized

**Manual resize**:
```bash
# Identify root partition
sudo fdisk -l

# Resize partition (example: /dev/mmcblk0p2)
sudo parted /dev/mmcblk0 resizepart 2 100%

# Resize filesystem
sudo resize2fs /dev/mmcblk0p2
```

## Performance Tips

### Use Fast Storage
- Use SSD instead of SD card (USB 3.0 or NVMe via PCIe)
- Enable TRIM for SSDs
- Use high-quality SD cards (A2 rating minimum)

### Optimize for Containers
- Prefer containers over VMs (lower overhead)
- Use ZFS storage pool for better performance (optional)
- Limit container resources appropriately

### Monitor System Resources
```bash
# Check CPU/RAM usage
htop

# Check disk usage
df -h

# Check Incus resource usage
incus info --resources
```

## Related Documentation

- **[Home](Home)**: Project overview
- **[GitHub Actions](GitHub-Actions)**: Automated build system
- **[RaspiVirt-Incus+Docker](Image-RaspiVirt-Incus-Docker)**: This image plus Docker
- **[Incus Documentation](https://linuxcontainers.org/incus/docs/latest/)**: Official Incus docs
- **[Debian Documentation](https://www.debian.org/doc/)**: Debian reference

## Build Information

**GitHub Actions Workflow**: Automatically builds this image on push and daily schedule

**Build Process**:
1. Download Raspberry Pi OS and Debian base images
2. Execute `setup.sh` in QEMU ARM64
3. Install RaspiOS kernel and Incus via APT
4. Merge boot partition and rootfs
5. Compress with PiShrink

**Download**: [Latest Release](../../releases)

**Build Logs**: [GitHub Actions](../../actions)