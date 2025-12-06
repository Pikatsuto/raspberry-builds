# WiFi Hotspot Images

**WiFi Hotspot images** add WiFi Access Point functionality to RaspiVirt images, turning your Raspberry Pi into a WiFi hotspot while maintaining all virtualization capabilities. These images automatically detect and configure WiFi interfaces for optimal performance.

## Overview

All hotspot variants include:
- **Automatic WiFi interface detection** (single or dual-band)
- **hostapd** for WiFi Access Point
- **Dynamic bridge assignment** (br-lan or br-wan)
- **NetworkManager-based network configuration**
- All features from their base images

## Available Hotspot Images

### 1. RaspiVirt-Incus+Hotspot
**Image**: `rpi-raspivirt-qemu+hotspot.img`

Base virtualization platform with WiFi hotspot:
- Incus container/VM manager
- KVM hardware virtualization
- Bridged networking (br-wan + optional br-lan)
- **WiFi Access Point** (5GHz or dual-band)

```bash
./bin/autobuild --image raspivirt-qemu+hotspot
```

### 2. RaspiVirt-Incus+Docker+Hotspot
**Image**: `rpi-raspivirt-qemu+docker+hotspot.img`

Complete platform with Incus, Docker, and WiFi hotspot:
- Everything from Incus+Hotspot
- Docker Engine with Portainer
- Watchtower for automatic updates
- **WiFi Access Point** (5GHz or dual-band)

```bash
./bin/autobuild --image raspivirt-qemu+docker+hotspot
```

### 3. RaspiVirt-Incus+HAOS+Hotspot
**Image**: `rpi-raspivirt-qemu+haos+hotspot.img`

Home automation with WiFi hotspot:
- Incus with Home Assistant OS VM
- Zigbee USB dongle passthrough
- **WiFi Access Point** (5GHz or dual-band)

```bash
./bin/autobuild --image raspivirt-qemu+haos+hotspot
```

### 4. RaspiVirt-Incus+HAOS+Docker+Hotspot
**Image**: `rpi-raspivirt-qemu+haos+docker+hotspot.img`

Complete home automation platform:
- Incus with Home Assistant OS VM
- Docker Engine with Portainer
- Zigbee USB dongle passthrough
- **WiFi Access Point** (5GHz or dual-band)

```bash
./bin/autobuild --image raspivirt-qemu+haos+docker+hotspot
```

## WiFi Configuration

### Automatic Interface Detection

The system automatically detects available WiFi interfaces and configures hostapd accordingly:

#### Single WiFi Interface (wlan0 only)
```
Detected: wlan0
Configuration: 5GHz Access Point on wlan0
Service: hostapd-5ghz enabled
```

**Why 5GHz?**
- Better performance (up to 867 Mbps)
- Less interference
- More channels available

#### Dual WiFi Interfaces (wlan0 + wlan1)
```
Detected: wlan0 and wlan1
Configuration:
  - wlan0: 2.4GHz Access Point
  - wlan1: 5GHz Access Point
Service: Both hostapd-2.4ghz and hostapd-5ghz enabled
```

**Dual-band advantages**:
- Legacy device support (2.4GHz)
- High performance for modern devices (5GHz)
- Better coverage (2.4GHz has longer range)

### Default WiFi Settings

**SSID**: `RaspberryPI-WIFI`
**Password**: `raspberry`
**Security**: WPA2-PSK

**⚠️ Change these immediately after first boot!**

### Changing WiFi Settings

Edit the hostapd configuration files:

#### For 5GHz:
```bash
sudo nano /etc/hostapd/hostapd-5ghz.conf
```

```conf
ssid=YourNetwork5G
wpa_passphrase=YourSecurePassword
channel=36  # or 40, 44, 48, 149, 153, 157, 161
```

#### For 2.4GHz:
```bash
sudo nano /etc/hostapd/hostapd-2.4ghz.conf
```

```conf
ssid=YourNetwork2G
wpa_passphrase=YourSecurePassword
channel=6  # or 1, 11
```

**Restart hostapd after changes**:
```bash
sudo systemctl restart hostapd-5ghz
sudo systemctl restart hostapd-2.4ghz  # if dual-band
```

## Network Architecture

### With br-lan (eth1 present)

```
Internet
    ↓
  Router ←─ eth0 (br-wan)
    ↓
┌─────────────────────────────────┐
│  Raspberry Pi                   │
│  ┌───────────────────────────┐  │
│  │  br-lan (LAN Bridge)      │  │
│  │   ├─ eth1 (LAN port)      │  │ ← Local network
│  │   ├─ wlan0/wlan1 (WiFi)   │  │ ← WiFi clients
│  │   ├─ Container 1           │  │
│  │   └─ VM 1                  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Configuration**:
- **br-wan**: WAN connectivity (eth0)
- **br-lan**: Local network (eth1 + WiFi)
  - IP: 192.168.10.254/24
  - DHCP server for WiFi clients
  - DNS server with upstream Cloudflare

### Without br-lan (eth0 only)

```
Internet
    ↓
  Router
    ↓
┌─────────────────────────────────┐
│  Raspberry Pi                   │
│  ┌───────────────────────────┐  │
│  │  br-wan (Bridge)          │  │
│  │   ├─ eth0 (Ethernet)      │  │
│  │   ├─ wlan0/wlan1 (WiFi)   │  │ ← WiFi clients on router network
│  │   ├─ Container 1           │  │
│  │   └─ VM 1                  │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

**Configuration**:
- **br-wan**: Combined WAN + WiFi bridge (eth0 + WiFi)
- WiFi clients get IPs from your router
- No separate LAN subnet

## DHCP and DNS Configuration

When br-lan is available, a DHCP/DNS server is automatically configured:

### DHCP Settings
- **IPv4 range**: 192.168.10.100 - 192.168.10.199
- **IPv6 range**: fd00:10:10::100 - fd00:10:10::199
- **Lease time**: 12 hours
- **Gateway**: 192.168.10.254 (Raspberry Pi)

### DNS Settings
- **Local DNS**: 192.168.10.254
- **Domain**: `.lan`
- **Upstream DNS**: Cloudflare (1.1.1.1, 1.0.0.1)
- **Features**:
  - Local hostname resolution (e.g., `mycontainer.lan`)
  - DNS query logging
  - DHCP request logging

### Configuration File
`/etc/NetworkManager/dnsmasq-shared.d/br-lan.conf`

## First-Boot Process

### Stage 1: rpi-first-boot
1. Enable classic network names (eth0, wlan0)
2. Disable cloud-init networking
3. Resize root partition
4. Reboot

### Stage 2: services-first-boot
1. **Configure network bridges**:
   - Create br-wan (always)
   - Create br-lan (if eth1 exists)
   - Configure DHCP/DNS for br-lan
2. **Configure WiFi Access Point**:
   - Detect wlan0 and wlan1
   - Update hostapd configurations
   - Set bridge assignment (br-lan or br-wan)
   - Enable and start hostapd services
3. **Initialize services** (Incus, Docker, HAOS as applicable)
4. Self-destruct

## Installed Software

### Networking (in addition to base image)
- **NetworkManager** - Modern network management
- **hostapd** - WiFi Access Point daemon
- **dnsmasq** (via NetworkManager) - DHCP and DNS server

### Hostapd Services
- **hostapd-5ghz.service** - 5GHz Access Point
- **hostapd-2.4ghz.service** - 2.4GHz Access Point (dual-band only)

## WiFi Performance

### 5GHz Configuration
- **Standard**: IEEE 802.11ac (WiFi 5)
- **Channel width**: 80 MHz (VHT80)
- **Max speed**: Up to 867 Mbps
- **Channel**: 36 (5.180 GHz)
- **Features**:
  - Short GI (Guard Interval)
  - HT40+ (40 MHz on 2.4GHz fallback)

### 2.4GHz Configuration
- **Standard**: IEEE 802.11n (WiFi 4)
- **Max speed**: Up to 300 Mbps
- **Channel**: 6 (2.437 GHz)
- **Better range** than 5GHz
- **Legacy device support**

## Use Cases

### Home WiFi Router + Virtualization
- Use as primary WiFi router with Incus containers
- Run services in containers accessible via WiFi
- Separate LAN for IoT devices

### Development Hotspot
- Create isolated WiFi network for testing
- Run dev containers accessible via WiFi
- Debug mobile apps connecting to local services

### IoT Gateway
- WiFi access point for IoT devices
- Run Home Assistant in Incus VM
- Zigbee/Z-Wave gateway in container

### Portable Lab
- Self-contained network with WiFi
- Run isolated test environments
- Demo platform with WiFi access

## Managing WiFi Clients

### View Connected Clients (br-lan)
```bash
# View DHCP leases
cat /var/lib/NetworkManager/dnsmasq-br-lan.leases

# View active connections
sudo iw dev wlan0 station dump  # or wlan1 for 5GHz
```

### Monitor WiFi Status
```bash
# Check hostapd status
sudo systemctl status hostapd-5ghz
sudo systemctl status hostapd-2.4ghz  # if dual-band

# View hostapd logs
sudo journalctl -u hostapd-5ghz -f
```

### Restart WiFi Access Point
```bash
# Restart 5GHz
sudo systemctl restart hostapd-5ghz

# Restart 2.4GHz (if dual-band)
sudo systemctl restart hostapd-2.4ghz
```

## Advanced Configuration

### Change WiFi Channel

**5GHz channels** (less interference):
- 36, 40, 44, 48 (lower band)
- 149, 153, 157, 161 (upper band)

**2.4GHz channels** (avoid overlap):
- 1, 6, 11 (non-overlapping)

Edit `/etc/hostapd/hostapd-5ghz.conf`:
```conf
channel=149  # Change to desired channel
```

### Enable Hidden SSID

Edit hostapd configuration:
```conf
ignore_broadcast_ssid=1
```

### MAC Address Filtering

Edit hostapd configuration:
```conf
macaddr_acl=1
accept_mac_file=/etc/hostapd/hostapd.accept
```

Create `/etc/hostapd/hostapd.accept`:
```
aa:bb:cc:dd:ee:ff
11:22:33:44:55:66
```

### Change WiFi Country Code

Edit `/etc/hostapd/hostapd-5ghz.conf`:
```conf
country_code=US  # or GB, DE, FR, etc.
```

## Troubleshooting

### WiFi Not Broadcasting

**Check WiFi interface**:
```bash
ip link show wlan0
```

**Verify hostapd is running**:
```bash
sudo systemctl status hostapd-5ghz
```

**Check hostapd logs**:
```bash
sudo journalctl -u hostapd-5ghz -n 50
```

**Common issues**:
- WiFi interface in use by NetworkManager (should be disabled automatically)
- Country code mismatch
- Unsupported channel

### Clients Can't Connect

**Check hostapd configuration**:
```bash
sudo hostapd -dd /etc/hostapd/hostapd-5ghz.conf
# Run in debug mode (stop service first)
```

**Verify DHCP server** (br-lan only):
```bash
sudo systemctl status NetworkManager
sudo journalctl -u NetworkManager | grep dnsmasq
```

**Common issues**:
- Wrong WiFi password
- WPA2 not supported by client
- DHCP not responding (br-lan)

### No Internet on WiFi

**With br-lan**: Check NAT and forwarding:
```bash
# Verify IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check NAT rules
sudo iptables -t nat -L -n -v
```

**With br-wan**: Check bridge:
```bash
# Verify br-wan has IP
ip addr show br-wan

# Check wlan0/wlan1 in bridge
bridge link show
```

### Performance Issues

**Check WiFi signal strength**:
```bash
sudo iw dev wlan0 station dump
# Look for "signal" values
```

**Change channel if interference**:
```bash
# Scan for best channel
sudo iw dev wlan0 scan | grep -E "^BSS|channel|signal"
```

**Optimize hostapd**:
```conf
# In hostapd config
wmm_enabled=1  # Enable WMM for better performance
```

## Security Recommendations

1. **Change default WiFi password** immediately
2. **Change SSID** to something unique
3. **Use strong WPA2 password** (minimum 12 characters)
4. **Disable WPS** (already disabled by default)
5. **Enable MAC filtering** for sensitive networks
6. **Monitor connected clients** regularly
7. **Update firmware** regularly via apt

## Performance Tips

### WiFi Performance
- Use 5GHz for better performance (less interference)
- Use 2.4GHz for better range
- Choose least congested channel
- Position antenna for optimal coverage
- Use external antenna if available

### Network Performance
- Use wired connection (eth0/eth1) for containers/VMs when possible
- Enable QoS in hostapd for prioritization
- Limit bandwidth per WiFi client if needed
- Monitor network usage with iftop

## Related Documentation

- **Base Images**: See parent image documentation for full feature list
- **[RaspiVirt-Incus](Image-RaspiVirt-Incus)**: Base Incus image
- **[RaspiVirt-Incus+Docker](Image-RaspiVirt-Incus-Docker)**: Docker variant
- **[RaspiVirt-Incus+HAOS](Image-RaspiVirt-Incus-HAOS)**: Home Assistant variant
- **[HAOS+Docker Images](Image-HAOS-Docker)**: Docker+HAOS combinations
- **[hostapd Documentation](https://w1.fi/hostapd/)**: Official hostapd docs
- **[NetworkManager](https://networkmanager.dev/)**: NetworkManager documentation

## Build Information

All hotspot images use the same WiFi configuration with automatic detection. The only differences are the additional software installed from their base images.

**Download**: [Latest Release](../../releases)

**Build Logs**: [GitHub Actions](../../actions)