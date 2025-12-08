# Frequently Asked Questions

## General Questions

### What is this project?

An automated build system for creating custom Raspberry Pi images with:
- Debian ARM64 userspace
- Raspberry Pi OS kernel and firmware
- Modular service composition
- Automatic hardware detection
- GitHub Actions CI/CD

### Why not use standard Raspberry Pi OS?

You should use standard RaspiOS if it meets your needs. Use this project if you want:
- Debian package ecosystem instead of RaspiOS customizations
- Modular service composition
- Version-controlled image configurations
- Automated builds and updates
- Custom base distributions (in development)

### Why not use standard Debian ARM64?

Standard Debian ARM64 lacks Raspberry Pi-specific drivers:
- RP1 chip drivers (Ethernet, USB, GPIO on Pi 5)
- Optimized WiFi/Bluetooth firmware
- Hardware acceleration
- Bootloader configuration

This project combines Debian with RaspiOS kernel/firmware for full hardware support.

---

## Build Questions

### How long does a build take?

**Typical build times**:
- Base image: 10-15 minutes
- With services: 15-30 minutes
- Full stack (all services): 30-45 minutes

**Factors**:
- Internet speed (downloading base images, packages)
- CPU speed (QEMU emulation)
- RAM available (QEMU VM performance)
- Disk speed (image operations)

### Can I build on macOS or Windows?

Not directly. The build system requires Linux for:
- Loop device support (partition mounting)
- QEMU ARM64 with KVM (optional but faster)
- ext4 filesystem tools

**Options**:
- Use WSL2 on Windows
- Use a Linux VM on macOS
- Use GitHub Actions (no local build needed)

### Why does QEMU use so much RAM?

QEMU allocates RAM for:
- Guest VM (QEMU_RAM, typically 4-8GB)
- Host overhead (1-2GB)
- Disk cache (varies)

**Reduce RAM usage**:
```bash
# In config.sh
QEMU_RAM="2G"  # Minimum for base builds
QEMU_CPUS="2"  # Reduce CPU count
```

**Note**: Lower RAM may cause build failures for images with many packages.

### Can I build multiple images in parallel?

Yes, but consider resources:

```bash
# Parallel builds
./bin/autobuild --image debian &
./bin/autobuild --image debian/qemu &
wait
```

**Requirements per build**:
- RAM: QEMU_RAM + 2GB overhead
- Disk: IMAGE_SIZE * 3 (source + output + temp)
- CPU: QEMU_CPUS cores

**Example**: 2 parallel builds with QEMU_RAM=4G requires 12GB total RAM.

### Why is PiShrink so slow?

PiShrink:
- Resizes ext4 filesystem
- Compresses with xz (CPU-intensive)
- Verifies integrity

**Speed up**:
```bash
# Skip PiShrink
./bin/autobuild --image debian --skip-compress

# Or use faster compression
xz -T0 -1 image.img  # Parallel, lower compression
```

---

## Hardware Questions

### Which Raspberry Pi models are supported?

**Supported**:
- Raspberry Pi 4 (all RAM variants)
- Raspberry Pi 5 (all RAM variants)

**Not supported**:
- Raspberry Pi 3 and earlier (32-bit ARM)
- Raspberry Pi Zero (32-bit, insufficient resources)
- Raspberry Pi Compute Module (untested)

**Reason**: This project uses ARM64 (64-bit) Debian. Pi 3 and earlier are 32-bit ARMv7.

### Do I need a specific SD card?

**Recommended**:
- Class 10 or better
- U1/U3 for video applications
- A1/A2 for better random I/O
- Reputable brands (SanDisk, Samsung, Kingston)

**Minimum size**:
- Base image: 8GB
- With services: 16GB
- Full stack: 32GB

**Avoid**:
- Generic/cheap cards (reliability issues)
- Cards older than 5 years (wear)

### Can I use USB SSD instead of SD card?

Yes! Benefits:
- Faster I/O
- Better reliability
- Longer lifespan

**Process**:
```bash
# Flash to USB SSD (same as SD card)
xz -dc image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress

# Boot from USB (Raspberry Pi 4/5 support USB boot)
```

**Raspberry Pi 5**: Native USB boot support
**Raspberry Pi 4**: Update bootloader for USB boot

### Does WiFi work out of the box?

Yes, with `firmware-brcm80211` package (included in base service).

**Supported adapters**:
- Built-in WiFi on Raspberry Pi 4/5
- Most USB WiFi adapters (Realtek, Atheros, etc.)

**Check compatibility**:
```bash
# After boot, check WiFi interface
ip link show wlan0

# Check firmware
dmesg | grep brcmfmac
```

### Does Bluetooth work?

Yes, Bluetooth firmware is included.

**Usage**:
```bash
# Check Bluetooth
bluetoothctl
scan on
```

**Pairing**:
- Use `bluetoothctl` CLI
- Or install GUI: `apt install blueman`

---

## Service Questions

### Can I run Home Assistant without Incus?

No. The `haos` service requires Incus to run Home Assistant OS as a VM.

**Alternative**: Use Home Assistant Container (Docker):
```bash
# Add to custom service
docker run -d --name homeassistant \
  -v /home/pi/homeassistant:/config \
  --network=host \
  ghcr.io/home-assistant/home-assistant:stable
```

### How much RAM do services need?

**Service RAM usage**:
- base: ~500MB
- docker: ~200MB + containers
- qemu (Incus): ~100MB + VMs/containers
- haos VM: 4GB (configurable)
- openwrt container: ~100MB
- hotspot: ~50MB

**Total for full stack**:
- Minimum: 4GB (Pi 5 8GB recommended)
- Comfortable: 8GB

### Can I disable a service after building?

Yes:

```bash
# Stop service
sudo systemctl stop service-name

# Disable service
sudo systemctl disable service-name

# Or remove completely
sudo apt remove package-name
```

**Example**: Disable Home Assistant:
```bash
sudo incus stop haos
sudo incus delete haos
```

### How do I add my own service?

See [Services - Creating Custom Services](Services/#creating-custom-services).

Quick version:
1. Create `images/debian/services/myservice/`
2. Add `setup.sh` (package installation)
3. Add `first-boot/init.sh` (runtime config)
4. Build: `./bin/autobuild --image debian/myservice`

---

## Network Questions

### What are br-wan and br-lan?

**Network bridges** for consistent service networking:

**br-wan** (always created):
- Connects to WAN (internet)
- DHCP client
- Attached to eth0

**br-lan** (created if eth1 exists):
- LAN for internal services
- DHCP server (192.168.10.0/24)
- NAT enabled
- Attached to eth1

**Why bridges?**
- Services attach to bridges, not physical interfaces
- Allows flexible network configuration
- Supports VMs/containers without network conflicts

### How do I use a single NIC?

It works automatically. If only eth0 detected:
- br-wan created (WAN)
- br-lan not created
- Services use br-wan

### How do I set static IP?

See [Configuration Reference - Static IP](Configuration-Reference/#static-ip).

### Can I use WiFi for WAN instead of Ethernet?

Yes, configure NetworkManager to bridge WiFi to br-wan:

```bash
# Connect WiFi
sudo nmcli dev wifi connect "SSID" password "PASSWORD"

# Bridge WiFi to br-wan (advanced - requires network downtime)
sudo nmcli con add type bridge con-name br-wan ifname br-wan
sudo nmcli con add type wifi slave-type bridge con-name wlan0 ifname wlan0 master br-wan ssid "SSID"
```

**Warning**: WiFi bridging may be unreliable. Ethernet recommended for WAN.

---

## Update Questions

### How do I update the system?

```bash
sudo apt update
sudo apt upgrade -y
```

This updates:
- Debian packages (from Debian repos)
- RaspiOS kernel/firmware (from RaspiOS repo)

### Will updates break hardware support?

No. APT pinning ensures RaspiOS kernel/firmware packages update from RaspiOS repository, maintaining hardware support.

**Pinning config**: `/etc/apt/preferences.d/raspi-pin`

### How do I update to a newer Debian version?

**Not recommended while Debian 13 (Trixie) is testing/unstable.**

When Debian 13 is stable:
```bash
# Standard Debian upgrade process
sudo apt update
sudo apt full-upgrade
sudo reboot
```

Or rebuild image with newer Debian.

### Can I upgrade the kernel manually?

Not recommended. Kernel updates via APT automatically.

**To force kernel update**:
```bash
sudo apt update
sudo apt install --reinstall raspberrypi-kernel
sudo reboot
```

---

## Troubleshooting Questions

### Image won't boot (rainbow screen)

**Causes**:
- Corrupted SD card
- Incomplete flash
- Incompatible Raspberry Pi model

**Solutions**:
1. Verify image integrity:
   ```bash
   sha256sum image.img.xz
   ```
2. Re-flash:
   ```bash
   xz -dc image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   sync
   ```
3. Try different SD card
4. Check UART output for errors

### Can't login (credentials don't work)

**Default credentials**:
- Username: `pi`
- Password: `raspberry`

**If still fails**:
- Caps Lock enabled?
- Keyboard layout (US by default)
- Wait for first-boot to complete (3-5 minutes)

**Reset password** (mount SD card on another Linux machine):
```bash
sudo mount /dev/sdX2 /mnt
sudo chroot /mnt
passwd pi
exit
sudo umount /mnt
```

### No network / can't get IP

**Troubleshooting**:
1. Check cable:
   ```bash
   ip link show eth0
   # Should show "state UP"
   ```
2. Check DHCP:
   ```bash
   sudo nmcli con up br-wan
   ```
3. Check NetworkManager:
   ```bash
   sudo systemctl status NetworkManager
   ```
4. Manual IP (see "How do I set static IP?" above)

### Service didn't start

**Check first-boot logs**:
```bash
sudo journalctl -u services-first-boot
```

**Check service status**:
```bash
sudo systemctl status docker
sudo incus list
```

**Common issues**:
- First-boot still running (wait 5-10 min)
- Insufficient disk space (`df -h`)
- Network unavailable during first-boot

### Build failed in GitHub Actions

**Check logs**:
1. Go to Actions tab
2. Click failed workflow
3. Click failed job
4. Review logs

**Common issues**:
- QEMU timeout (increase QEMU_TIMEOUT)
- Out of disk space (reduce IMAGE_SIZE)
- Network error (retry build)

---

## Advanced Questions

### Can I use a different base distribution?

**Experimental support** for non-Debian distributions is in development.

**Current**: Only Debian 13 (Trixie) supported

**Future**: Ubuntu, Fedora, Alpine planned

**Why Debian-only currently?**
- Services use APT (Debian package manager)
- RaspiOS repository is Debian-based

### Can I cross-compile instead of using QEMU?

Theoretically yes, but:
- Complex to set up
- Requires ARM64 toolchain
- Package installation still needs emulation or chroot

**QEMU advantages**:
- Native ARM64 environment
- No cross-compilation issues
- Simpler workflow

### Can I build for Raspberry Pi 3 (32-bit)?

Not currently. This project uses ARM64 (64-bit) Debian.

**For Pi 3**:
- Use standard Raspberry Pi OS (32-bit)
- Or adapt this project for armhf (significant work)

### How do I contribute?

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

Quick start:
1. Fork repository
2. Create feature branch
3. Make changes
4. Test builds
5. Submit pull request

---

## Support

**Can't find your answer?**

- [Check Troubleshooting guide](Troubleshooting.md)
- [Open an issue](https://github.com/Pikatsuto/raspberry-builds/issues)
- [Start a discussion](https://github.com/Pikatsuto/raspberry-builds/discussions)