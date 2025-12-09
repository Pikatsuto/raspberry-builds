# Incus UI service MOTD configuration
# These variables are used by update-motd-ip.sh to generate service URLs

# Service detection command (should return 0 if service is active)
SERVICE_DETECT_CMD='systemctl is-active --quiet incus 2>/dev/null'

# Service information
SERVICE_NAME="Incus UI"
PROTOCOL="https"
PORT="8443"
USE_HOST_HOSTNAME=true  # Use host's hostname instead of VM hostname