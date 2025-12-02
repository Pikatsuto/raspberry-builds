# RaspiVirt-Incus+HAOS Image

**RaspiVirt-Incus+HAOS** is a Raspberry Pi image that combines the power of [Incus](https://linuxcontainers.org/incus/) virtualization with [Home Assistant OS](https://www.home-assistant.io/). This image provides a complete home automation platform running in a virtual machine with automatic configuration and USB device passthrough for Zigbee dongles.

## Overview

RaspiVirt-Incus+HAOS extends the base [RaspiVirt-Incus](Image-RaspiVirt-Incus) image by automatically deploying Home Assistant OS as a virtual machine. On first boot, the system downloads HAOS, imports it into Incus, creates a VM with optimal configuration, and starts it automatically.

### Key Features

- **Everything from RaspiVirt-Incus**: Full Incus container/VM platform with web UI
- **Home Assistant OS VM**: Pre-configured HAOS virtual machine (16.3)
- **Automatic Setup**: Downloads, imports, and configures HAOS on first boot
- **Optimized Configuration**: 2 CPU cores, 4GB RAM, 24GB disk
- **Adaptive Network Configuration**:
  - Dual-NIC mode: eth1 detected → br-lan (internal LAN) + br-wan (WAN)
  - Single-NIC mode: eth0 → br-wan (WAN)
- **Built-in DHCP Server**: Automatic DHCP on br-lan (192.168.10.100-199) with Cloudflare DNS
- **NAT Routing**: Internet access for internal LAN via NAT masquerade
- **Zigbee Dongle Detection**: Automatically detects and passthroughs USB Zigbee dongles
- **Auto-Start on Boot**: HAOS VM starts automatically when Raspberry Pi boots
- **Hardware Acceleration**: KVM-accelerated virtualization for better performance
- **Secure Boot Disabled**: HAOS VM configured to bypass Secure Boot restrictions

## Image Specifications

- **Image Name**: `rpi-raspivirt-incus-haos.img.xz`
- **Base OS**: Debian 13 (Trixie) ARM64
- **Kernel**: Raspberry Pi OS kernel (with RP1 drivers)
- **Image Size**: ~1.5 GB (expands on first boot)
- **Compressed Size**: ~500MB (xz compressed)
- **HAOS Version**: 16.3 (downloaded on first boot)

### Build Configuration

From `images/raspivirt-incus+haos/config.sh`:
```bash
OUTPUT_IMAGE="rpi-raspivirt-incus.img"
IMAGE_SIZE="4G"
QEMU_RAM="8G"
QEMU_CPUS="4"
DESCRIPTION="Raspberry Pi image with Incus, KVM virtualization and br-wan bridge"
```

## Installed Software

This image includes everything from [RaspiVirt-Incus](Image-RaspiVirt-Incus) plus:

### Home Assistant OS
- **HAOS 16.3 ARM64** - Latest Home Assistant Operating System
- **Virtual Machine**: Incus VM with KVM acceleration
- **Resource Allocation**: 2 CPU cores, 4GB RAM, 24GB disk
- **Network**: Adaptive (br-lan or br-wan depending on eth1 presence)
- **Auto-Start**: Enabled on boot
- **Secure Boot**: Disabled for compatibility

### Network Stack
- **NetworkManager** - Bridge and connection management
- **dnsmasq** - DHCP server (DNS disabled, port 0)
  - Range: 192.168.10.100-199
  - DNS servers: 1.1.1.1, 1.0.0.1 (Cloudflare)
  - Lease time: 12 hours
- **iptables** - NAT masquerade and routing rules

### Additional Configuration
- **USB Passthrough**: Automatic Zigbee dongle detection and passthrough
- **First-Boot Automation**: HAOS download, import, and VM creation
- **Adaptive Networking**: Dual-bridge mode if eth1 detected

For base system packages (Debian, RaspiOS kernel, Incus, KVM), see [RaspiVirt-Incus documentation](Image-RaspiVirt-Incus#installed-software).

## Network Configuration

The image supports **two network modes** that are automatically detected and configured on first boot:

### Mode 1: Dual-NIC (eth1 detected)

When a second network interface (eth1) is detected, the system creates an **internal LAN** with DHCP:

```
Internet
    ↓
Router (DHCP)
    ↓
┌──────────────────────────────────────────┐
│  Raspberry Pi                            │
│  ┌────────────────────────────────────┐  │
│  │ eth0 → br-wan (WAN)                │  │ ← Gets IP from router
│  │        ↑                            │  │
│  │        │ NAT MASQUERADE             │  │
│  │        ↓                            │  │
│  │ eth1 → br-lan (Internal LAN)       │  │
│  │        192.168.10.254/24            │  │
│  │        ├─ DHCP: 192.168.10.100-199 │  │
│  │        ├─ DNS: 1.1.1.1, 1.0.0.1    │  │
│  │        ├─ HAOS VM (default)        │  │ ← Gets 192.168.10.x
│  │        └─ Other VMs/Containers     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**Configuration**:
- **br-lan** (default network): Internal LAN with DHCP server
  - IP: `192.168.10.254/24`
  - DHCP range: `192.168.10.100-199`
  - DNS servers: `1.1.1.1`, `1.0.0.1` (Cloudflare)
  - Managed by NetworkManager + dnsmasq
- **br-wan** (optional network): WAN connectivity
  - IP from router DHCP
  - For VMs/containers needing direct internet access
- **NAT routing**: VMs on br-lan can access internet via br-wan (iptables MASQUERADE)
- **Incus default profile**: Uses br-lan

**Use cases**:
- Isolated home automation network
- Multiple NICs on Raspberry Pi (USB Ethernet adapter + built-in)
- Separate IoT network from main LAN
- Advanced routing/firewall setups

### Mode 2: Single-NIC (eth1 not detected)

When only eth0 is available, the system creates a simple **WAN bridge**:

```
Internet
    ↓
Router (DHCP)
    ↓
┌─────────────────────────────────────┐
│  Raspberry Pi                       │
│  ┌───────────────────────────────┐  │
│  │  eth0 → br-wan (WAN)          │  │ ← Gets IP from router
│  │         ├─ Raspberry Pi       │  │
│  │         ├─ HAOS VM (default)  │  │ ← Gets IP from router
│  │         └─ Other VMs/Containers  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Configuration**:
- **br-wan** (default network): WAN connectivity
  - IP from router DHCP
  - All VMs/containers get IPs from router
  - Managed by NetworkManager
- **Incus default profile**: Uses br-wan
- **No DHCP server**: dnsmasq not started

**Use cases**:
- Standard setup with single Ethernet interface
- Simpler network topology
- All devices on same LAN as router

### Network Stack

**NetworkManager**:
- Manages all bridge connections
- Configures br-wan (always) and br-lan (if eth1 exists)
- Replaces netplan for better bridge management

**dnsmasq** (Dual-NIC mode only):
- DHCP server on br-lan
- DNS disabled (`port=0`) - no conflict with other DNS servers
- Clients get Cloudflare DNS (1.1.1.1, 1.0.0.1)

**iptables** (Dual-NIC mode only):
- NAT masquerade: `br-lan` → `br-wan`
- Forward rules for internet access
- Persistent across reboots via `iptables-restore.service`

### Switching Between Modes

The network mode is detected automatically on first boot. To switch modes:

**To enable Dual-NIC mode**:
1. Add USB Ethernet adapter to Raspberry Pi
2. Reflash image and boot
3. System detects eth1 and configures br-lan

**To revert to Single-NIC mode**:
1. Remove USB Ethernet adapter
2. Reflash image and boot
3. System only configures br-wan

**Note**: Network configuration happens during first boot and cannot be changed without reflashing.

## First-Boot Process

The image uses a **two-stage first-boot process**:

### Stage 1: rpi-first-boot (System Configuration)

**Script**: `/usr/local/bin/rpi-first-boot.sh`

**Actions**:
1. **Enable classic network names**:
   - Adds `net.ifnames=0 biosdevname=0` to `/boot/firmware/cmdline.txt`
   - Results in `eth0`, `eth1`, `wlan0` instead of `enp*`, `wlp*`

2. **Disable cloud-init networking**:
   - Creates `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg`
   - NetworkManager takes over network management

3. **Resize root partition**:
   - Detects root partition
   - Expands to use full SD card/SSD
   - Resizes ext4 filesystem

4. **Configure network bridges with NetworkManager**:
   - **Detect eth1**: Checks if second network interface exists
   - **If eth1 detected**:
     - Creates `br-lan` (192.168.10.254/24) on eth1
     - Creates `br-wan` (DHCP) on eth0
     - Deploys dnsmasq configuration for br-lan DHCP
     - Configures NAT masquerade rules (iptables)
     - Creates `iptables-restore.service` for persistence
   - **If eth1 not detected**:
     - Creates `br-wan` (DHCP) on eth0 only

5. **Reboot**: System reboots to apply network configuration

### Stage 2: services-first-boot (Service Deployment)

**Script**: `/usr/local/bin/services-first-boot.sh`

**Part 1: Incus Configuration**

1. **Wait for internet connectivity**:
   - Pings 8.8.8.8 and 1.1.1.1
   - Timeout: 5 minutes
   - Required for HAOS download

2. **Initialize Incus**:
   - Minimal initialization: `incus admin init --minimal`
   - Configure HTTPS UI: `incus config set core.https_address :8443`

3. **Configure Incus networks** (adaptive):
   - **If br-lan exists** (Dual-NIC mode):
     - Create Incus network for br-lan (default)
     - Create Incus network for br-wan (optional)
     - Default profile uses br-lan
   - **If br-lan missing** (Single-NIC mode):
     - Create Incus network for br-wan (default)
     - Default profile uses br-wan

**Part 2: HAOS Deployment**

4. **Download Home Assistant OS**:
   - Downloads `haos_generic-aarch64-16.3.qcow2.xz`
   - Decompresses image

5. **Import HAOS Image into Incus**:
   - Creates metadata (architecture, description, release)
   - Imports as `haos-aarch64-16.3` alias
   - Cleans up temporary files

6. **Create HAOS Virtual Machine**:
   ```bash
   incus init haos-aarch64-16.3 haos --vm
   ```

7. **Configure VM Resources**:
   - CPU: 2 cores (`limits.cpu=2`)
   - RAM: 4GB (`limits.memory=4GB`)
   - Disk: 24GB (`device override root size=24GB`)
   - Secure Boot: Disabled (`security.secureboot=false`)

8. **Network Configuration**:
   - VM inherits eth0 from default Incus profile
   - Dual-NIC: Gets IP from br-lan DHCP (192.168.10.x)
   - Single-NIC: Gets IP from router DHCP

9. **Enable Auto-Start**:
   ```bash
   incus config set haos boot.autostart=true
   ```

10. **Detect and Passthrough Zigbee Dongle**:
    - Scans `/dev/ttyUSB*` and `/dev/ttyACM*`
    - Detects common Zigbee coordinator vendors
    - Configures USB passthrough to VM

11. **Start HAOS VM**:
    ```bash
    incus start haos
    ```

12. **Self-Destruct**:
    - Disables services-first-boot service
    - Deletes service and script files

**Why Two Stages?**
- Stage 1: Network configuration (adaptive based on eth1 presence)
- Stage 2: Service deployment (requires internet and network)

## Zigbee Dongle Detection

The image includes automatic detection and passthrough for common Zigbee USB dongles.

### Supported Dongles

The detection script identifies dongles from these manufacturers:
- **Conbee/RaspBee** (dresden elektronik)
- **Sonoff Zigbee Dongles** (ITead)
- **Texas Instruments** (CC2652P, CC2652R, CC2531)
- **Silicon Labs** (EZSP coordinators)
- **FTDI-based** adapters

### How It Works

The first-boot script `/usr/local/bin/services-first-boot.sh:103-141`:

1. **Scans USB Serial Devices**:
   ```bash
   /dev/ttyUSB*  # Most Zigbee dongles
   /dev/ttyACM*  # Some Zigbee dongles
   ```

2. **Identifies Zigbee Devices**:
   - Uses `udevadm` to query device information
   - Checks for known vendor IDs
   - Extracts USB Vendor ID and Product ID

3. **Configures USB Passthrough**:
   ```bash
   incus config device add haos zigbee-dongle usb \
       vendorid="<VENDOR_ID>" \
       productid="<PRODUCT_ID>" \
       required=false
   ```

4. **Non-Blocking Behavior**:
   - If no dongle detected: Displays informational message
   - Does not prevent VM startup
   - You can add USB device manually later

### Manual USB Passthrough

If your Zigbee dongle is not auto-detected:

```bash
# List USB devices
lsusb

# Find your Zigbee dongle (example: Bus 001 Device 003: ID 0451:16a8)
# Vendor ID: 0451, Product ID: 16a8

# Add USB device to HAOS VM
incus config device add haos zigbee-dongle usb \
    vendorid=0451 \
    productid=16a8

# Restart HAOS VM
incus restart haos
```

### Verifying USB Passthrough

After boot, check if the USB device is passed to HAOS:

```bash
# SSH into Raspberry Pi
ssh pi@<raspberry-pi-ip>

# Check HAOS VM USB devices
incus config device show haos

# Expected output:
# zigbee-dongle:
#   productid: "16a8"
#   type: usb
#   vendorid: "0451"
```

## User Configuration

Same as [RaspiVirt-Incus User Configuration](Image-RaspiVirt-Incus#user-configuration):

- **Username**: `pi`
- **Password**: `raspberry`
- **Sudo**: Passwordless (`NOPASSWD:ALL`)
- **Groups**: `sudo`, `kvm`, `incus`, `incus-admin`

### Security Recommendations

After first boot, **immediately**:
1. Change default password: `passwd pi`
2. Configure Home Assistant authentication
3. Add SSH keys: `ssh-copy-id pi@<raspberry-pi-ip>`

## Accessing Home Assistant

### Finding HAOS IP Address

```bash
# SSH into Raspberry Pi
ssh pi@<raspberry-pi-ip>

# List Incus VMs
incus list

# Example output:
# +------+---------+---------------------+------+-----------+-----------+
# | NAME |  STATE  |        IPV4         | IPV6 |   TYPE    | SNAPSHOTS |
# +------+---------+---------------------+------+-----------+-----------+
# | haos | RUNNING | 192.168.1.150 (eth0)|      | VIRTUAL-MACHINE | 0   |
# +------+---------+---------------------+------+-----------+-----------+
```

### Web Interface

Open browser and navigate to:
```
http://192.168.1.150:8123
```

**Note**: Replace `192.168.1.150` with your HAOS VM IP address.

### Initial Setup

1. **Create Admin Account** (first access)
2. **Configure Location and Units**
3. **Install Integrations**:
   - Zigbee Home Automation (ZHA)
   - Zigbee2MQTT (if preferred)

### Configuring Zigbee

If a Zigbee dongle was detected and passed through:

1. Navigate to **Settings → Devices & Services**
2. Click **Add Integration**
3. Search for **Zigbee Home Automation** (ZHA)
4. Select your Zigbee coordinator:
   - `/dev/ttyUSB0` (most common)
   - `/dev/ttyACM0` (some dongles)
5. Follow setup wizard

## Incus Management

### Basic VM Commands

```bash
# Check HAOS VM status
incus list

# Start HAOS VM
incus start haos

# Stop HAOS VM (graceful shutdown)
incus stop haos

# Restart HAOS VM
incus restart haos

# Access VM console
incus console haos

# Check VM resource usage
incus info haos --resources
```

### VM Configuration

```bash
# Show full VM configuration
incus config show haos

# Check USB devices
incus config device show haos

# Check auto-start status
incus config get haos boot.autostart
```

### VM Snapshots

```bash
# Create snapshot before updates
incus snapshot create haos pre-update

# List snapshots
incus info haos

# Restore snapshot
incus snapshot restore haos pre-update

# Delete snapshot
incus snapshot delete haos pre-update
```

### Modifying VM Resources

```bash
# Increase RAM to 8GB
incus config set haos limits.memory=8GB

# Increase CPU cores to 4
incus config set haos limits.cpu=4

# Restart VM to apply changes
incus restart haos
```

## Use Cases

### Smart Home Hub
- **Zigbee/Z-Wave Devices**: Direct USB passthrough for coordinators
- **IoT Integration**: Control lights, sensors, thermostats
- **Automation**: Complex automations with Home Assistant
- **Voice Control**: Alexa, Google Home integration

### Home Automation Lab
- **Test Integrations**: Experiment with different protocols
- **Development**: Develop custom Home Assistant components
- **Snapshots**: Quick rollback for testing
- **Isolated Environment**: VM isolation from host

### Additional Services
Since this is a full Incus platform, you can run additional containers:
- **Pi-hole**: DNS ad-blocking
- **Nginx Proxy Manager**: Reverse proxy for HAOS and other services
- **Grafana/InfluxDB**: Metrics and monitoring
- **Node-RED**: Advanced automation flows

### Example: Adding Pi-hole Container

```bash
# Create Pi-hole container on br-wan
incus launch images:ubuntu/22.04 pihole

# Install Pi-hole
incus exec pihole -- bash -c "curl -sSL https://install.pi-hole.net | bash"

# Access Pi-hole web UI
# Find container IP: incus list
# Open: http://<pihole-ip>/admin
```

## Troubleshooting

### HAOS VM Not Starting

**Check VM status**:
```bash
incus list
incus info haos --show-log
```

**Common issues**:
- Insufficient RAM (increase in config.sh before build)
- HAOS image download failed (check internet during first boot)
- KVM not available (verify CPU virtualization support)

**Manual fix**:
```bash
# Check KVM availability
lsmod | grep kvm

# Try starting with detailed logs
incus start haos --debug
```

### Home Assistant Not Accessible

**Verify VM is running**:
```bash
incus list
# Status should be "RUNNING"
```

**Check VM IP address**:
```bash
incus list
# Check eth0 IP address
```

**If VM has no IPv4 address** (only IPv6 on internal network):

This means the default profile is using `incusbr0` instead of `br-wan`. Fix it:
```bash
# Stop the VM
incus stop haos

# Fix the default profile to use br-wan
incus profile device remove default eth0
incus profile device add default eth0 nic nictype=bridged parent=br-wan

# Remove eth1 if it exists (no longer needed)
incus config device remove haos eth1 2>/dev/null || true

# Start the VM
incus start haos

# Wait 30-60 seconds, then check
incus list
# Should now show IPv4 address on eth0
```

**Ping VM from Raspberry Pi**:
```bash
ping <haos-ip>
```

**Check HAOS VM logs**:
```bash
incus console haos
# Press Ctrl+C to interrupt if needed
# Check for boot errors
```

### Zigbee Dongle Not Working

**Check if USB device is passed through**:
```bash
incus config device show haos

# Should show zigbee-dongle device
```

**Manual passthrough**:
```bash
# List USB devices on host
lsusb

# Add USB device (example for TI CC2652)
incus config device add haos zigbee-dongle usb \
    vendorid=0451 \
    productid=16a8

# Restart HAOS VM
incus restart haos
```

**Verify in Home Assistant**:
1. Settings → System → Hardware
2. Check for `/dev/ttyUSB0` or `/dev/ttyACM0`

### First Boot Not Completing

**Check services-first-boot logs**:
```bash
# SSH into Raspberry Pi
ssh pi@<raspberry-pi-ip>

# Check service status
systemctl status services-first-boot.service

# View full logs
journalctl -u services-first-boot.service -n 100
```

**Common issues**:
- No internet connectivity (HAOS download requires internet)
- Insufficient disk space (check with `df -h`)
- DHCP not available on br-wan

**Manual HAOS deployment**:
```bash
# If first-boot failed, you can manually deploy HAOS:
cd /tmp
wget https://github.com/home-assistant/operating-system/releases/download/16.3/haos_generic-aarch64-16.3.qcow2.xz
unxz haos_generic-aarch64-16.3.qcow2.xz

# Create metadata
cat > metadata.yaml << EOF
architecture: aarch64
creation_date: $(date +%s)
properties:
  description: Home Assistant OS 16.3 ARM64
  os: haos
  release: "16.3"
EOF

# Import image
tar -czf metadata.tar.gz metadata.yaml
incus image import metadata.tar.gz haos_generic-aarch64-16.3.qcow2 --alias haos-aarch64-16.3

# Create and configure VM
incus init haos-aarch64-16.3 haos --vm
incus config set haos limits.cpu=2
incus config set haos limits.memory=4GB
incus config device override haos root size=24GB
# Note: eth0 is already on br-wan via default profile
incus config set haos boot.autostart=true
incus start haos
```

### Incus Web UI Issues

See [RaspiVirt-Incus Troubleshooting](Image-RaspiVirt-Incus#troubleshooting).

## Performance Tips

### Optimize for Home Assistant

**Recommended Hardware**:
- **Raspberry Pi 5** (best performance)
- **Raspberry Pi 4** (4GB or 8GB RAM)
- **Fast Storage**: SSD via USB 3.0 or NVMe (PCIe on Pi 5)

**Resource Allocation**:
```bash
# For larger Home Assistant installations (many integrations)
incus config set haos limits.memory=8GB
incus config set haos limits.cpu=4

# Restart to apply
incus restart haos
```

**Storage Performance**:
- Use SSD instead of SD card
- Enable TRIM for SSDs
- Use ZFS storage pool in Incus (optional, advanced)

### Monitor Resources

```bash
# Check overall Raspberry Pi resources
htop

# Check Incus resource usage
incus info --resources

# Check HAOS VM resource usage
incus info haos --resources

# Monitor in real-time
watch -n 1 'incus info haos --resources'
```

## Customization

### Modifying HAOS Version

Edit `images/raspivirt-incus+haos/setupfiles/services-first-boot.sh:67-68`:
```bash
# Change version
wget https://github.com/home-assistant/operating-system/releases/download/17.0/haos_generic-aarch64-17.0.qcow2.xz
unxz haos_generic-aarch64-17.0.qcow2.xz

# Update metadata
cat << EOF > metadata.yaml
architecture: aarch64
creation_date: $(date +%s)
properties:
  description: Home Assistant OS 17.0 ARM64
  os: haos
  release: "17.0"
EOF
```

### Changing VM Resources

Edit `images/raspivirt-incus+haos/setupfiles/services-first-boot.sh:88-91`:
```bash
# Increase resources
incus config set haos limits.cpu=4        # 4 cores instead of 2
incus config set haos limits.memory=8GB   # 8GB instead of 4GB
incus config device override haos root size=32GB  # 32GB instead of 24GB
```

### Adding Custom Integrations

After first boot:
1. SSH into Raspberry Pi
2. Access HAOS terminal:
   ```bash
   incus console haos
   # Login as root (no password)
   ```
3. Install custom integrations via HACS or manual install
4. Create snapshots before major changes

## Related Documentation

- **[Home](Home)**: Project overview
- **[RaspiVirt-Incus](Image-RaspiVirt-Incus)**: Base image documentation
- **[RaspiVirt-Incus+Docker](Image-RaspiVirt-Incus-Docker)**: Incus + Docker image
- **[GitHub Actions](GitHub-Actions)**: Automated build system
- **[Home Assistant Documentation](https://www.home-assistant.io/docs/)**: Official HAOS docs
- **[Incus Documentation](https://linuxcontainers.org/incus/docs/latest/)**: Official Incus docs

## Build Information

**GitHub Actions Workflow**: Automatically builds this image on push and daily schedule

**Build Process**:
1. Download Raspberry Pi OS and Debian base images
2. Execute `setup.sh` in QEMU ARM64
3. Install RaspiOS kernel, Incus, and KVM via APT
4. Configure first-boot services (including HAOS deployment)
5. Merge boot partition and rootfs
6. Compress with PiShrink

**Download**: [Latest Release](../../releases)

**Build Logs**: [GitHub Actions](../../actions)

## Frequently Asked Questions

### Can I run other VMs alongside HAOS?

Yes! This is a full Incus virtualization platform. You can run multiple VMs:

```bash
# Launch additional VMs
incus launch images:ubuntu/22.04 ubuntu-vm --vm
incus launch images:debian/13 debian-vm --vm
```

### Can I use Zigbee2MQTT instead of ZHA?

Yes! Install Zigbee2MQTT as a Home Assistant add-on:
1. Navigate to **Settings → Add-ons**
2. Click **Add-on Store**
3. Search for **Zigbee2MQTT**
4. Install and configure

### How much RAM does HAOS need?

- **Minimum**: 2GB (basic setup)
- **Recommended**: 4GB (default)
- **Optimal**: 8GB (many integrations)

Adjust via: `incus config set haos limits.memory=8GB`

### Can I migrate an existing Home Assistant installation?

Yes! Two methods:

**Method 1: Backup and Restore**
1. Create backup in your existing HAOS
2. Access new HAOS VM
3. Restore backup from Settings → System → Backups

**Method 2: Disk Migration**
1. Export existing HAOS disk
2. Import into Incus
3. Create VM from imported image

### How do I update Home Assistant?

Home Assistant updates itself automatically:
1. Navigate to **Settings → System → Updates**
2. Install available updates
3. VM will restart automatically

### Can I access the Raspberry Pi host while HAOS is running?

Yes! The host system runs independently:
- SSH access: `ssh pi@<raspberry-pi-ip>`
- Incus Web UI: `https://<raspberry-pi-ip>:8443`
- HAOS runs in isolated VM

### What happens if I need to reboot the Raspberry Pi?

HAOS VM is configured with `boot.autostart=true`:
1. Raspberry Pi boots
2. Incus starts automatically
3. HAOS VM starts automatically
4. Home Assistant becomes available within 2-3 minutes