# Custom Images

This folder contains configurations for different Raspberry Pi images.

## Structure

Each image has its own folder with:

```
images/
└── image-name/
    ├── config.sh          # Image configuration (size, RAM, etc.)
    ├── setup.sh           # Script executed at boot in QEMU
    ├── setupfiles/        # Files copied to the image
    └── cloudinit/         # Cloud-init configuration for this image
        ├── user-data      # Users, SSH, passwords
        ├── meta-data      # Hostname, instance-id
        └── seed.img       # Automatically generated
```

## Creating a New Image

1. **Copy the example folder**
   ```bash
   cp -r images/exemple images/my-image
   ```

2. **Modify the configuration** (`images/my-image/config.sh`)
   ```bash
   OUTPUT_IMAGE="rpi-my-image.img"
   IMAGE_SIZE="16G"
   QEMU_RAM="8G"
   QEMU_CPUS="4"
   DESCRIPTION="My awesome custom image"
   ```

3. **Customize the setup** (`images/my-image/setup.sh`)
   - Add your packages
   - Configure your services
   - Customize the system

4. **Add your files** (`images/my-image/setupfiles/`)
   - Configurations (.bashrc, .vimrc, etc.)
   - Scripts
   - SSH keys
   - Etc.

5. **Build the image**
   ```bash
   ./bin/autobuild --image my-image
   ```

## Build All Images

```bash
./bin/autobuild --all-images
```

## Image Examples

### "exemple" Image
Base image with:
- Essential packages (vim, git, htop, python3)
- Optimized network configuration
- Timezone Europe/Paris
- French locale

### Create a Docker Image
```bash
cp -r images/exemple images/docker
```

Modify `images/docker/setup.sh`:
```bash
# Add Docker
apt install -y docker.io docker-compose
systemctl enable docker
usermod -aG docker pi
```

Build:
```bash
./bin/autobuild --image docker
```

### Create a Web Server Image
```bash
cp -r images/exemple images/webserver
```

Modify `images/webserver/setup.sh`:
```bash
# Install Nginx
apt install -y nginx php-fpm mariadb-server
systemctl enable nginx mariadb
```

Build:
```bash
./bin/autobuild --image webserver
```