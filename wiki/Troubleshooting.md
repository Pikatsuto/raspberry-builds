# Troubleshooting

Common issues and solutions.

## Build Issues

### QEMU Won't Boot
**Symptoms**: QEMU hangs at boot

**Solutions**:
```bash
# Install UEFI firmware
sudo apt install qemu-efi-aarch64

# Increase timeout in config.sh
QEMU_TIMEOUT=3600

# Check logs
cat images/*/qemu-*.log
```

### QEMU Timeout
**Symptoms**: "QEMU timeout" error

**Solutions**:
- Increase `QEMU_TIMEOUT` in config.sh
- Increase `QEMU_RAM` and `QEMU_CPUS`
- Check network connectivity
- Review QEMU logs

### Merge Fails
**Symptoms**: Error during merge stage

**Solutions**:
```bash
# Check disk space
df -h

# Re-download base images
rm images/debian/*.img images/debian/*.raw
./bin/autobuild --image debian

# Check partition layout
fdisk -l raspios.img
fdisk -l debian.raw
```

### Out of Disk Space
**Symptoms**: "No space left on device"

**Solutions**:
- Free up space: `sudo apt clean`
- Use smaller `IMAGE_SIZE`
- Build fewer services

## Boot Issues

### Rainbow Screen
**Symptoms**: Raspberry Pi shows rainbow screen, won't boot

**Solutions**:
1. Verify image integrity: `sha256sum image.img.xz`
2. Re-flash SD card
3. Try different SD card
4. Check UART output

### Can't Login
**Symptoms**: Credentials don't work

**Default**: Username `pi`, password `raspberry`

**Solutions**:
- Check Caps Lock
- Wait for first-boot to complete (3-5 min)
- Reset password via SD card mount

### No Network
**Symptoms**: Can't get IP address

**Solutions**:
```bash
# Check interface
ip link show eth0

# Restart connection
sudo nmcli con up br-wan

# Check NetworkManager
sudo systemctl status NetworkManager

# Set static IP (see Configuration Reference)
```

## Service Issues

### Service Not Starting
**Symptoms**: Docker/HAOS/OpenWrt not running

**Solutions**:
```bash
# Check first-boot logs
sudo journalctl -u services-first-boot

# Check service status
sudo systemctl status docker
incus list

# Check disk space
df -h
```

### Container/VM Won't Start
**Symptoms**: Incus container/VM fails to start

**Solutions**:
```bash
# Check Incus logs
incus info haos
incus info --show-log haos

# Check resources
free -h
df -h

# Restart Incus
sudo systemctl restart incus
```

## Hardware Issues

### WiFi Not Detected
**Symptoms**: wlan0 doesn't exist

**Solutions**:
```bash
# Check firmware
dmesg | grep brcmfmac

# Install firmware
sudo apt install firmware-brcm80211

# Reboot
sudo reboot
```

### Zigbee Not Passed to HAOS
**Symptoms**: Zigbee dongle not in Home Assistant

**Solutions**:
```bash
# Check detection
sudo journalctl -u services-first-boot | grep -i zigbee

# Manual passthrough
lsusb  # Find vendor/product ID
incus config device add haos zigbee usb vendorid=XXXX productid=YYYY

# Restart VM
incus restart haos
```

## GitHub Actions Issues

### Build Timeout
**Symptoms**: CI/CD build fails with timeout

**Solutions**:
- Increase `QEMU_TIMEOUT` in workflow
- Reduce `IMAGE_SIZE`
- Use fewer services

### Asset Upload Fails
**Symptoms**: Image built but not in release

**Solutions**:
- Check GitHub token permissions
- Verify release was created
- Check asset size (<2GB per file)

## Getting Help

**Check logs**:
```bash
# Build logs
cat images/*/qemu-*.log

# First-boot logs
sudo journalctl -u rpi-first-boot
sudo journalctl -u services-first-boot

# Service logs
sudo journalctl -u docker
sudo journalctl -u incus
```

**Still stuck?**
- [Check FAQ](FAQ.md)
- [Open issue](https://github.com/Pikatsuto/raspberry-builds/issues)
- [Ask in discussions](https://github.com/Pikatsuto/raspberry-builds/discussions)

Include:
- Build command used
- Error messages
- Relevant logs
- Hardware details (Pi model, RAM, SD card size)