# Creating Custom Images

Guide to creating your own image configurations.

## Quick Start

```bash
# 1. Copy base configuration
cp -r images/debian images/myproject

# 2. Edit config
vim images/myproject/config.sh

# 3. Customize setup
vim images/myproject/services/base/setup.sh

# 4. Build
./bin/autobuild --image myproject
```

## Configuration File (config.sh)

**Required variables**:
```bash
OUTPUT_IMAGE="myproject.img"
IMAGE_SIZE="8G"
QEMU_RAM="4G"
QEMU_CPUS="4"
CLOUD=true  # or false
IMAGE_URL="https://cloud.debian.org/images/cloud/trixie-backports/daily/latest/debian-13-backports-genericcloud-arm64-daily.raw"
SERVICES="base qemu docker"
DESCRIPTION="My custom image"
```

## Using Service Composition

**Dynamic images** - compose from existing services:
```bash
./bin/autobuild --image debian/qemu+docker+myservice
```

**Physical images** - full custom directory:
```bash
./bin/autobuild --image myproject
```

See [Services - Creating Custom Services](Services/#creating-custom-services) for adding new service modules.

## Examples

**Minimal Debian**:
```bash
SERVICES="base"
IMAGE_SIZE="4G"
```

**Docker host**:
```bash
SERVICES="base docker"
IMAGE_SIZE="8G"
```

**Custom service stack**:
```bash
SERVICES="base qemu docker myapp"
IMAGE_SIZE="16G"
```

## Next Steps

- [Build system options](Build-System.md)
- [Create custom service](Services/#creating-custom-services)
- [GitHub Actions CI/CD](GitHub-Actions.md)