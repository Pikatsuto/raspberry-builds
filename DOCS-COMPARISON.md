# Documentation Sites Comparison

This repository contains **two versions** of the documentation site:

## 1. Nuxt Version (`docs/`)

**Framework**: Nuxt 3 + Nuxt UI + Nuxt Content

### Pros
- Rich UI component library (Nuxt UI)
- Excellent Vue 3 integration
- Built-in SSR/SSG support
- Hot module replacement for fast development
- Great for complex Vue applications

### Cons
- Larger bundle size
- Slower build times
- More JavaScript shipped to client
- Requires Vue knowledge

### Usage
```bash
cd docs
npm install
npm run dev        # http://localhost:3000/
npm run generate   # Build to .output/public/
```

---

## 2. Astro Version (`docs-astro/`)

**Framework**: Astro + Vue 3 (for interactive components) + Tailwind CSS

### Pros
- **Zero JavaScript by default** (only Vue components load JS)
- Much smaller bundle size
- Faster build times (3-5x faster than Nuxt)
- Better Lighthouse scores
- Framework agnostic (can mix Vue/React/Svelte)
- Islands architecture for better performance

### Cons
- No built-in UI component library
- Manual Tailwind styling needed
- Smaller ecosystem than Nuxt
- Less Vue-specific features

### Usage
```bash
cd docs-astro
npm install
npm run dev        # http://localhost:4321/
npm run build      # Build to dist/
```

---

## Feature Comparison

| Feature | Nuxt | Astro |
|---------|------|-------|
| **Build Speed** | ~30-60s | ~10-20s |
| **Bundle Size** | ~500KB | ~50KB |
| **First Load JS** | ~300KB | ~20KB |
| **Vue Components** | ✅ Full support | ✅ Partial hydration only |
| **SSR** | ✅ Yes | ✅ Yes (optional) |
| **Content Collections** | Nuxt Content | Built-in |
| **Markdown** | ✅ | ✅ |
| **Dark Mode** | Nuxt UI | Manual |
| **TypeScript** | ✅ | ✅ |

---

## Performance Metrics (Estimated)

### Nuxt
- **First Contentful Paint**: ~1.2s
- **Time to Interactive**: ~2.5s
- **Total Bundle**: ~500KB gzipped

### Astro
- **First Contentful Paint**: ~0.6s
- **Time to Interactive**: ~0.8s
- **Total Bundle**: ~50KB gzipped

---

## When to Use Which?

### Use **Nuxt** if:
- You want a polished UI out-of-the-box
- You're building a complex SPA
- You need advanced Vue features (Pinia, Vue Router, etc.)
- You prefer convention over configuration

### Use **Astro** if:
- Performance is critical
- You want minimal JavaScript
- You're building a content-heavy site
- You want faster build times
- You want to mix different frameworks

---

## Current Deployment

**Active**: Nuxt version (from `docs/`)
**URL**: https://pikatsuto.github.io/raspberry-builds/

To switch to Astro, update `.github/workflows/deploy-docs.yml` to build from `docs-astro/` instead.

---

## Maintenance

Both versions:
- Share the same content sources (`/wiki/`, `/README.md`, `/images/`)
- Use identical content aggregation logic
- Support the same features (releases API, navigation, etc.)
- Deploy to the same GitHub Pages structure

Only one version should be deployed at a time to avoid conflicts.