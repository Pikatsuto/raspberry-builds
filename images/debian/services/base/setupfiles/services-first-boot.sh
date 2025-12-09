#!/bin/bash
# Base services-first-boot script
# This script runs once on first boot after network is available
# Additional services will append their initialization code here

set -e

echo "======================================"
echo "Running services first-boot setup..."
echo "======================================"

# Network Manager should be active - wait for connectivity
echo "Waiting for network connectivity..."
timeout=60
counter=0
while ! ping -c 1 -W 1 8.8.8.8 &> /dev/null; do
    sleep 1
    counter=$((counter + 1))
    if [ $counter -ge $timeout ]; then
        echo "Warning: Network connectivity timeout after ${timeout}s"
        break
    fi
done

if ping -c 1 -W 1 8.8.8.8 &> /dev/null; then
    echo "Network is up!"
else
    echo "Warning: No network connectivity detected"
fi

# ====== SERVICES INITIALIZATION ======
# Additional service initialization code will be appended here by autobuild

# ====== END SERVICES INITIALIZATION ======

echo "======================================"
echo "Services first-boot setup complete!"
echo "======================================"

# Update MOTD with service URLs
echo "Updating MOTD with service information..."
if [ -f /etc/setupfiles/update-motd-ip.sh ]; then
    bash /etc/setupfiles/update-motd-ip.sh
    echo "MOTD updated successfully!"
    echo ""
    # Display the MOTD
    cat /etc/issue
fi

# Disable this service after first run
systemctl disable services-first-boot.service

exit 0