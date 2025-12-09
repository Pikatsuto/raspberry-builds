# OpenWRT service MOTD configuration
# These variables are used by update-motd-ip.sh to generate service URLs

# Service information
SERVICE_NAME="OpenWRT"
PROTOCOL="http"
PORT=""  # No port needed (default 80)
VM_NAME="openwrt"  # Incus VM/container name to get IP and hostname from