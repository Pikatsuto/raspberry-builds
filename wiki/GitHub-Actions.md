# GitHub Actions CI/CD

Automated image builds and releases using GitHub Actions.

## Overview

The project includes a sophisticated multi-stage CI/CD pipeline that:
- Builds images in parallel
- Creates GitHub releases automatically
- Uploads compressed images as release assets
- Supports multiple branch strategies (stable, test, preview)
- Runs daily builds

## Workflow Architecture

### Build Pipeline (`.github/workflows/build-images.yml`)

**6-job multi-stage pipeline**:

```
detect-images
     ↓
     ├─→ stage1-2-download-qemu (parallel matrix)
     │   └─→ stage3-build (sequential)
     │       └─→ stage4-compress (sequential)
     │
     └─→ create-release (parallel)
         └─→ cleanup-release (final)
```

### Job Descriptions

**1. detect-images**
- Reads `.github/images.txt`
- Outputs list of images to build
- Sets up matrix for parallel builds

**2. stage1-2-download-qemu**
- Downloads RaspiOS and Debian base images
- Runs QEMU setup (installs packages)
- Uploads artifacts: Debian image, setup files

**3. create-release**
- Determines release tag (daily vs push)
- Creates GitHub release (or updates existing)
- Sets release as pre-release for non-main branches

**4. stage3-build**
- Downloads artifacts from stage1-2
- Merges RaspiOS + Debian
- Uploads merged image artifact

**5. stage4-compress**
- Downloads merged image
- Compresses with PiShrink + xz
- Uploads compressed image to GitHub release

**6. cleanup-release**
- Deletes release if no assets uploaded (failure)
- Always runs, even on failure

---

## Setting Up CI/CD

### 1. Fork/Clone Repository

```bash
git clone https://github.com/Pikatsuto/raspberry-builds.git
cd raspberry-builds
```

### 2. Configure Images to Build

Edit `.github/images.txt`:

```
debian
debian/qemu+docker
debian/qemu+haos
debian/qemu+docker+openwrt+hotspot+haos
```

One image per line. Comments with `#` supported.

### 3. Push to GitHub

```bash
git add .github/images.txt
git commit -m "Configure CI/CD images"
git push origin main
```

### 4. Enable GitHub Actions

- Go to repository Settings → Actions → General
- Enable "Allow all actions and reusable workflows"
- Save

### 5. Enable GitHub Pages (for docs)

- Go to repository Settings → Pages
- Source: GitHub Actions
- Save

### 6. Trigger First Build

**Manual trigger**:
- Go to Actions tab
- Select "Build Raspberry Pi Images" workflow
- Click "Run workflow"
- Select branch (main)
- Click "Run workflow"

**Automatic trigger**:
- Push changes to `images/**`, `bin/**`, or `.github/**`
- Wait for daily cron (2:00 AM UTC)

---

## Triggers

### Push Trigger

```yaml
on:
  push:
    branches:
      - main
      - test
      - preview
    paths:
      - 'images/**'
      - 'bin/**'
      - '.github/**'
```

**Behavior**:
- Only triggers when image configs or build scripts change
- Ignores documentation-only changes
- Supports main, test, preview branches

### Schedule Trigger

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2:00 AM UTC
```

**Behavior**:
- Runs daily to capture latest base images
- Builds all images from `.github/images.txt`
- Creates `daily-YYYY-MM-DD` release

### Manual Trigger

```yaml
on:
  workflow_dispatch:
```

**Behavior**:
- Run from GitHub Actions UI
- Useful for testing or on-demand builds
- Supports branch selection

---

## Release Strategy

### Release Tagging

**Daily builds** (cron):
```
Tag: daily-YYYY-MM-DD
Example: daily-2024-12-08
```
- Overwrites existing daily release
- Always pre-release

**Push builds**:
```
Tag: vYYYY-MM-DD-HHMM
Example: v2024-12-08-1430
```
- Unique timestamp for each build
- Pre-release for test/preview branches
- Stable release for main branch

### Branch Strategy

**main branch**:
- Stable releases
- No pre-release flag
- Recommended for production

**test branch**:
- Pre-releases with warning banner
- For testing new features
- May contain bugs

**preview branch**:
- Experimental pre-releases
- Bleeding-edge features
- Use at your own risk

### Release Notes

Auto-generated release notes include:
- List of images built
- Download links
- SHA256 checksums
- Installation instructions
- Changelog (if commits since last release)

**Example**:
```markdown
## Raspberry Pi Images - v2024-12-08-1430

### Images Built
- debian-base.img.xz
- debian-qemu-docker.img.xz
- debian-qemu-haos.img.xz

### Installation
1. Download image
2. Verify checksum
3. Flash to SD card:
   ```bash
   xz -dc image.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
   ```

### Checksums (SHA256)
- debian-base.img.xz: abc123...
- debian-qemu-docker.img.xz: def456...
```

---

## Artifacts

### Uploaded Artifacts (Intermediate)

Used for passing data between stages:

**stage1-2-download-qemu**:
- `debian-<image>-image` - Configured Debian image
- `setup-iso-<image>` - Setup scripts
- `setupfiles-<image>` - Configuration files

**stage3-build**:
- `hybrid-<image>-image` - Merged image (uncompressed)

**Retention**: 1 day (deleted after stage4 completes)

### Release Assets (Final)

Uploaded to GitHub Releases:

- `<image-name>.img.xz` - Compressed image
- `<image-name>.img.xz.sha256` - Checksum

**Retention**: Permanent (until manually deleted)

---

## Customizing Workflow

### Adjust Runner Resources

For faster builds, use larger runners:

```yaml
jobs:
  stage1-2-download-qemu:
    runs-on: ubuntu-latest  # Change to ubuntu-latest-4-cores or custom runner
```

**Options**:
- `ubuntu-latest` - 2 cores, 7GB RAM (free)
- `ubuntu-latest-4-cores` - 4 cores, 16GB RAM (paid)
- Self-hosted runners

### Adjust QEMU Timeout

Increase timeout for slow builds:

```yaml
env:
  QEMU_TIMEOUT: 3600  # 1 hour (default: 1800 = 30 min)
```

### Parallel Image Builds

By default, images build in parallel via matrix strategy. To limit parallelism:

```yaml
strategy:
  matrix:
    image: ${{ fromJson(needs.detect-images.outputs.images) }}
  max-parallel: 2  # Limit to 2 concurrent builds
```

### Skip Compression

To speed up testing builds:

```yaml
- name: Build image
  run: ./bin/autobuild --image ${{ matrix.image }} --skip-compress
```

### Custom Base Images

Override base image URLs via environment variables:

```yaml
env:
  RASPIOS_URL: https://example.com/custom-raspios.img.xz
  DEBIAN_URL: https://example.com/custom-debian.raw
```

---

## Monitoring Builds

### GitHub Actions UI

**View running builds**:
1. Go to Actions tab
2. Click on running workflow
3. Click on job to see logs

**Check build status**:
- Green checkmark: Success
- Red X: Failure
- Yellow circle: In progress

### Logs

**Download logs**:
1. Go to completed workflow run
2. Click "..." (three dots)
3. Select "Download log archive"

**Key log sections**:
- **stage1-2**: QEMU boot, package installation
- **stage3**: Merge operation
- **stage4**: Compression, upload

### Debugging Failures

**QEMU timeout**:
- Increase `QEMU_TIMEOUT`
- Check for interactive prompts in logs
- Verify network connectivity

**Merge failure**:
- Check disk space
- Verify base image URLs
- Review merge logs

**Upload failure**:
- Check GitHub token permissions
- Verify release exists
- Check artifact size limits (2GB per file)

---

## Security Considerations

### GitHub Token

The workflow uses `GITHUB_TOKEN` for:
- Creating releases
- Uploading assets
- Downloading artifacts

**Permissions required**:
```yaml
permissions:
  contents: write  # Create releases, upload assets
  actions: read    # Download artifacts
```

**Token is automatically provided by GitHub Actions** - no manual setup needed.

### Secrets

No secrets required for basic builds. Optional secrets:

**CUSTOM_REGISTRY_TOKEN**:
- For private Docker registries
- Add in Settings → Secrets → Actions

**Usage**:
```yaml
env:
  REGISTRY_TOKEN: ${{ secrets.CUSTOM_REGISTRY_TOKEN }}
```

---

## Cost Optimization

### Free Tier Limits

**GitHub Actions free tier** (public repos):
- Unlimited minutes
- 2 cores, 7GB RAM runners
- No artifact storage cost

**GitHub Actions free tier** (private repos):
- 2000 minutes/month
- Same runner specs
- Artifact storage counted

### Reduce Build Time

**Cache base images**:
- Base images cached between builds
- Use `--skip-download` when possible

**Reduce image count**:
- Remove unused images from `.github/images.txt`
- Build only on significant changes

**Use smaller images**:
- Reduce `IMAGE_SIZE` in config
- Skip unnecessary services

---

## Advanced Workflows

### Build on Pull Request

Add PR trigger to test changes before merge:

```yaml
on:
  pull_request:
    branches:
      - main
    paths:
      - 'images/**'
      - 'bin/**'
```

**Behavior**:
- Builds images without creating release
- Uploads artifacts for testing
- Blocks merge if build fails

### Multi-Architecture Builds

Add ARM64 runner for native builds (no QEMU emulation):

```yaml
jobs:
  build:
    runs-on: [self-hosted, linux, arm64]
```

**Benefits**:
- Faster builds (no emulation overhead)
- Lower resource usage

**Requirements**:
- ARM64 GitHub runner (Raspberry Pi 5, AWS Graviton, etc.)

### Notification on Failure

Send notifications via email/Slack/Discord:

```yaml
- name: Notify on failure
  if: failure()
  uses: actions/notify@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    message: "Build failed: ${{ github.workflow }}"
```

---

## Example: Custom Workflow

**Scenario**: Build only on weekends, upload to custom S3 bucket

```yaml
name: Weekend Builds

on:
  schedule:
    - cron: '0 2 * * 6'  # Saturday at 2 AM UTC

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build images
        run: ./bin/autobuild --all-images

      - name: Upload to S3
        uses: aws-actions/upload-s3@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_KEY }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET }}
          bucket: my-rpi-images
          source: images/**/*.img.xz
```

---

## Next Steps

- [Learn about hardware auto-detection](Hardware-Detection.md)
- [Create custom services](Services.md)
- [Troubleshoot build issues](Troubleshooting.md)