# Docker service MOTD configuration
# These variables are used by update-motd-ip.sh to generate service URLs

# Service detection command (should return 0 if service is active)
SERVICE_DETECT_CMD='systemctl is-active --quiet docker && docker ps --format "{{.Names}}" 2>/dev/null | grep -q portainer'

# Service information
SERVICE_NAME="Portainer"
PROTOCOL="https"
PORT="9443"
USE_HOST_HOSTNAME=true  # Use host's hostname instead of VM hostname