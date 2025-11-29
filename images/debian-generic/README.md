# debian-generic - First-Boot Mode Example

This image demonstrates the **first-boot service mode** - a cloud-init-free approach that works with any generic Debian ARM64 image.

## Features

- No cloud-init dependency
- Works with generic Debian ARM64 images (not just cloud images)
- Automatic user creation (pi/raspberry)
- SSH enabled by default
- Basic system configuration (timezone, locale)

## How It Works

Instead of cloud-init, this image uses a systemd service that:

1. Runs once at first boot
2. Creates the `pi` user with sudo access
3. Configures SSH for password authentication
4. Mounts and executes `setup.sh` from the setup.iso
5. Self-destructs after completion

## Files

### `first-boot/setup-runner.sh`
The first-boot script that:
- Creates the default user (`pi` with password `raspberry`)
- Configures SSH
- Mounts `/dev/vdc` (setup.iso) and runs the setup script
- Removes itself after execution

### `first-boot/setup-runner.service`
Systemd service that runs `setup-runner.sh` once at first boot.

### `setup.sh`
Your custom setup script executed inside QEMU. Modify this to:
- Install packages
- Configure services
- Set up networking
- Customize the system

### `setupfiles/`
Directory for custom files to include in the image. These files are copied to `/root/setupfiles/` during setup.

## Usage

```bash
# Build the image
./bin/autobuild --image debian-generic

# Flash to SD card
sudo dd if=rpi-debian-generic.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

## Default Credentials

- **Username**: `pi`
- **Password**: `raspberry`
- **Sudo**: Passwordless sudo enabled

**Important**: Change the default password after first boot!

## Customization

1. Edit `setup.sh` to customize system configuration
2. Add files to `setupfiles/` to include in the image
3. Modify `first-boot/setup-runner.sh` to change user creation or SSH config
4. Update `config.sh` to adjust image size, QEMU RAM, etc.

## Comparison with Cloud-Init Mode

| Feature | First-Boot Mode | Cloud-Init Mode |
|---------|----------------|-----------------|
| Debian image required | Any generic ARM64 | Cloud image with cloud-init |
| Dependencies | None (systemd only) | cloud-init package |
| Configuration | Direct shell script | YAML files |
| Complexity | Simple | More features, more complex |
| Use case | Generic images, minimal setup | Cloud environments, advanced config |