# GitHub Actions - Automated Build

This folder contains GitHub Actions workflows for automatically building Raspberry Pi images.

## `build-images.yml` Workflow

### Triggers

The workflow triggers in the following cases:

1. **Push to any branch**: On every pushed commit
2. **Daily schedule**: Every day at 2:00 AM UTC
3. **Manual trigger**: Via the GitHub Actions interface

### Build Process

1. **Environment preparation**
   - Free up disk space (~14GB)
   - Install dependencies (QEMU, parted, rsync, etc.)
   - Install PiShrink
   - Enable loop devices

2. **Build images**
   - Execute `./bin/autobuild --all-images`
   - Build all images defined in `images/`
   - Compress with PiShrink

3. **Create release**
   - Date-based tag: `vYYYY-MM-DD-HHMM`
   - **`main` branch** → Normal release
   - **Other branches** → Pre-release
   - Upload all `.img.xz` files

### Release Types

#### Release (`main` branch)
- Tag: `v2025-01-15-1430`
- Name: `Release 2025-01-15`
- Status: Stable release

#### Pre-release (other branches)
- Tag: `v2025-01-15-1430`
- Name: `Pre-release 2025-01-15 (dev)`
- Status: Pre-release

### Artifacts

Each release contains:
- All generated `.img.xz` files
- Build information (branch, commit, date)
- Flashing instructions

In case of failure, artifacts are kept for 7 days.

## Limitations

### Loop Devices

The workflow requires access to loop devices for:
- Mounting disk images
- Manipulating partitions
- Merging RaspiOS and Debian

**GitHub Actions ubuntu-latest runners** have loop devices, but for intensive production use, consider a **self-hosted runner**.

### Disk Space

The build requires approximately:
- ~3-4 GB per Debian image
- ~2-3 GB per RaspiOS image
- ~1-2 GB for final images

The workflow automatically frees ~14GB by removing unused tools.

### Build Duration

- Single image build: ~10-20 minutes (depending on QEMU)
- All images build: ~30-60 minutes
- GitHub Actions limit: 6 hours (more than sufficient)

## Required Configuration

### Permissions

The workflow requires:
```yaml
permissions:
  contents: write  # To create releases and tags
```

### Secrets

No additional secrets required. The workflow uses the automatically provided `GITHUB_TOKEN`.

## Customization

### Change daily build time

Edit `.github/workflows/build-images.yml`:

```yaml
schedule:
  - cron: '0 2 * * *'  # Modify the time here (format: minute hour * * *)
```

### Disable daily build

Comment out or remove the `schedule` section:

```yaml
on:
  push:
    branches:
      - '**'
  # schedule:
  #   - cron: '0 2 * * *'
  workflow_dispatch:
```

### Build only on main

Edit `.github/workflows/build-images.yml`:

```yaml
on:
  push:
    branches:
      - main  # Only the main branch
```

## Self-Hosted Runner

To use a self-hosted runner with more resources:

1. **Configure the runner**
   ```yaml
   jobs:
     build-images:
       runs-on: self-hosted  # Instead of ubuntu-latest
   ```

2. **Install dependencies** on the runner
   ```bash
   sudo apt install -y qemu-system-aarch64 qemu-utils qemu-efi-aarch64 \
                       parted e2fsprogs dosfstools rsync xz-utils genisoimage
   ```

3. **Advantages**
   - More CPU/RAM available
   - Faster builds
   - No strict time limit
   - Full control over the environment

## Troubleshooting

### Build fails with "No space left on device"

The workflow already frees ~14GB. If insufficient:
- Use a self-hosted runner with more space
- Reduce the number of images to build
- Reduce image size in `config.sh`

### Loop devices are not available

On GitHub Actions ubuntu-latest, loop devices should be available. If there's a problem:
- Check the logs from the "Enable loop devices" step
- Use a self-hosted runner
- Contact GitHub support

### PiShrink fails

PiShrink requires sudo. The workflow already uses `sudo pishrink.sh`.
If error:
- Check detailed logs
- Test locally to reproduce
- Use `--skip-compress` temporarily

## Monitoring

### View running builds

1. Go to the **Actions** tab of the repo
2. Click on the **Build Raspberry Pi Images** workflow
3. View current/past runs

### Notifications

GitHub sends notifications by default:
- Email on failure
- Email on success (if configured)

To configure:
1. Settings → Notifications
2. Actions → Success/Failure