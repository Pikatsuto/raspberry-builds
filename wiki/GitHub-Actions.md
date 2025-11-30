# GitHub Actions - Automated Build System

This page documents the automated build system powered by GitHub Actions. The workflow automatically builds all Raspberry Pi images, compresses them, and creates GitHub releases with ready-to-flash `.img.xz` files.

## Overview

The GitHub Actions workflow (`.github/workflows/build-images.yml`) provides a complete CI/CD pipeline for building Raspberry Pi images. It automatically:

1. Detects all available images in the `images/` directory
2. Downloads base images (RaspiOS + Debian)
3. Executes setup scripts in QEMU ARM64
4. Creates hybrid images
5. Compresses images with PiShrink
6. Creates GitHub releases with downloadable assets

## Workflow Triggers

The workflow runs automatically on:

### 1. Push Events
- **Trigger**: Any push to any branch
- **Branches**: `**` (all branches)
- **Purpose**: Immediate build on code changes
- **Release Type**:
  - `main` branch → Stable release
  - Other branches → Pre-release

### 2. Scheduled Builds
- **Trigger**: Daily at 2:00 AM UTC
- **Schedule**: `cron: '0 2 * * *'`
- **Purpose**: Fetch latest Debian and RaspiOS base images
- **Benefit**: Images stay up-to-date with security patches and new features

### 3. Manual Dispatch
- **Trigger**: Manual workflow run via GitHub Actions UI
- **Purpose**: Build on-demand without pushing code
- **Usage**: Go to Actions tab → Select workflow → "Run workflow"

## Build Architecture

The workflow uses a **4-stage parallel build system** with artifact caching to optimize build time and resource usage.

```
┌─────────────────────────────────────────────────────────────┐
│ Job 1: detect-images                                        │
│  └─ Scans images/ directory and outputs image list         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Job 2: stage1-download (Parallel per image)                │
│  ├─ Downloads RaspiOS and Debian base images               │
│  ├─ Creates setup.iso from setup.sh + setupfiles/          │
│  └─ Uploads artifacts: *.img, *.raw, seed.img, setup.iso   │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Job 3: stage2-qemu (Parallel per image)                    │
│  ├─ Downloads artifacts from stage1                        │
│  ├─ Launches QEMU ARM64 with Debian + setup.iso            │
│  ├─ Executes setup.sh in native ARM64 environment          │
│  ├─ Installs RaspiOS kernel/firmware via APT               │
│  └─ Uploads configured Debian image                        │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Job 4: stage3-build (Parallel per image)                   │
│  ├─ Downloads RaspiOS from stage1                          │
│  ├─ Downloads configured Debian from stage2                │
│  ├─ Runs merge-debian-raspios.sh                           │
│  └─ Uploads hybrid image (rpi-*.img)                       │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Job 5: stage4-compress (Parallel per image)                │
│  ├─ Downloads hybrid image from stage3                     │
│  ├─ Compresses with PiShrink + xz                          │
│  └─ Uploads final image (rpi-*.img.xz)                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Job 6: create-release                                       │
│  ├─ Downloads all final images (rpi-*.img.xz)              │
│  ├─ Generates release name and tag                         │
│  ├─ Creates GitHub release with build info                 │
│  └─ Uploads all .img.xz files as release assets            │
└─────────────────────────────────────────────────────────────┘
```

## Detailed Job Breakdown

### Job 1: detect-images

**Purpose**: Dynamic image detection

**Steps**:
1. Checkout repository
2. Scan `images/` directory
3. Extract directory names (basename)
4. Convert to JSON array for matrix strategy
5. Output image list to GitHub Actions outputs

**Output**: JSON array like `["raspivirt-incus", "raspivirt-incus+docker"]`

**Code**:
```bash
images=$(ls -d images/*/ | xargs -n 1 basename | jq -R -s -c 'split("\n")[:-1]')
```

### Job 2: stage1-download

**Purpose**: Download and prepare base images

**Strategy**: Matrix parallelization (one job per image)

**Steps**:
1. **Free disk space**: Remove unused packages to prevent disk full errors
   - Removes: .NET, Android SDK, GHC, CodeQL, Docker images
   - Frees ~40GB of space
2. **Install dependencies**: `wget`, `genisoimage`, `xz-utils`
3. **Run autobuild stage 1**: `./bin/autobuild --image <name> --stage 1`
   - Downloads RaspiOS image (if missing)
   - Downloads Debian image (if missing)
   - Creates `setup.iso` from `setup.sh` + `setupfiles/`
   - Regenerates cloud-init `seed.img`
4. **Upload artifacts**:
   - RaspiOS image (`*.img`)
   - Debian image (`*.raw`)
   - Cloud-init seed (`seed.img`)
   - Setup ISO (`setup.iso`)
   - Retention: 1 day

**Artifact Size**: ~2-4GB per image

### Job 3: stage2-qemu

**Purpose**: Execute setup script in QEMU ARM64

**Strategy**: Matrix parallelization (one job per image)

**Timeout**: 60 minutes (safety limit for long-running setups)

**Steps**:
1. **Install QEMU dependencies**:
   - `qemu-system-aarch64`: ARM64 system emulator
   - `qemu-utils`: Image utilities
   - `qemu-efi-aarch64`: UEFI firmware for ARM64
2. **Download artifacts from stage1**:
   - RaspiOS image (needed for reference)
   - Debian image (modified during setup)
   - Cloud-init seed (first-boot configuration)
   - Setup ISO (contains setup.sh + files)
3. **Run autobuild stage 2**: `./bin/autobuild --image <name> --stage 2`
   - Creates working copy of Debian image
   - Launches QEMU ARM64 with:
     - Debian image as main disk
     - Cloud-init seed for user configuration
     - Setup ISO for package installation
   - QEMU executes setup.sh in native ARM64:
     - System update (`apt update && apt upgrade`)
     - Essential packages (curl, wget, sudo, SSH, etc.)
     - RaspiOS repository configuration + APT pinning
     - RaspiOS kernel/firmware installation
     - Image-specific software (Incus, Docker, etc.)
     - Service configuration
   - Waits for automatic poweroff signal
4. **Upload configured Debian image**:
   - Debian image with RaspiOS kernel + custom software
   - Retention: 1 day
   - Compression disabled (speed optimization)

**Artifact Size**: ~3-6GB per image

**Key Feature**: Native ARM64 execution ensures compatibility and proper package installation

### Job 4: stage3-build

**Purpose**: Create hybrid Raspberry Pi image

**Strategy**: Matrix parallelization (one job per image)

**Steps**:
1. **Install build dependencies**:
   - `parted`: Partition management
   - `e2fsprogs`: ext4 filesystem tools
   - `dosfstools`: FAT32 filesystem tools
   - `rsync`: Efficient file copying
   - `qemu-utils`: Image conversion
2. **Enable loop devices**: Load kernel module for disk image mounting
3. **Download artifacts**:
   - RaspiOS image from stage1 (boot partition source)
   - Configured Debian image from stage2 (rootfs source)
4. **Run autobuild stage 3**: `./bin/autobuild --image <name> --stage 3`
   - Executes `merge-debian-raspios.sh`:
     - Creates output image based on RaspiOS
     - Resizes to configured IMAGE_SIZE
     - Mounts both images via loop devices
     - Deletes RaspiOS root partition content
     - Copies Debian rootfs (with RaspiOS kernel pre-installed)
     - Restores RaspiOS `/etc/fstab`
     - Creates `/boot/firmware` mount point
     - Unmounts and cleans up
5. **Upload hybrid image**:
   - Final bootable image (`rpi-*.img`)
   - Retention: 1 day
   - Compression disabled (PiShrink does this in stage 4)

**Artifact Size**: Matches IMAGE_SIZE (e.g., 6GB for raspivirt-incus)

**Result**: Bootable Raspberry Pi image ready for compression

### Job 5: stage4-compress

**Purpose**: Shrink and compress final images

**Strategy**: Matrix parallelization (one job per image)

**Steps**:
1. **Install PiShrink**:
   - Downloads from official repository
   - Moves to `/usr/local/bin/`
2. **Download hybrid image from stage3**
3. **Run autobuild stage 4**: Compresses with PiShrink
   - Executes: `sudo pishrink.sh -aZ <image>.img`
   - `-a`: Aggressive compression
   - `-Z`: Parallel xz compression
   - Process:
     - Shrinks filesystem to minimum size
     - Removes unused space from partition
     - Truncates image file
     - Compresses to `.img.xz`
4. **Upload final image**:
   - Compressed image (`rpi-*.img.xz`)
   - Retention: 7 days
   - Typical compression: 6GB → 1-2GB

**Artifact Size**: ~1-2GB per image (compressed)

**Compression Ratio**: Typically 60-80% size reduction

### Job 6: create-release

**Purpose**: Create GitHub release with all final images

**Permissions**: `contents: write` (required for release creation)

**Steps**:
1. **Download all compressed images**:
   - Pattern: `final-image-*`
   - Merges all image artifacts
2. **List built images**: Display file sizes for verification
3. **Generate release information**:
   - **Release tag**: `v<YYYY-MM-DD>-<HHMM>` (e.g., `v2025-12-01-1430`)
   - **Release name**:
     - Main branch: `Release <YYYY-MM-DD>`
     - Other branches: `Pre-release <YYYY-MM-DD> (<branch-name>)`
   - **Pre-release flag**:
     - Main branch: `false` (stable release)
     - Other branches: `true` (experimental release)
4. **Create release body**: Markdown with:
   - Build date
   - Flash instructions
   - Build information (branch, commit, workflow link)
   - Documentation links
5. **Create GitHub release**:
   - Uses `gh release create` CLI
   - Uploads all `.img.xz` files as assets
   - Sets pre-release flag based on branch
6. **Cleanup**: Remove large files to free disk space

**Release Example**:
```
Tag: v2025-12-01-1430
Name: Release 2025-12-01
Assets:
  - rpi-raspivirt-incus.img.xz (1.2 GB)
  - rpi-raspivirt-incus+docker.img.xz (1.5 GB)
```

## Artifact Management

### Artifact Flow

```
stage1 → stage2: Base images (RaspiOS, Debian, seed.img, setup.iso)
stage2 → stage3: Configured Debian image
stage3 → stage4: Hybrid image (rpi-*.img)
stage4 → release: Final compressed image (rpi-*.img.xz)
```

### Retention Policy

- **Stage 1-4 artifacts**: 1 day (temporary build artifacts)
- **Final compressed images**: 7 days (backup before release)
- **Release assets**: Permanent (until manually deleted)

### Compression Strategy

- **Stage 1-3**: No compression (speed optimization)
- **Stage 4**: Full compression with PiShrink + xz
- **Rationale**: Intermediate artifacts are deleted quickly; only final images need compression

## Optimization Strategies

### 1. Parallel Execution
- All images build simultaneously (matrix strategy)
- Total build time = slowest image (not sum of all images)

### 2. Stage Separation
- Each stage uploads artifacts for the next stage
- Failed stages don't rebuild earlier stages
- Easy to retry individual stages

### 3. Artifact Caching
- Reuses artifacts across jobs
- Avoids redundant downloads and builds
- Reduces total workflow time

### 4. Disk Space Management
- Removes unused software before builds
- Cleans up artifacts after each stage
- Prevents out-of-disk errors on GitHub runners

### 5. Fail-Fast Disabled
- `fail-fast: false` in stage2 (QEMU)
- One failing image doesn't stop others
- Maximizes successful builds

## Environment Variables

### Global Environment
```yaml
env:
  DEBIAN_FRONTEND: noninteractive
```
- Prevents interactive prompts during apt operations
- Required for unattended package installation

### Job-Specific Variables
- Passed via autobuild script stages
- Configured in `images/<name>/config.sh`:
  - `OUTPUT_IMAGE`: Final filename
  - `IMAGE_SIZE`: Target image size
  - `QEMU_RAM`: RAM for QEMU
  - `QEMU_CPUS`: CPU cores for QEMU

## Release Versioning

### Version Format
- **Pattern**: `vYYYY-MM-DD-HHMM`
- **Example**: `v2025-12-01-1430` (December 1, 2025 at 14:30)
- **Uniqueness**: Timestamp ensures unique tags

### Release Types

#### Stable Release (main branch)
- **Name**: `Release YYYY-MM-DD`
- **Flag**: `prerelease: false`
- **Purpose**: Production-ready images
- **Visibility**: Featured on repository homepage

#### Pre-Release (other branches)
- **Name**: `Pre-release YYYY-MM-DD (branch-name)`
- **Flag**: `prerelease: true`
- **Purpose**: Testing and development
- **Visibility**: Listed but marked as pre-release

## Build Duration

Typical build times on GitHub runners (ubuntu-latest):

- **Stage 1 (Download)**: 3-5 minutes per image
- **Stage 2 (QEMU)**: 15-30 minutes per image (most time-consuming)
- **Stage 3 (Build)**: 5-10 minutes per image
- **Stage 4 (Compress)**: 3-5 minutes per image
- **Stage 5 (Release)**: 1-2 minutes

**Total Time**: ~30-50 minutes for all images (parallel execution)

## Monitoring Builds

### Via GitHub UI
1. Go to repository **Actions** tab
2. Select workflow run
3. View job progress and logs
4. Check artifacts and releases

### Via GitHub CLI
```bash
# List recent workflow runs
gh run list --workflow=build-images.yml

# Watch a running workflow
gh run watch <run-id>

# Download artifacts
gh run download <run-id>
```

## Troubleshooting

### Build Failures

#### Stage 1 Failures
- **Symptom**: Download errors
- **Cause**: Network issues, broken URLs
- **Solution**: Check base image URLs in `autobuild` script

#### Stage 2 Failures (QEMU)
- **Symptom**: QEMU timeout or setup.sh errors
- **Cause**: Package installation failures, network issues in QEMU
- **Solution**: Check `setup.sh` syntax, verify package names
- **Debugging**: Add `set -x` to `setup.sh` for verbose output

#### Stage 3 Failures
- **Symptom**: Merge errors, loop device issues
- **Cause**: Insufficient permissions, partition layout issues
- **Solution**: Verify image formats, check merge script logic

#### Stage 4 Failures
- **Symptom**: PiShrink errors
- **Cause**: Filesystem corruption, insufficient disk space
- **Solution**: Check stage 3 output, verify filesystem integrity

### Disk Space Issues
- **Symptom**: "No space left on device"
- **Solution**: Already handled by "Free disk space" step
- **If persists**: Reduce IMAGE_SIZE in config.sh

### Release Creation Failures
- **Symptom**: Permission denied errors
- **Cause**: Missing `contents: write` permission
- **Solution**: Verify workflow permissions in YAML

## Customizing the Workflow

### Adding a New Build Stage

1. Add new job to `.github/workflows/build-images.yml`
2. Define dependencies with `needs: [previous-job]`
3. Add matrix strategy if parallel execution needed
4. Upload artifacts for next stage
5. Update artifact retention as needed

### Changing Build Frequency

Edit the `schedule` trigger:
```yaml
schedule:
  # Build every 6 hours
  - cron: '0 */6 * * *'
```

### Disabling Automatic Builds

Comment out unwanted triggers:
```yaml
# on:
#   push:
#     branches:
#       - '**'
#   schedule:
#     - cron: '0 2 * * *'
  workflow_dispatch:  # Keep manual trigger only
```

## Best Practices

### For Image Developers
1. **Test locally first**: Run `./bin/autobuild --image <name>` before pushing
2. **Small iterations**: Commit small changes to debug issues faster
3. **Monitor logs**: Check Actions tab for build output
4. **Use branches**: Test in feature branches before merging to main

### For Repository Maintainers
1. **Review PRs carefully**: Malicious setup.sh could compromise runners
2. **Monitor disk usage**: Adjust retention policies if needed
3. **Update base images**: Keep RaspiOS and Debian URLs current
4. **Clean old releases**: Remove outdated releases periodically

## Security Considerations

### Runner Security
- Workflows run in isolated GitHub-hosted runners
- Each job runs in a fresh VM
- Artifacts are sandboxed
- No access to repository secrets (unless explicitly added)

### Image Security
- Setup scripts run with root privileges in QEMU
- Only trusted contributors should modify setup.sh
- Review all package installations
- Avoid hardcoded credentials

### Release Security
- Releases are public by default
- Verify checksums before flashing images
- Use HTTPS for all downloads

## Performance Metrics

### Resource Usage (per image)
- **CPU**: 4 cores (QEMU)
- **RAM**: 8GB (QEMU)
- **Disk**: ~20GB peak usage
- **Network**: ~2GB download (base images)

### GitHub Actions Limits
- **Concurrent jobs**: 20 (free tier)
- **Job timeout**: 6 hours (we set 60 min for QEMU)
- **Artifact size**: 10GB per file
- **Total storage**: 500MB artifacts (free tier)

## Future Improvements

Potential enhancements:

1. **Caching base images**: Store RaspiOS/Debian images in GitHub cache
2. **Incremental builds**: Only rebuild changed images
3. **Build matrix**: Test multiple Debian versions
4. **Checksum verification**: Add SHA256 checksums to releases
5. **Build badges**: Display build status in README
6. **Multi-architecture**: Support x86_64 images for testing

## Related Documentation

- **[Home](Home)**: Project overview
- **[Main README](../README.md)**: Complete documentation
- **[CLAUDE.md](../CLAUDE.md)**: Technical architecture details
- **GitHub Actions**: [Official documentation](https://docs.github.com/en/actions)