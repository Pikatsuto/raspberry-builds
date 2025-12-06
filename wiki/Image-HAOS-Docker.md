# HAOS+Docker Images

**HAOS+Docker images** combine Home Assistant OS virtualization with Docker containerization, providing a complete home automation and container platform on Raspberry Pi. These images extend the base HAOS images with Docker Engine, Portainer, and Watchtower.

## Overview

HAOS+Docker images provide:
- **Incus** for Home Assistant OS VM
- **Docker Engine** for containerized applications
- **Portainer** for Docker management via web UI
- **Watchtower** for automatic container updates
- **Zigbee USB passthrough** to Home Assistant VM
- **Dual networking**: br-wan for WAN, optional br-lan for LAN

## Available HAOS+Docker Images

### 1. RaspiVirt-Incus+HAOS+Docker
**Image**: `rpi-raspivirt-qemu+haos+docker.img`

Complete home automation platform with Docker:
- Incus with Home Assistant OS VM
- Docker Engine with Portainer (port 9443)
- Watchtower for automatic container updates
- Zigbee/Z-Wave USB dongle auto-passthrough
- Bridged networking (br-wan + optional br-lan)

```bash
./bin/autobuild --image raspivirt-qemu+haos+docker
```

**Use cases**:
- Run Home Assistant for home automation
- Run additional services in Docker containers
- Separate HAOS VM from other applications
- Unified management platform

### 2. RaspiVirt-Incus+HAOS+Docker+Hotspot
**Image**: `rpi-raspivirt-qemu+haos+docker+hotspot.img`

All-in-one home automation with WiFi hotspot:
- Everything from HAOS+Docker
- WiFi Access Point (5GHz or dual-band)
- WiFi clients can access HAOS and containers
- Complete standalone solution

```bash
./bin/autobuild --image raspivirt-qemu+haos+docker+hotspot
```

**Use cases**:
- Home automation hub with WiFi
- IoT gateway with WiFi access point
- Standalone home automation server
- WiFi-enabled smart home controller

## Image Specifications

### RaspiVirt-Incus+HAOS+Docker
- **Image Name**: `rpi-raspivirt-qemu+haos+docker.img.xz`
- **Base OS**: Debian 13 (Trixie) ARM64
- **Kernel**: Raspberry Pi OS kernel (with RP1 drivers)
- **Image Size**: ~2 GB (expands on first boot)
- **Compressed Size**: ~700MB (xz compressed)

### RaspiVirt-Incus+HAOS+Docker+Hotspot
- **Image Name**: `rpi-raspivirt-qemu+haos+docker+hotspot.img.xz`
- **Same specifications as above + WiFi hotspot**

## Installed Software

### All software from base HAOS image, plus:

### Docker Stack
- **docker-ce** - Docker Community Edition
- **docker-ce-cli** - Docker command-line interface
- **containerd.io** - Container runtime
- **docker-buildx-plugin** - Docker build extension
- **docker-compose-plugin** - Docker Compose V2

### Pre-installed Containers
- **Portainer CE** (latest LTS)
  - Web UI for Docker management
  - Port: 9443 (HTTPS)
  - Volume: `portainer_data`
  - Auto-restart enabled

- **Watchtower**
  - Automatic container updates
  - Schedule: Daily at 4:00 AM
  - Monitors all containers
  - Auto-restart enabled

### WiFi Support (Hotspot variant only)
- **NetworkManager** - Network management
- **hostapd** - WiFi Access Point daemon
- Automatic dual-band configuration

## Docker Configuration

### Docker Daemon Configuration

The Docker daemon is configured with:
- **Min API Version**: 1.25 (for compatibility)
- **Bridge network**: docker0
- **Storage driver**: overlay2
- **Log driver**: json-file

Configuration file: `/etc/systemd/system/docker.service.d/override.conf`

### User Configuration

The `pi` user is automatically added to the `docker` group:
```bash
# Run Docker commands without sudo
docker ps
docker run hello-world
```

### Pre-installed Containers

#### Portainer CE
```bash
# Access Portainer
https://<raspberry-pi-ip>:9443

# Default credentials: Set on first login
# Manages: Containers, images, volumes, networks
```

**Container details**:
- **Name**: portainer
- **Image**: portainer/portainer-ce:lts
- **Ports**: 8000 (HTTP), 9443 (HTTPS)
- **Volumes**:
  - `/var/run/docker.sock:/var/run/docker.sock` (Docker API)
  - `portainer_data:/data` (Persistent storage)
- **Restart**: always
- **Label**: `hidden=true` (hidden from Portainer container list)

#### Watchtower
```bash
# View Watchtower logs
docker logs watchtower

# Check for updates manually
docker restart watchtower
```

**Container details**:
- **Name**: watchtower
- **Image**: containrrr/watchtower
- **Schedule**: `0 0 4 * * *` (Daily at 4:00 AM)
- **Restart**: always
- **Label**: `hidden=true`

### Docker Networks

Docker containers can use:
1. **docker0** (default bridge) - Container-to-container
2. **br-wan** - Direct LAN access via Incus network
3. **br-lan** - Local LAN access (if eth1 present)

**Example: Container on br-wan**:
```bash
# Connect container to br-wan via Incus network
docker network create \
  --driver bridge \
  --opt com.docker.network.bridge.name=incus-br-wan \
  incus-br-wan
```

## Home Assistant OS VM

### Pre-configured VM
The Home Assistant OS VM is automatically created on first boot:
- **Name**: haos
- **Type**: Virtual machine (KVM)
- **OS**: Home Assistant OS (latest)
- **Resources**:
  - CPU: 2 cores
  - RAM: 2 GB
  - Disk: 32 GB
- **Network**: br-wan (gets IP from router)

### Accessing Home Assistant

1. **Wait for VM to boot** (~2-3 minutes)
2. **Find VM IP address**:
   ```bash
   incus list
   # Look for "haos" VM IP
   ```
3. **Access Home Assistant**:
   ```
   http://<haos-vm-ip>:8123
   ```

### USB Passthrough

Zigbee/Z-Wave USB dongles are automatically passed through to the HAOS VM:

**Supported devices**:
- Sonoff Zigbee dongles
- ConBee/RaspBee
- Aeotec Z-Wave
- Nortek HUSBZB-1
- Generic USB serial adapters

**Detection script**: `/usr/local/bin/haos-usb-passthrough.sh`

The script automatically:
1. Detects USB dongles (VID:PID matching)
2. Passes them to HAOS VM via Incus
3. Monitors for new devices

**Manual passthrough**:
```bash
# List USB devices
lsusb

# Pass device to VM
incus config device add haos zigbee usb \
  vendorid=1a86 \
  productid=7523
```

## Combining Docker and Incus

### Use Case: HAOS + Additional Services

Run Home Assistant in Incus VM while running supporting services in Docker:

```bash
# HAOS VM for home automation
incus list  # haos VM running

# Docker containers for additional services
docker run -d --name mqtt mosquitto
docker run -d --name influxdb influxdb
docker run -d --name grafana grafana/grafana
```

**Advantages**:
- **HAOS VM isolation**: Full OS for Home Assistant
- **Docker flexibility**: Quick deployment of supporting services
- **Resource efficiency**: Docker for lightweight services
- **Easy management**: Portainer for Docker, Incus UI for VMs

### Container Communication with HAOS

Docker containers can communicate with HAOS VM via:

1. **Direct IP** (if on same network):
   ```yaml
   # In Docker container config
   mqtt_broker: <haos-vm-ip>:1883
   ```

2. **Docker bridge + port mapping**:
   ```bash
   # Expose HAOS service to Docker network
   docker run -d \
     --add-host=haos:<haos-vm-ip> \
     mycontainer
   ```

## Service Management

### Docker Services

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# View Docker logs
sudo journalctl -u docker -f

# Check containerd
sudo systemctl status containerd
```

### Container Management

```bash
# List containers
docker ps -a

# View container logs
docker logs -f portainer
docker logs -f watchtower

# Restart containers
docker restart portainer
docker restart watchtower

# Remove and recreate
docker rm -f portainer
docker run -d \
  -p 8000:8000 -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts
```

### Watchtower Configuration

```bash
# Change update schedule (edit container)
docker rm -f watchtower
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e WATCHTOWER_SCHEDULE="0 0 2 * * *" \  # 2:00 AM
  --restart always \
  containrrr/watchtower

# Disable auto-updates for specific container
docker run -d \
  --label com.centurylinklabs.watchtower.enable=false \
  mycontainer
```

## First-Boot Process

The first-boot process includes all stages from base HAOS image plus Docker initialization:

### Stage 1: rpi-first-boot
1. Enable classic network names (eth0, wlan0)
2. Disable cloud-init networking
3. Resize root partition
4. Reboot

### Stage 2: services-first-boot
1. **Configure network bridges**:
   - Create br-wan (always)
   - Create br-lan (if eth1 exists)
   - Configure DHCP/DNS for br-lan (if WiFi hotspot)
2. **Configure WiFi** (hotspot variant only):
   - Detect wlan0/wlan1
   - Configure hostapd
   - Start WiFi Access Point
3. **Initialize Incus**:
   - Minimal initialization
   - Configure networks (br-wan, br-lan)
   - Set up default profile
4. **Initialize Docker containers**:
   - Create Portainer volume
   - Start Portainer container
   - Start Watchtower container
5. **Deploy Home Assistant OS VM**:
   - Download HAOS image
   - Create VM with 2GB RAM, 2 CPUs
   - Configure USB passthrough
   - Start VM
6. Self-destruct

## Network Architecture

### Standard (no WiFi hotspot)

```
Internet
    ↓
  Router ←─ eth0 (br-wan)
    ↓
┌─────────────────────────────────┐
│  Raspberry Pi                   │
│  ┌───────────────────────────┐  │
│  │  br-wan Bridge            │  │
│  │   ├─ Docker containers    │  │ ← Get IPs from router
│  │   └─ HAOS VM              │  │ ← Gets IP from router
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### With WiFi Hotspot + br-lan

```
Internet
    ↓
  Router ←─ eth0 (br-wan)
    ↓
┌──────────────────────────────────────┐
│  Raspberry Pi                        │
│  ┌────────────────────────────────┐  │
│  │  br-lan (LAN + WiFi)           │  │
│  │   ├─ eth1 (LAN port)           │  │
│  │   ├─ wlan0/wlan1 (WiFi)        │  │ ← WiFi clients (192.168.10.x)
│  │   ├─ Docker containers         │  │
│  │   └─ HAOS VM                   │  │
│  └────────────────────────────────┘  │
│                                      │
│  br-wan: WAN connectivity            │
└──────────────────────────────────────┘
```

## Accessing Services

### Service Ports

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| Home Assistant | 8123 | HTTP | http://\<haos-ip\>:8123 |
| Portainer | 9443 | HTTPS | https://\<rpi-ip\>:9443 |
| Portainer Agent | 8000 | HTTP | Internal only |
| Incus UI | 8443 | HTTPS | https://\<rpi-ip\>:8443 |

### URLs
```
# Home Assistant
http://<haos-vm-ip>:8123

# Portainer (Docker management)
https://<raspberry-pi-ip>:9443

# Incus UI (VM/container management)
https://<raspberry-pi-ip>:8443
```

## Use Cases

### Complete Home Automation Hub
- **HAOS VM**: Home Assistant with Zigbee/Z-Wave
- **Docker containers**:
  - MQTT broker (Mosquitto)
  - Database (InfluxDB)
  - Visualization (Grafana)
  - Node-RED for automation

### IoT Gateway with WiFi
- **HAOS**: Central home automation
- **WiFi hotspot**: Connect IoT devices
- **Docker**: Additional services (MQTT, database)
- **Isolated network**: br-lan for IoT devices

### Development Environment
- **HAOS**: Production home automation
- **Docker**: Development containers
- **Incus**: Test VMs
- **Portainer**: Easy container management

### Media + Automation
- **HAOS**: Home automation
- **Docker containers**:
  - Plex/Jellyfin media server
  - Download clients
  - File sharing
- **Incus**: Additional services in VMs

## Troubleshooting

### Portainer Not Accessible

**Check container**:
```bash
docker ps | grep portainer
```

**Check logs**:
```bash
docker logs portainer
```

**Restart Portainer**:
```bash
docker restart portainer
```

### Watchtower Not Updating

**Check Watchtower logs**:
```bash
docker logs watchtower
```

**Force update check**:
```bash
docker restart watchtower
```

**Common issues**:
- Internet connectivity required
- Rate limits on Docker Hub
- Container labels preventing updates

### Docker Daemon Issues

**Check Docker status**:
```bash
sudo systemctl status docker
sudo journalctl -u docker -n 50
```

**Restart Docker**:
```bash
sudo systemctl restart docker
```

**Check disk space**:
```bash
df -h
docker system df  # Docker disk usage
```

### HAOS VM + Docker Conflicts

**Resource contention**:
```bash
# Check CPU usage
htop

# Check memory
free -h

# Adjust HAOS VM resources
incus config set haos limits.memory=1GB
incus config set haos limits.cpu=1
```

## Performance Optimization

### Docker Performance
```bash
# Clean up unused images/containers
docker system prune -a

# Limit container resources
docker run -d \
  --memory="512m" \
  --cpus="0.5" \
  mycontainer
```

### Combined Workload
- **HAOS VM**: 2GB RAM minimum for good performance
- **Docker**: 1GB RAM for containers
- **System**: 512MB minimum
- **Total**: 4GB RAM recommended minimum

### Storage Optimization
```bash
# Move Docker data to USB SSD
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/usb-ssd/docker
sudo ln -s /mnt/usb-ssd/docker /var/lib/docker
sudo systemctl start docker
```

## Security Recommendations

1. **Change Portainer admin password** on first login
2. **Use Portainer HTTPS** (9443) instead of HTTP (8000)
3. **Configure Docker socket access** carefully
4. **Regular updates** via Watchtower
5. **Network isolation** for sensitive containers
6. **HAOS authentication** configured in Home Assistant
7. **Change WiFi password** (hotspot variant)

## Related Documentation

- **[RaspiVirt-Incus+HAOS](Image-RaspiVirt-Incus-HAOS)**: Base HAOS image
- **[RaspiVirt-Incus+Docker](Image-RaspiVirt-Incus-Docker)**: Docker variant details
- **[WiFi Hotspot Images](Image-WiFi-Hotspot)**: WiFi configuration (hotspot variant)
- **[Portainer Documentation](https://docs.portainer.io/)**: Portainer docs
- **[Watchtower Documentation](https://containrrr.dev/watchtower/)**: Watchtower docs
- **[Docker Documentation](https://docs.docker.com/)**: Docker reference
- **[Home Assistant](https://www.home-assistant.io/)**: Home Assistant docs

## Build Information

**GitHub Actions Workflow**: Automatically builds these images on push and daily schedule

**Download**: [Latest Release](../../releases)

**Build Logs**: [GitHub Actions](../../actions)