# Deployment Guide - Astro Version

## GitHub Actions Workflow (Optional)

To deploy the Astro version instead of Nuxt, replace `.github/workflows/deploy-docs.yml` with:

```yaml
name: Deploy Documentation to GitHub Pages (Astro)

on:
  push:
    branches:
      - main
    paths:
      - 'docs-astro/**'
      - 'wiki/**'
      - 'images/**'
      - 'README.md'
      - '.github/README.md'
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: docs-astro/package-lock.json

      - name: Install dependencies
        working-directory: docs-astro
        run: npm ci

      - name: Aggregate content from wiki and READMEs
        working-directory: docs-astro
        run: npm run aggregate-content

      - name: Build Astro site
        working-directory: docs-astro
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./docs-astro/dist

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build

    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

## Manual Deployment

1. Build the site:
   ```bash
   cd docs-astro
   npm install
   npm run build
   ```

2. The output will be in `docs-astro/dist/`

3. Deploy `dist/` to your hosting provider

## Configuration

The Astro site is configured for GitHub Pages at:
- **Site URL**: `https://pikatsuto.github.io`
- **Base path**: `/raspberry-builds`

These are set in `astro.config.mjs`:
```js
export default defineConfig({
  site: 'https://pikatsuto.github.io',
  base: '/raspberry-builds',
  // ...
});
```

## Testing Locally

Development mode (no base path):
```bash
npm run dev
# → http://localhost:4321/
```

Production preview (with base path):
```bash
npm run build
npm run preview
# → http://localhost:4321/raspberry-builds/
```

## Switching from Nuxt to Astro

1. Update `.github/workflows/deploy-docs.yml` with the workflow above
2. Commit and push
3. GitHub Actions will build and deploy the Astro version

Both versions can coexist, but only one should be deployed to avoid conflicts.