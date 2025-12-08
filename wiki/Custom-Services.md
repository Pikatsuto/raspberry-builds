# Creating Custom Services

Guide to creating new service modules.

## Service Structure

```
images/debian/services/myservice/
├── setup.sh              # Package installation (runs in QEMU)
├── first-boot/init.sh    # Runtime config (runs on first boot)
├── setupfiles/           # Static files → /etc/setupfiles/
├── depends.sh            # Optional: dependencies
└── motd.sh               # Optional: MOTD banner
```

## Quick Template

```bash
# Create service
mkdir -p images/debian/services/myservice/first-boot

# Package installation
cat > images/debian/services/myservice/setup.sh <<'EOF'
#!/bin/bash
set -e
apt update
apt install -y nginx
systemctl enable nginx
EOF
chmod +x images/debian/services/myservice/setup.sh

# Runtime configuration
cat > images/debian/services/myservice/first-boot/init.sh <<'EOF'
#!/bin/bash
set -e
systemctl start nginx
EOF
chmod +x images/debian/services/myservice/first-boot/init.sh

# Build
./bin/autobuild --image debian/myservice
```

## Script Guidelines

**setup.sh** (runs in QEMU):
- Install packages
- Configure system
- Enable services (don't start them)

**first-boot/init.sh** (runs on Raspberry Pi):
- Detect hardware
- Download large files
- Create containers/VMs
- Start services

## Dependencies

Create `depends.sh`:
```bash
DEPENDS_ON="qemu"  # This service requires qemu
```

## Advanced Topics

For detailed information see [Services Guide](Services.md):
- Service lifecycle
- Hardware detection
- Best practices
- Debugging