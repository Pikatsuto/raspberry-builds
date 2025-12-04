# Wiki Documentation

This directory contains the complete wiki documentation for the RPI-Dev project. The wiki provides comprehensive documentation for users and developers.

## Wiki Structure

- **[Home.md](Home.md)**: Project overview, quick start guide, and main documentation entry point
- **[GitHub-Actions.md](GitHub-Actions.md)**: Detailed documentation of the automated CI/CD build system
- **[Image-RaspiVirt-Incus.md](Image-RaspiVirt-Incus.md)**: Complete guide for the RaspiVirt-Incus image
- **[Image-RaspiVirt-Incus-Docker.md](Image-RaspiVirt-Incus-Docker.md)**: Complete guide for the RaspiVirt-Incus+Docker image
- **[Image-RaspiVirt-Incus-HAOS.md](Image-RaspiVirt-Incus-HAOS.md)**: Complete guide for the RaspiVirt-Incus+HAOS image with Home Assistant OS

## Publishing to GitHub Wiki

GitHub Wikis are separate git repositories. To publish these pages:

### Option 1: Manual Copy (Recommended for Initial Setup)

1. **Enable Wiki** on your GitHub repository:
   - Go to repository Settings → Features
   - Check "Wikis"

2. **Clone the wiki repository**:
   ```bash
   git clone https://github.com/Pikatsuto/raspberry-builds.wiki.git
   cd rpi-dev.wiki
   ```

3. **Copy wiki files**:
   ```bash
   cp ../wiki/*.md .
   rm README.md  # Remove this meta-README
   ```

4. **Commit and push**:
   ```bash
   git add .
   git commit -m "Initial wiki documentation"
   git push origin master
   ```

### Option 2: Automated Sync with GitHub Actions

Create `.github/workflows/sync-wiki.yml`:

```yaml
name: Sync Wiki

on:
  push:
    branches:
      - main
    paths:
      - 'wiki/**'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Checkout wiki
        uses: actions/checkout@v6
        with:
          repository: ${{ github.repository }}.wiki
          path: wiki-repo
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Sync files
        run: |
          cp wiki/*.md wiki-repo/
          cd wiki-repo
          rm -f README.md
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add .
          git diff --quiet && git diff --staged --quiet || \
            (git commit -m "Auto-sync wiki from main repository" && git push)
```

### Option 3: Keep in Repository (No Separate Wiki)

If you prefer to keep documentation in the main repository:

1. **Update internal links** to use relative paths:
   ```markdown
   [GitHub Actions](GitHub-Actions.md) → [GitHub Actions](wiki/GitHub-Actions.md)
   ```

2. **Link from main README**:
   ```markdown
   ## Documentation

   - [Home](wiki/Home.md)
   - [GitHub Actions](wiki/GitHub-Actions.md)
   - [RaspiVirt-Incus Image](wiki/Image-RaspiVirt-Incus.md)
   - [RaspiVirt-Incus+Docker Image](wiki/Image-RaspiVirt-Incus-Docker.md)
   - [RaspiVirt-Incus+HAOS Image](wiki/Image-RaspiVirt-Incus-HAOS.md)
   ```

## Maintaining the Wiki

### Adding a New Image

When adding a new image configuration:

1. **Create image directory**: `images/new-image/`
2. **Create wiki page**: `wiki/Image-New-Image.md`
3. **Update Home.md**: Add link in "Available Images" section
4. **Sync to GitHub Wiki**

### Updating Documentation

When changing image configurations or build process:

1. **Update relevant wiki pages**
2. **Update version/date information**
3. **Commit changes**:
   ```bash
   git add wiki/
   git commit -m "docs: update wiki for <change>"
   git push
   ```
4. **Sync to GitHub Wiki** (if using separate wiki repository)

## Wiki Page Template

When creating a new image page, follow this structure:

```markdown
# Image Name

Brief description of the image.

## Overview

Key features and use cases.

## Image Specifications

- Image name
- Base OS
- Kernel
- Size information

## Installed Software

List of packages and tools.

## Configuration

Network, users, services.

## First-Boot Process

Initialization steps.

## Usage Examples

Common commands and scenarios.

## Use Cases

When to use this image.

## Customization

How to modify the image.

## Troubleshooting

Common issues and solutions.

## Related Documentation

Links to other wiki pages and external docs.

## Build Information

GitHub Actions and download links.
```

## Markdown Formatting

GitHub Wiki supports GitHub Flavored Markdown:

### Code Blocks

\`\`\`bash
# Commands
sudo apt update
\`\`\`

### Links

- Internal: `[GitHub Actions](GitHub-Actions)`
- External: `[Incus Docs](https://linuxcontainers.org/incus/)`
- Relative: `[README](../README.md)`

### Tables

```markdown
| Column 1 | Column 2 |
|----------|----------|
| Data 1   | Data 2   |
```

### Alerts

```markdown
> **Warning**: Important information
```

## Viewing Locally

Preview wiki pages using any markdown viewer:

```bash
# Using grip (GitHub README previewer)
pip install grip
grip wiki/Home.md

# Using markdown-preview (VS Code extension)
# Install "Markdown Preview Enhanced" extension

# Using pandoc
pandoc wiki/Home.md -o preview.html && open preview.html
```

## Contributing

When contributing to the wiki:

1. Follow the existing structure and formatting
2. Keep pages focused and well-organized
3. Include code examples and screenshots where helpful
4. Cross-reference related pages
5. Update the Home page navigation when adding pages
6. Test all commands and code examples before committing

## License

This documentation is provided "as is" without warranty. Use at your own risk.