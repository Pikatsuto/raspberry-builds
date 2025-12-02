# Contributing to RPI-Dev

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the Raspberry Pi + Debian hybrid image builder.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Image Development](#image-development)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior via GitHub issues.

## Getting Started

### Prerequisites

- Linux system (Debian/Ubuntu recommended)
- Required packages:
  ```bash
  sudo apt install -y parted e2fsprogs dosfstools qemu-utils rsync xz-utils genisoimage qemu-system-aarch64
  ```
- Basic knowledge of Bash scripting
- Understanding of Raspberry Pi boot process and Debian systems

### Understanding the Project

Before contributing, please read:
- [README.md](README.md) - Project overview
- [Wiki](https://github.com/Pikatsuto/raspberry-builds/wiki) - Detailed technical documentation
- [.github/README.md](.github/README.md) - CI/CD workflow documentation

## How to Contribute

### Types of Contributions

We welcome:
- **Bug fixes** - Fix issues with existing functionality
- **New image configurations** - Add new pre-configured images in `images/`
- **Script improvements** - Enhance build scripts, error handling, or performance
- **Documentation** - Improve README, comments, or technical documentation
- **CI/CD enhancements** - Improve GitHub Actions workflows
- **Testing** - Add tests or improve test coverage

## Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
git clone https://github.com/Pikatsuto/raspberry-builds.git
cd rpi-dev
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Branch naming conventions:
- `feature/` - New features or enhancements
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `ci/` - CI/CD changes

### 3. Make Changes

- Follow existing code style and conventions
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation if needed

### 4. Test Locally

```bash
# Test with a specific image
./bin/autobuild --image exemple

# Test with --skip-download for faster iteration
./bin/autobuild --image exemple --skip-download

# Test merge script directly
./bin/merge-debian-raspios.sh raspios.img debian.raw -o test-output.img
```

### 5. Commit Changes

```bash
git add .
git commit -m "type: brief description"
```

Commit message format:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `ci:` - CI/CD changes
- `refactor:` - Code refactoring
- `test:` - Adding tests

Example:
```
feat: add support for custom partition sizes
fix: resolve boot partition mounting issue
docs: update CONTRIBUTING.md with testing guidelines
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Image Development

### Creating a New Image Configuration

1. Copy the example image:
   ```bash
   cp -r images/exemple images/your-image-name
   ```

2. Edit `config.sh`:
   ```bash
   vim images/your-image-name/config.sh
   ```
   Set: `OUTPUT_IMAGE`, `IMAGE_SIZE`, `QEMU_RAM`, `QEMU_CPUS`, `DESCRIPTION`

3. Customize `setup.sh`:
   ```bash
   vim images/your-image-name/setup.sh
   ```
   Add package installations, configurations, etc.

4. Add custom files to `setupfiles/`:
   ```bash
   cp your-config.conf images/your-image-name/setupfiles/
   ```

5. Choose boot configuration mode:
   - **first-boot/** - Recommended for generic Debian images
   - **cloudinit/** - For Debian cloud images with cloud-init

6. Test your image:
   ```bash
   ./bin/autobuild --image your-image-name
   ```

### Image Guidelines

- Keep `setup.sh` scripts idempotent (can run multiple times safely)
- Use proper error handling (`set -euo pipefail`)
- Document any special requirements in comments
- Minimize image size where possible
- Test on actual Raspberry Pi hardware if available

## Submitting Changes

### Pull Request Guidelines

- **Title**: Clear, descriptive title following commit conventions
- **Description**: Explain what changes you made and why
- **Testing**: Describe how you tested your changes
- **Screenshots**: Include if relevant (especially for documentation changes)
- **Breaking changes**: Clearly mark any breaking changes

### PR Checklist

Before submitting, ensure:
- [ ] Code follows project style and conventions
- [ ] Changes have been tested locally
- [ ] Documentation has been updated if needed
- [ ] Commit messages follow the format guidelines
- [ ] No merge conflicts with main branch
- [ ] All checks pass in CI/CD

### Review Process

1. Maintainers will review your PR
2. Address any requested changes
3. Once approved, your PR will be merged
4. Your contribution will be included in the next release

## Reporting Bugs

### Before Submitting a Bug Report

- Check existing issues to avoid duplicates
- Verify the bug exists in the latest version
- Collect relevant information (error messages, logs, system info)

### Bug Report Template

Use the bug report issue template and include:
- **Description**: Clear description of the bug
- **Steps to reproduce**: Detailed steps to reproduce the issue
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: OS, versions, hardware details
- **Logs**: Relevant error messages or log output

## Feature Requests

We welcome feature requests! Please use the feature request issue template and include:
- **Problem description**: What problem does this solve?
- **Proposed solution**: How should it work?
- **Alternatives**: Any alternative solutions considered?
- **Additional context**: Screenshots, examples, etc.

## Questions?

If you have questions:
- Check the [Wiki](https://github.com/Pikatsuto/raspberry-builds/wiki) for detailed technical documentation
- Search existing issues
- Create a new issue with the question label

## License

By contributing, you agree that your contributions will be licensed under the GNU Lesser General Public License v2.1 (LGPL-2.1).

Thank you for contributing!