# Raspberry Pi Builds Documentation (Astro)

This is an **alternative version** of the documentation site built with **Astro** instead of Nuxt.

## Key Features

- **Astro** - Fast, modern static site generator
- **Vue 3** - For interactive components (Releases page)
- **Tailwind CSS** - Utility-first styling
- **MDX** - Enhanced markdown support
- **Content Aggregation** - Automatically pulls from `/wiki/` and README files

## Development

```bash
# Install dependencies
cd docs-astro
npm install

# Aggregate content
npm run aggregate-content

# Start dev server
npm run dev
# → http://localhost:4321/raspberry-builds/
```

## Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

The static site will be generated in `dist/` directory.

## Comparison with Nuxt Version

**Astro advantages:**
- Faster build times
- Smaller bundle size (zero JS by default)
- Better performance (static HTML)
- Component framework agnostic (can mix Vue, React, etc.)

**Nuxt advantages:**
- Better SSR support if needed
- More Vue ecosystem integration
- Built-in routing conventions

## Structure

```
docs-astro/
├── src/
│   ├── layouts/
│   │   └── Layout.astro         # Main layout
│   ├── pages/
│   │   ├── index.astro          # Home page
│   │   ├── releases.astro       # Releases page
│   │   └── content/[category]/[...slug].astro  # Dynamic content pages
│   ├── components/
│   │   └── Releases.vue         # Vue component for releases
│   └── content/
│       ├── docs/                # Generated docs (ignored by git)
│       └── images/              # Generated image docs (ignored by git)
├── scripts/
│   └── aggregate-content.mjs    # Content aggregation script
├── public/
│   └── .nojekyll                # GitHub Pages config
└── astro.config.mjs             # Astro configuration
```

## Deployment

This version can be deployed alongside the Nuxt version or replace it. Simply update the GitHub Actions workflow to build from `docs-astro/` instead of `docs/`.

## Content Sources

Same as Nuxt version:
- `/wiki/*.md` - GitHub wiki pages
- `/README.md` - Project overview
- `/.github/README.md` - GitHub Actions docs
- `/images/*/` - Image configurations