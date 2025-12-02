# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| other branches | :x:     |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in this project, please help us by reporting it responsibly.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by:

1. **Opening a GitHub Security Advisory** (recommended)
   - Go to the [Security tab](../../security/advisories)
   - Click "Report a vulnerability"
   - Provide detailed information about the vulnerability

2. **Creating a private issue**
   - If Security Advisories are not available, create a standard issue
   - Mark it with the `security` label
   - Avoid including sensitive details in the public description

### What to Include

Please include as much of the following information as possible:

- **Type of vulnerability** (e.g., code injection, privilege escalation, insecure defaults)
- **Affected component(s)** (e.g., specific script, image configuration, workflow)
- **Steps to reproduce** the vulnerability
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your environment** (OS, versions, etc.)

### Response Timeline

- **Initial response**: Within 48 hours
- **Assessment**: Within 1 week
- **Fix timeline**: Depends on severity
  - Critical: Immediate fix and release
  - High: Fix within 1-2 weeks
  - Medium/Low: Fix in next release cycle

### Security Considerations for This Project

This project builds custom Raspberry Pi images. Please consider:

#### 1. Image Security

- **Default credentials**: Always change default passwords after first boot
- **SSH access**: Images may have SSH enabled by default - secure it immediately
- **Network exposure**: Review firewall rules and exposed services
- **Package updates**: Run `apt update && apt upgrade` after first boot

#### 2. Build Process Security

- **Downloaded images**: We download base images from official sources (Raspberry Pi OS, Debian)
- **Image verification**: Consider verifying checksums of downloaded base images
- **Build environment**: Use trusted build environments (avoid compromised systems)
- **Custom configurations**: Review `setup.sh` scripts before building images

#### 3. Supply Chain Security

- **Base images**: Downloaded from official Raspberry Pi and Debian repositories
- **Packages**: Installed via official APT repositories (archive.raspberrypi.org, deb.debian.org)
- **Dependencies**: Minimal external dependencies, all from official distro repos
- **GitHub Actions**: Workflows run in GitHub-hosted runners with restricted permissions

#### 4. Known Limitations

- **Cloud-init passwords**: Cloud-init configurations may contain plain text passwords
  - Store `user-data` files securely
  - Change passwords after first boot
  - Consider using SSH keys instead
- **QEMU execution**: Setup scripts run in QEMU during build
  - Review `setup.sh` scripts for malicious commands
  - Avoid running untrusted image configurations
- **Root access**: Build process requires root/sudo access
  - Review scripts before running with elevated privileges
  - Use dedicated build systems if possible

### Best Practices for Users

When using images built by this project:

1. **Change default credentials** immediately after first boot
2. **Update system packages**: `sudo apt update && sudo apt upgrade`
3. **Configure firewall**: Set up `ufw` or `iptables`
4. **Disable unnecessary services**
5. **Enable automatic security updates**: Install `unattended-upgrades`
6. **Use SSH keys** instead of password authentication
7. **Review running services**: `systemctl list-units --type=service`

### Security Updates

Security fixes will be:
- Released as soon as possible after confirmation
- Documented in release notes
- Announced via GitHub releases
- Tagged with `security` label in issues/PRs

### Disclosure Policy

- We follow coordinated disclosure principles
- Security vulnerabilities will be publicly disclosed after a fix is available
- We will credit security researchers (unless they prefer to remain anonymous)

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Raspberry Pi Security Documentation](https://www.raspberrypi.com/documentation/computers/configuration.html#security)
- [Debian Security Information](https://www.debian.org/security/)

Thank you for helping keep this project and its users safe!