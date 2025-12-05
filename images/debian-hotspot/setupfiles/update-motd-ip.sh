#!/bin/bash
# Update /etc/issue (login screen) and /etc/motd with current IP addresses

ISSUE_FILE="/etc/issue"
MOTD_FILE="/etc/motd"

# Get hostname
HOSTNAME=$(hostname)

# Get all IP addresses (excluding loopback)
IP_LIST=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")

# Build content
CONTENT="========================================
  Raspberry Pi - RaspiVirt-Incus
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
        CONTENT+="    $IFACE: $ip
"
    done <<< "$IP_LIST"
fi

CONTENT+="
  SSH: ssh root@<ip>

========================================
"

# Write to both /etc/issue (login screen) and /etc/motd (after login)
echo "$CONTENT" > "$ISSUE_FILE"
# echo "$CONTENT" > "$MOTD_FILE"
