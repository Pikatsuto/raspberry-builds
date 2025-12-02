# GitHub Pages Setup Guide

This guide explains how to configure GitHub Pages for the Raspberry Pi Builds documentation site.

## Prerequisites

1. Repository: `Pikatsuto/raspberry-builds`
2. GitHub Actions enabled
3. Admin access to repository settings

## Step-by-Step Setup

### 1. Enable GitHub Pages

1. Go to repository Settings
2. Navigate to **Pages** (in the left sidebar)
3. Under **Build and deployment**:
   - **Source**: Select "GitHub Actions"
   - **Branch**: Not applicable (using Actions)

### 2. Configure Workflow Permissions

1. Go to repository Settings
2. Navigate to **Actions** → **General**
3. Scroll to **Workflow permissions**
4. Select **Read and write permissions**
5. Check **Allow GitHub Actions to create and approve pull requests**
6. Click **Save**

### 3. Initial Deployment

The documentation site will automatically deploy when:

- Changes are pushed to the `main` branch that affect:
  - `docs/**` files
  - `wiki/**` files
  - `images/**` configurations
  - `README.md` or `.github/README.md`

**Manual trigger:**

1. Go to **Actions** tab
2. Select "Deploy Documentation to GitHub Pages"
3. Click **Run workflow**
4. Select `main` branch
5. Click **Run workflow** button

### 4. Verify Deployment

1. Go to **Actions** tab
2. Find the running workflow
3. Wait for completion (usually 2-3 minutes)
4. Visit: https://pikatsuto.github.io/raspberry-builds/

## Troubleshooting

### Deployment Fails

**Error: "Resource not accessible by integration"**

- Solution: Check workflow permissions (Step 2)
- Ensure "Read and write permissions" is enabled

**Error: "Pages build failed"**

- Check the Actions log for specific errors
- Verify `baseURL` in `nuxt.config.ts` matches repository name
- Ensure `.nojekyll` file exists in `docs/public/`

### 404 Errors on Deployed Site

**Homepage loads but pages return 404:**

- Check that `baseURL: '/raspberry-builds/'` is set in `nuxt.config.ts`
- Verify static generation is working: `cd docs && npm run generate`

**All pages return 404:**

- Ensure GitHub Pages source is set to "GitHub Actions"
- Check that `dist/` directory contains files after build

### Content Not Updating

**Wiki changes not appearing:**

1. Check that wiki files are in `/wiki/` directory (not separate repo)
2. Verify changes are committed to `main` branch
3. Check workflow was triggered (Actions tab)

**Images not showing:**

- Ensure images are in `/wiki/` or `docs/public/` directories
- Use correct base URL path: `/raspberry-builds/image.png`

## Maintenance

### Updating Dependencies

```bash
cd docs
npm update
npm audit fix
```

### Rebuilding Site

The site automatically rebuilds on changes. For manual rebuild:

```bash
cd docs
npm run aggregate-content
npm run generate
```

### Monitoring

- **Actions Tab**: View deployment status and logs
- **Pages Settings**: View deployment history and current URL
- **Deployments**: Check deployment status in repository sidebar

## Advanced Configuration

### Custom Domain

To use a custom domain:

1. Go to repository Settings → Pages
2. Enter custom domain under "Custom domain"
3. Add DNS records (CNAME or A records) as shown
4. Wait for DNS propagation
5. Enable "Enforce HTTPS"

### Deployment Branch

To deploy from a different branch:

1. Edit `.github/workflows/deploy-docs.yml`
2. Change `branches: [main]` to your branch name
3. Commit and push changes

### Build Optimization

To reduce build time:

1. Enable dependency caching (already configured)
2. Use `skip-ci` in commit messages to skip builds:
   ```bash
   git commit -m "docs: minor typo fix [skip ci]"
   ```

## Support

For issues related to:
- **Nuxt/deployment**: Check `docs/README.md`
- **Content aggregation**: Check `docs/scripts/aggregate-content.mjs`
- **GitHub Actions**: Check `.github/workflows/deploy-docs.yml`