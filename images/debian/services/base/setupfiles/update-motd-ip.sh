#!/bin/bash
# Update /etc/issue (login screen) and /etc/motd with current IP addresses and service URLs

ISSUE_FILE="/etc/issue"
MOTD_FILE="/etc/motd"
MOTD_CONFIGS_DIR="/etc/setupfiles/motd.d"

# Get hostname
HOSTNAME=$(hostname)

# Get IP addresses (prefer br-lan, then add br-wan if exists)
IP_LIST=""

# Try br-lan first
if ip addr show br-lan >/dev/null 2>&1; then
    IP_LIST=$(ip -4 addr show br-lan | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
fi

# Add br-wan if exists
if ip addr show br-wan >/dev/null 2>&1; then
    BR_WAN_IP=$(ip -4 addr show br-wan | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
    if [ -n "$BR_WAN_IP" ]; then
        IP_LIST="${IP_LIST}${IP_LIST:+$'\n'}${BR_WAN_IP}"
    fi
fi

# Fallback: get all IPs if br-lan and br-wan don't exist
if [ -z "$IP_LIST" ]; then
    IP_LIST=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
fi

# Get primary IP (first in list)
PRIMARY_IP=$(echo "$IP_LIST" | head -1)

# Detect DNS search domain (prefer br-lan, fallback to br-wan, then any interface)
DNS_DOMAIN=""

# Try to get DNS search domain from NetworkManager connections
if ip addr show br-lan >/dev/null 2>&1; then
    DNS_DOMAIN="lan"
elif command -v nmcli >/dev/null 2>&1; then
    # Check br-lan first
    if nmcli connection show br-lan >/dev/null 2>&1; then
        DNS_DOMAIN=$(nmcli -g ipv4.dns-search connection show br-lan 2>/dev/null | head -1)
    fi

    # Fallback to br-wan
    if [ -z "$DNS_DOMAIN" ] && nmcli connection show br-wan >/dev/null 2>&1; then
        DNS_DOMAIN=$(nmcli -g ipv4.dns-search connection show br-wan 2>/dev/null | head -1)
    fi

    # Fallback to any active connection
    if [ -z "$DNS_DOMAIN" ]; then
        DNS_DOMAIN=$(nmcli -g ipv4.dns-search connection show --active 2>/dev/null | grep -v '^$' | head -1)
    fi
fi

# Fallback to /etc/resolv.conf
if [ -z "$DNS_DOMAIN" ] && [ -f /etc/resolv.conf ]; then
    DNS_DOMAIN=$(grep -m1 '^search ' /etc/resolv.conf | awk '{print $2}')
fi

# Final fallback to .lan
if [ -z "$DNS_DOMAIN" ]; then
    DNS_DOMAIN="lan"
fi

echo "Detected DNS domain: $DNS_DOMAIN" >&2

# Build content
CONTENT="========================================
  Raspberry Pi - Debian ARM
========================================
  Hostname: $HOSTNAME

  IP Addresses:
"

if [ -z "$IP_LIST" ]; then
    CONTENT+="    No IP address assigned yet
"
else
    while IFS= read -r ip; do
        # Get interface name for this IP
        IFACE=$(ip -4 addr show | grep -B2 "$ip" | head -1 | awk '{print $2}' | sed 's/://')
        CONTENT+="    $IFACE:\t$ip
"
    done <<< "$IP_LIST"
fi

CONTENT+="
  SSH:
    ${HOSTNAME}:\tssh root@${HOSTNAME}.${DNS_DOMAIN}
    \t\tssh root@${PRIMARY_IP}

"

# Collect service URLs from motd.d configs
SERVICES_CONTENT=""

if [ -d "$MOTD_CONFIGS_DIR" ]; then
    for motd_config in "$MOTD_CONFIGS_DIR"/*.sh; do
        [ -f "$motd_config" ] || continue

        # Reset variables
        SERVICE_NAME=""
        PROTOCOL=""
        PORT=""
        VM_NAME=""
        USE_HOST_HOSTNAME=false
        SERVICE_DETECT_CMD=""

        # Source the config
        source "$motd_config"

        # Skip if service name not defined
        [ -z "$SERVICE_NAME" ] && continue

        # Check if service is active (if detect command provided)
        if [ -n "$SERVICE_DETECT_CMD" ]; then
            eval "$SERVICE_DETECT_CMD" || continue
        fi

        # Determine hostname and IP
        SERVICE_HOSTNAME=""
        SERVICE_IP=""

        if [ "$USE_HOST_HOSTNAME" = true ]; then
            # Use host's hostname and IP
            SERVICE_HOSTNAME="$HOSTNAME"
            SERVICE_IP="$PRIMARY_IP"
        elif [ -n "$VM_NAME" ]; then
            # Get VM/container info from Incus
            if command -v incus >/dev/null 2>&1; then
                # Get IP from incus list
                SERVICE_IP=$(echo $(incus list "$VM_NAME" --format csv --columns 4 2>/dev/null | xargs -0 | cut -d' ' -f1 | sed 's|"||g') | cut -d ' ' -f 1)

                # Get hostname from VM/container
                SERVICE_HOSTNAME=$(
                    incus exec "$VM_NAME" -- hostname 2>/dev/null \
                    || getent hosts "$SERVICE_IP" | xargs | cut -d " " -f 2
                )

                if [ -z "$SERVICE_HOSTNAME" ]; then
                    SERVICE_HOSTNAME="$VM_NAME"
                fi
            fi
        fi

        if [ -z "$SERVICE_IP" ] || [ "$SERVICE_IP" = "-" ]; then
            if [ "$USE_HOST_HOSTNAME" = true ]; then
                # Use host's hostname and IP
                SERVICE_HOSTNAME="$HOSTNAME"
                SERVICE_IP="$PRIMARY_IP"
            elif [ -n "$VM_NAME" ]; then
                # Scan network to find VM/container by service port
                # Get local network subnet (prefer br-lan, fallback to br-wan)
                LOCAL_SUBNET=""

                # Try br-lan first
                if ip addr show br-lan >/dev/null 2>&1; then
                    LOCAL_SUBNET=$(ip -4 addr show br-lan | grep -oP '(?<=inet\s)\d+(\.\d+){2}' | head -1)
                fi

                # Fallback to br-wan
                if [ -z "$LOCAL_SUBNET" ] && ip addr show br-wan >/dev/null 2>&1; then
                    LOCAL_SUBNET=$(ip -4 addr show br-wan | grep -oP '(?<=inet\s)\d+(\.\d+){2}' | head -1)
                fi

                if [ -z "$LOCAL_SUBNET" ]; then
                    # No local network found
                    continue
                fi

                # Default port for scanning
                SCAN_PORT="${PORT:-80}"

                # Scan local network for the service port
                # Use nmap if available, otherwise use simple nc scan
                if command -v nmap >/dev/null 2>&1; then
                    # Fast nmap scan for specific port
                    SERVICE_IP=$(nmap -p "$SCAN_PORT" --open -oG - "${LOCAL_SUBNET}.0/24" 2>/dev/null | \
                        grep "/open/" | head -1 | awk '{print $2}')
                else
                    # Fallback: simple nc scan (slower but no dependencies)
                    for i in {2..254}; do
                        TEST_IP="${LOCAL_SUBNET}.${i}"

                        # Skip host's own IP
                        if echo "$IP_LIST" | grep -q "$TEST_IP"; then
                            continue
                        fi

                        # Test connection with timeout
                        if timeout 0.2 nc -z "$TEST_IP" "$SCAN_PORT" 2>/dev/null; then
                            SERVICE_IP="$TEST_IP"
                            break
                        fi
                    done
                fi

                # Skip if service not found on network
                if [ -z "$SERVICE_IP" ]; then
                    continue
                fi

                # Try to get hostname via reverse DNS or HTTP request
                SERVICE_HOSTNAME=""

                # Method 1: Try reverse DNS lookup
                if command -v host >/dev/null 2>&1; then
                    SERVICE_HOSTNAME=$(host "$SERVICE_IP" 2>/dev/null | grep "domain name pointer" | awk '{print $NF}' | sed 's/\.$//')
                fi

                # Method 2: If HTTP/HTTPS service, try to get hostname from HTTP headers
                if [ -z "$SERVICE_HOSTNAME" ] && [ "$PROTOCOL" = "http" ] || [ "$PROTOCOL" = "https" ]; then
                    # Try curl with timeout
                    if command -v curl >/dev/null 2>&1; then
                        SERVICE_HOSTNAME=$(curl -s -m 2 --insecure -I "${PROTOCOL}://${SERVICE_IP}:${SCAN_PORT}" 2>/dev/null | \
                            grep -i "^Server:\|^Host:" | head -1 | awk '{print $2}' | tr -d '\r')
                    fi
                fi

                # Fallback: use VM_NAME as hostname
                if [ -z "$SERVICE_HOSTNAME" ]; then
                    SERVICE_HOSTNAME="$VM_NAME"
                fi
            else
                continue
            fi
        fi

        # Convert hostname to lowercase
        SERVICE_HOSTNAME=$(echo -n "$SERVICE_HOSTNAME" | tr '[:upper:]' '[:lower:]')

        # Build URL
        URL_HOSTNAME="${PROTOCOL}://${SERVICE_HOSTNAME}.${DNS_DOMAIN}"
        URL_IP="${PROTOCOL}://${SERVICE_IP}"

        # Add port if specified
        if [[ -n "$PORT" && "$PORT" != "80" ]]; then
            URL_HOSTNAME="${URL_HOSTNAME}:${PORT}"
            URL_IP="${URL_IP}:${PORT}"
        fi
        URL_HOSTNAME="${URL_HOSTNAME}\n"
        URL_IP="\t\t${URL_IP}\n"

        # Add to services content with proper alignment
        SERVICES_CONTENT+="    $SERVICE_NAME:\t$URL_HOSTNAME"
        SERVICES_CONTENT+="$URL_IP"
    done
fi

# Add services section if any services found
if [ -n "$SERVICES_CONTENT" ]; then
    CONTENT+="  Services:
$SERVICES_CONTENT"
fi

CONTENT+="========================================
"

# Write to both /etc/issue (login screen) and /etc/motd (after login)
echo -e "$CONTENT" > "$ISSUE_FILE"
# echo -e "$CONTENT" > "$MOTD_FILE"