#!/bin/bash
set -e

# ============================================================================
# First-boot setup runner - Replaces cloud-init
# This script runs once at first boot, configures the system, and self-destructs
# ============================================================================

echo "======================================"
echo "First Boot Setup Runner"
echo "======================================"

runner() {
    # 1. Create default user
    echo "[1/5] Creating user 'pi'..."
    if ! id -u pi &>/dev/null; then
        useradd -m -s /bin/bash pi
        echo "pi:raspberry" | chpasswd
        usermod -aG sudo pi
        mkdir -p /etc/sudoers.d
        echo "pi ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/pi
        chmod 440 /etc/sudoers.d/pi
        echo "  User 'pi' created (password: raspberry)"
    else
        echo "  User 'pi' already exists"
    fi

    # 3. Mount setup.iso and execute setup.sh
    echo "[3/5] Running setup script from setup.iso..."
    if [ -e /dev/vdc ]; then
        mkdir -p /mnt/setup
        mount /dev/vdc /mnt/setup

        # Copy setupfiles to /root
        if [ -d /mnt/setup/setupfiles ]; then
            cp -r /mnt/setup/setupfiles /root/setupfiles
            echo "  Setup files copied to /root/setupfiles"
        fi

        # Execute setup script
        if [ -f /mnt/setup/setup ]; then
            echo "  Executing /mnt/setup/setup..."
            chmod +x /mnt/setup/setup
            /mnt/setup/setup
            echo "  Setup script completed"
        else
            echo "  Warning: /mnt/setup/setup not found"
        fi

        # Cleanup
        umount /mnt/setup
        rm -rf /mnt/setup /root/setupfiles
    else
        echo "  Warning: /dev/vdc (setup.iso) not found, skipping setup script"
    fi

    # 4. Self-destruct - Remove this service
    echo "[4/5] Removing first-boot service..."
    systemctl disable setup-runner.service 2>/dev/null || true
    rm -f /etc/systemd/system/setup-runner.service
    rm -f /root/setup-runner.sh
    systemctl daemon-reload
    echo "  First-boot service removed"
}

runner || true

# 5. Poweroff
echo "[5/5] Powering off..."
echo "======================================"
echo "First boot setup completed!"
echo "======================================"
sleep 2
poweroff