# Raspberry Pi Builds Documentation

This directory contains the Nuxt-based documentation site for the Raspberry Pi Builds project. The site aggregates content from the GitHub wiki and README files to create a unified documentation experience.

## Architecture

- **Framework**: Nuxt 3 with Nuxt Content for markdown rendering
- **UI**: Nuxt UI for components and styling
- **Content Sources**:
  - `/wiki/*.md` - GitHub wiki pages
  - `/README.md` - Project overview
  - `/.github/README.md` - GitHub Actions documentation
  - `/images/*/` - Image configuration details

## Development

### Prerequisites

- Node.js 20+
- npm or pnpm

### Local Development

```bash
# Install dependencies
cd docs
npm install

# Aggregate content from wiki and READMEs
npm run aggregate-content

# Start development server
npm run dev
```

Visit http://localhost:3000 to view the documentation site.

### Building for Production

```bash
# Generate static site
npm run generate
```

The static site will be generated in `.output/public/` directory.

### Testing Production Build Locally

The production build uses `baseURL: '/raspberry-builds/'` which means all links point to `/raspberry-builds/...`. To test this locally with the correct path structure:

```bash
# After generating the site, run:
npm run test:production
```

This will:
1. Create a test structure: `dist-test/raspberry-builds/`
2. Copy the built site into it
3. Start a server at http://localhost:3000
4. **Visit http://localhost:3000/raspberry-builds/** (note the path!)

**Important:** The baseURL is conditional:
- **Development** (`npm run dev`): Uses `/` - visit http://localhost:3000/
- **Production** (`npm run generate`): Uses `/raspberry-builds/` - visit http://localhost:3000/raspberry-builds/

## Content Aggregation

The `scripts/aggregate-content.mjs` script automatically:

1. Reads markdown files from `/wiki/` directory
2. Processes main repository READMEs (excluding CLAUDE.md)
3. Generates documentation from image configurations in `/images/`
4. Adds frontmatter metadata to all content
5. Organizes content into categories (docs, images)

Content is categorized as:
- **docs**: Wiki pages, README files, general documentation
- **images**: Wiki pages starting with "Image-" and image configurations

## Deployment

The site is automatically deployed to GitHub Pages via GitHub Actions:

- **Workflow**: `.github/workflows/deploy-docs.yml`
- **Trigger**: Push to `main` branch (when docs, wiki, or images change)
- **URL**: https://pikatsuto.github.io/raspberry-builds/

### Manual Deployment

You can manually trigger deployment from the GitHub Actions tab.

## File Structure

```
docs/
├── app.vue                 # Root app component
├── assets/
│   └── css/
│       └── main.css       # Tailwind CSS
├── layouts/
│   └── default.vue        # Main layout with navigation
├── pages/
│   ├── index.vue          # Home page
│   └── [...slug].vue      # Dynamic content pages
├── public/
│   └── .nojekyll          # GitHub Pages config
├── scripts/
│   └── aggregate-content.mjs  # Content aggregation script
├── nuxt.config.ts         # Nuxt configuration
└── package.json           # Dependencies
```

## Adding Content

### Wiki Pages

Add or edit markdown files in `/wiki/`. They will be automatically included in the next build.

### Image Documentation

Add a `README.md` file in `/images/<image-name>/` to provide custom documentation for that image. The aggregation script will combine it with the configuration details.

### README Files

Main README files are automatically included. To add more:

1. Edit `scripts/aggregate-content.mjs`
2. Add the file to the `readmeFiles` array in `processReadmes()`

## Customization

### Styling

- Modify `assets/css/main.css` for global styles
- Use Nuxt UI components for consistent theming
- Tailwind classes available throughout

### Navigation

The sidebar navigation is automatically generated from content frontmatter categories. To customize:

1. Edit `layouts/default.vue`
2. Modify the navigation query in the `<script setup>` section

### Home Page

Edit `pages/index.vue` to customize the landing page content and layout.

## Troubleshooting

### Content not updating

1. Run `npm run aggregate-content` manually
2. Clear Nuxt cache: `rm -rf .nuxt .output`
3. Restart dev server

### Build errors

1. Check Node.js version (should be 20+)
2. Delete `node_modules` and `package-lock.json`
3. Run `npm install` again

### GitHub Pages not updating

1. Check GitHub Actions workflow status
2. Ensure GitHub Pages is enabled in repository settings
3. Verify the source is set to "GitHub Actions"