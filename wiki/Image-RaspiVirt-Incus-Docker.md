# RaspiVirt-Incus+Docker Image

**RaspiVirt-Incus+Docker** extends the [RaspiVirt-Incus](Image-RaspiVirt-Incus) image by adding **Docker** container support alongside Incus. This image provides the best of both worlds: Incus for system containers and VMs, plus Docker for application containers with Docker Compose and the full Docker ecosystem.

## Overview

This image combines two powerful containerization platforms:
- **Incus** - System containers (LXC) and virtual machines (KVM)
- **Docker** - Application containers with OCI compatibility

Additionally, the image includes:
- **Portainer** - Web-based Docker management UI
- **Watchtower** - Automatic Docker container updates

### Key Features

All features from [RaspiVirt-Incus](Image-RaspiVirt-Incus) and:
- **Docker Engine** - Latest Docker CE with containerd
- **Docker Compose** - Multi-container application orchestration (plugin v2)
- **Docker Buildx** - Advanced build features and multi-platform support
- **Portainer CE** - Web UI for Docker management (port 9443)
- **Watchtower** - Automatic container image updates (daily at 4 AM)
- **Dual Container Ecosystems** - Choose the right tool for each workload

## Image Specifications

- **Image Name**: `rpi-raspivirt-incus+docker.img.xz`
- **Base OS**: Debian 13 (Trixie) ARM64
- **Kernel**: Raspberry Pi OS kernel (with RP1 drivers)
- **Image Size**: ~2.5 GB (expands on first boot)
- **Compressed Size**: ~700MB (xz compressed)

### Build Configuration

From `images/raspivirt-incus+docker/config.sh`:
```bash
OUTPUT_IMAGE="rpi-raspivirt-incus+docker.img"
IMAGE_SIZE="4G"
QEMU_RAM="8G"
QEMU_CPUS="4"
DESCRIPTION="Raspberry Pi image with Incus, KVM virtualization and br-wan bridge"
```

## Installed Software

All packages from [RaspiVirt-Incus](Image-RaspiVirt-Incus) and:

### Docker Stack
- **Docker CE** (`docker-ce`) - Docker Engine
- **Docker CLI** (`docker-ce-cli`) - Docker command-line interface
- **containerd** (`containerd.io`) - Container runtime
- **Docker Buildx** (`docker-buildx-plugin`) - Extended build capabilities
- **Docker Compose** (`docker-compose-plugin`) - Multi-container orchestration

### Pre-Installed Containers

#### Portainer CE (Latest LTS)
- **Purpose**: Web-based Docker management
- **Port**: 9443 (HTTPS), 8000 (Tunnel)
- **Volume**: `portainer_data`
- **Auto-start**: Yes
- **Image**: `portainer/portainer-ce:lts`

#### Watchtower
- **Purpose**: Automatic container updates
- **Schedule**: Daily at 4:00 AM
- **Monitors**: All containers
- **Auto-start**: Yes
- **Image**: `containrrr/watchtower`

## Docker Configuration

### User Permissions

The `pi` user is added to the `docker` group during setup:
```bash
usermod -aG docker pi
```

This allows running Docker commands without `sudo`:
```bash
# No sudo needed
docker ps
docker run hello-world
```

### Docker Daemon Configuration

Override file created at `/etc/systemd/system/docker.service.d/override.conf`:
```ini
[Service]
Environment=DOCKER_MIN_API_VERSION=1.25
```

This ensures compatibility with older Docker clients while maintaining security.

### Docker Repository

Official Docker repository configured at `/etc/apt/sources.list.d/docker.sources`:
```
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
```

Enables easy updates:
```bash
sudo apt update
sudo apt upgrade docker-ce docker-ce-cli containerd.io
```

## First-Boot Process

Extends the [RaspiVirt-Incus first-boot process](Image-RaspiVirt-Incus#first-boot-process) with Docker initialization.

### Stage 1: rpi-first-boot (Before Network)

Identical to RaspiVirt-Incus:
1. Enable classic network names (`eth0`)
2. Disable cloud-init networking
3. Resize root partition
4. Deploy netplan configuration
5. Reboot

### Stage 2: services-first-boot (After Network)

Enhanced to include Docker initialization:

**Script**: `/usr/local/bin/services-first-boot.sh`

**Actions**:
1. **Wait for internet connectivity** (5 minute timeout)
2. **Initialize Incus**:
   - Minimal init + web UI on :8443
   - Create `br-wan` network
   - Attach to default profile
3. **Initialize Docker containers**:
   - Create Portainer with persistent volume
   - Create Watchtower with daily schedule
4. **Self-destruct**

## Pre-Installed Containers

### Portainer CE

Portainer provides a comprehensive web UI for Docker management.

#### Access Portainer

1. Get Raspberry Pi IP: `ip addr show br-wan`
2. Open browser: `https://<raspberry-pi-ip>:9443`
3. Accept self-signed certificate
4. Create admin account on first login

#### Portainer Features

- **Container Management**: Start, stop, restart, delete containers
- **Image Management**: Pull, build, push images
- **Volume Management**: Create and manage volumes
- **Network Management**: Create and configure networks
- **Docker Compose**: Deploy stacks from compose files
- **Console Access**: Access container shells via web
- **Resource Monitoring**: CPU, memory, network usage
- **User Management**: Multi-user access with RBAC

#### Portainer Configuration

```bash
# Container details
docker inspect portainer

# Ports:
#   8000 -> Tunnel server
#   9443 -> HTTPS web UI

# Volumes:
#   /var/run/docker.sock -> Docker API access
#   portainer_data -> Persistent configuration

# Restart policy: always
```

### Watchtower

Watchtower automatically updates running Docker containers.

#### How Watchtower Works

1. Checks for new image versions daily at 4:00 AM
2. Pulls new images if available
3. Stops old containers gracefully
4. Starts new containers with same configuration
5. Cleans up old images

#### Watchtower Configuration

```bash
# Container details
docker inspect watchtower

# Environment:
#   WATCHTOWER_SCHEDULE: "0 0 4 * * *" (4:00 AM daily)

# Monitored containers:
#   All containers except those with label "hidden=true"
#   (Portainer and Watchtower are hidden)

# Restart policy: always
```

#### Controlling Watchtower

```bash
# Update all containers immediately
docker restart watchtower

# Exclude a container from updates
docker run -d --label com.centurylinklabs.watchtower.enable=false myimage

# View Watchtower logs
docker logs watchtower
```

## Docker Usage Examples

### Basic Commands

```bash
# Check Docker version
docker --version

# Check running containers
docker ps

# Check all containers (including stopped)
docker ps -a

# Pull an image
docker pull nginx:alpine

# Run a simple container
docker run -d -p 80:80 nginx:alpine

# View container logs
docker logs <container-id>

# Execute command in container
docker exec -it <container-id> bash

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>
```

### Docker Compose Example

Create a `docker-compose.yml` file:
```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: unless-stopped

  redis:
    image: redis:alpine
    restart: unless-stopped
```

Deploy the stack:
```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Common Applications

#### Web Server (Nginx)
```bash
docker run -d \
  --name nginx \
  -p 80:80 \
  -v /home/pi/www:/usr/share/nginx/html:ro \
  --restart unless-stopped \
  nginx:alpine
```

#### Database (PostgreSQL)
```bash
docker run -d \
  --name postgres \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=secretpassword \
  -v postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:alpine
```

#### Home Assistant
```bash
docker run -d \
  --name homeassistant \
  --privileged \
  --network host \
  -v /home/pi/homeassistant:/config \
  -e TZ=Europe/Paris \
  --restart unless-stopped \
  homeassistant/home-assistant:stable
```

#### Pi-hole (DNS + Ad Blocker)
```bash
docker run -d \
  --name pihole \
  -p 53:53/tcp -p 53:53/udp \
  -p 8080:80 \
  -e TZ=Europe/Paris \
  -e WEBPASSWORD=admin \
  -v pihole_etc:/etc/pihole \
  -v pihole_dnsmasq:/etc/dnsmasq.d \
  --restart unless-stopped \
  pihole/pihole:latest
```

## Incus + Docker Integration

### When to Use Incus vs Docker

#### Use Incus For:
- **System containers**: Full OS environments with systemd
- **Virtual machines**: When you need kernel isolation
- **Long-lived environments**: Development VMs, staging servers
- **Multi-distribution testing**: Run different Linux distros
- **Network isolation**: Complex network topologies

#### Use Docker For:
- **Application containers**: Stateless microservices
- **Docker Compose stacks**: Multi-container applications
- **CI/CD**: Build and test pipelines
- **Pre-built images**: Leveraging Docker Hub ecosystem
- **Lightweight services**: Single-purpose containers

### Shared Networking

Both Incus and Docker containers can use the `br-wan` bridge:
- **Incus containers**: Automatically use `br-wan` via default profile
- **Docker containers**: Use host network mode for direct bridge access

```bash
# Docker container on host network (uses br-wan)
docker run -d --network host nginx:alpine
```

## Network Configuration

### Bridge Topology

```
Internet
    ↓
Your Router (DHCP)
    ↓
┌─────────────────────────────────────────┐
│  Raspberry Pi                           │
│  ┌───────────────────────────────────┐  │
│  │  br-wan (Bridge)                  │  │ ← Gets IP from router
│  │   ├─ eth0 (Physical NIC)         │  │
│  │   ├─ Incus Container 1            │  │ ← Gets IP from router
│  │   ├─ Incus VM 1                   │  │ ← Gets IP from router
│  │   └─ Docker (host network mode)   │  │ ← Uses br-wan IP
│  └───────────────────────────────────┘  │
│                                          │
│  Docker (bridge network)                │
│  ┌───────────────────────────────────┐  │
│  │  docker0 (172.17.0.0/16)          │  │
│  │   ├─ Portainer                    │  │ ← Internal Docker network
│  │   ├─ Watchtower                   │  │ ← Internal Docker network
│  │   └─ Your containers              │  │ ← NAT to br-wan
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### Accessing Services

- **Incus Web UI**: `https://<pi-ip>:8443`
- **Portainer**: `https://<pi-ip>:9443`
- **Docker containers with published ports**: `http://<pi-ip>:<port>`
- **Incus containers**: Direct access via DHCP-assigned IPs

## Use Cases

All use cases from [RaspiVirt-Incus](Image-RaspiVirt-Incus#use-cases) plus:

### Docker-Specific Use Cases

#### Microservices Platform
- Deploy microservices with Docker Compose
- Use Incus for database VMs
- Portainer for central management

#### Home Automation Hub
- Home Assistant in Docker
- Node-RED for automation
- MQTT broker for IoT
- InfluxDB + Grafana for monitoring

#### Media Server
- Jellyfin/Plex in Docker
- Sonarr/Radarr for content management
- Transmission for downloads
- Storage in Incus container/VM

#### Development Environment
- Application containers in Docker
- Database/services in Incus containers
- Isolated environments for each project

## Customization

Same customization options as [RaspiVirt-Incus](Image-RaspiVirt-Incus#customization) plus:

### Modify Pre-Installed Containers

Edit `setupfiles/services-first-boot.sh` to change Portainer/Watchtower configuration:

```bash
# Example: Change Portainer to port 9000
docker run -d \
    -p 8000:8000 -p 9000:9000 \
    --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:lts
```

### Add Additional Pre-Installed Containers

Add to `services-first-boot.sh` before the "Disable this service" section:

```bash
# Create your custom container
echo "  Creating custom container..."
docker run -d \
    --name myapp \
    -p 8080:8080 \
    --restart=always \
    myimage:latest
```

### Disable Portainer or Watchtower

Comment out the respective sections in `services-first-boot.sh`:

```bash
# # Create Portainer
# echo "  Creating Portainer container..."
# docker volume create portainer_data
# ...
```

## System Resources

### Resource Recommendations

For optimal performance with both Incus and Docker:

- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 32GB minimum, 64GB+ recommended
- **CPU**: Raspberry Pi 4 (4GB+) or Raspberry Pi 5

### Monitoring Resources

```bash
# System resources
htop

# Docker stats (real-time)
docker stats

# Incus resource usage
incus info --resources

# Disk usage
df -h
du -sh /var/lib/docker
du -sh /var/lib/incus
```

### Resource Limits

Limit container resources to prevent overconsumption:

```bash
# Docker: Limit container to 1GB RAM, 1 CPU
docker run -d \
  --memory=1g \
  --cpus=1 \
  nginx:alpine

# Incus: Limit container to 2GB RAM, 2 CPUs
incus launch images:debian/13 limited \
  -c limits.memory=2GB \
  -c limits.cpu=2
```

## Troubleshooting

### Portainer Not Accessible

**Check container status**:
```bash
docker ps | grep portainer
```

**View logs**:
```bash
docker logs portainer
```

**Restart Portainer**:
```bash
docker restart portainer
```

### Watchtower Not Updating Containers

**Check schedule**:
```bash
docker inspect watchtower | grep WATCHTOWER_SCHEDULE
```

**View logs**:
```bash
docker logs watchtower
```

**Force update**:
```bash
# Trigger immediate update
docker restart watchtower
```

### Docker Daemon Not Starting

**Check status**:
```bash
sudo systemctl status docker
```

**View logs**:
```bash
sudo journalctl -u docker -n 50
```

**Restart Docker**:
```bash
sudo systemctl restart docker
```

### Permission Denied Errors

**Verify user in docker group**:
```bash
groups pi
# Should include: pi sudo kvm incus incus-admin docker
```

**Re-login** if group membership was just added:
```bash
# Logout and login again, or:
newgrp docker
```

### Disk Space Issues

**Check Docker disk usage**:
```bash
docker system df
```

**Clean up unused resources**:
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove everything unused
docker system prune -a --volumes
```

## Security Considerations

### Docker Security

- **Change Portainer password** immediately after first login
- **Use secrets** for sensitive data (passwords, API keys)
- **Limit exposed ports** to only what's necessary
- **Use official images** from Docker Hub
- **Keep images updated** (Watchtower helps with this)
- **Avoid running privileged containers** unless required

### Network Security

- **Firewall**: Consider using ufw to restrict access
- **HTTPS**: Use reverse proxy (Traefik, Nginx) for HTTPS
- **VPN**: Access services via VPN instead of exposing to internet

### Example: UFW Firewall

```bash
# Install UFW
sudo apt install ufw

# Allow SSH
sudo ufw allow 22/tcp

# Allow Incus and Portainer locally only
sudo ufw allow from 192.168.1.0/24 to any port 8443 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 9443 proto tcp

# Enable firewall
sudo ufw enable
```

## Performance Optimization

### Docker Best Practices

- Use **Alpine-based images** for smaller footprint
- Use **multi-stage builds** for efficient images
- Use **volume mounts** instead of copying large files
- Use **Docker Compose** for complex applications
- Use **health checks** for automatic restarts

### Storage Optimization

```bash
# Use overlay2 storage driver (default)
docker info | grep "Storage Driver"

# Limit log size per container
docker run -d \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  nginx:alpine
```

## Package Updates

Update both Debian/RaspiOS packages and Docker:

```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Update Docker Engine
sudo apt install --only-upgrade \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Update Incus
sudo apt install --only-upgrade incus incus-ui-canonical

# Update containers (Watchtower does this automatically)
docker images | grep -v REPOSITORY | awk '{print $1}' | xargs -L1 docker pull
```

## Related Documentation

- **[Home](Home)**: Project overview
- **[GitHub Actions](GitHub-Actions)**: Automated build system
- **[RaspiVirt-Incus](Image-RaspiVirt-Incus)**: Base image documentation
- **[Docker Documentation](https://docs.docker.com/)**: Official Docker docs
- **[Portainer Documentation](https://docs.portainer.io/)**: Portainer user guide
- **[Docker Compose Documentation](https://docs.docker.com/compose/)**: Compose reference

## Build Information

**GitHub Actions Workflow**: Automatically builds this image on push and daily schedule

**Differences from RaspiVirt-Incus**:
- Adds Docker CE + plugins
- Adds Portainer and Watchtower containers
- Enhanced services-first-boot script

**Download**: [Latest Release](../../releases)

**Build Logs**: [GitHub Actions](../../actions)