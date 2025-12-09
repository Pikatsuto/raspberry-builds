#!/usr/bin/env node

import { promises as fs } from 'fs'
import { resolve, dirname, basename } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const REPO_ROOT = resolve(__dirname, '../..')
const DOCS_ROOT = resolve(__dirname, '..')
const CONTENT_DIR = resolve(DOCS_ROOT, 'src/content/docs')
const WIKI_DIR = resolve(REPO_ROOT, 'wiki')

console.log('🚀 Starting content aggregation for Starlight...\n')

// Ensure content directories exist
await fs.mkdir(resolve(CONTENT_DIR, 'docs'), { recursive: true })
await fs.mkdir(resolve(CONTENT_DIR, 'images'), { recursive: true })
await fs.mkdir(resolve(CONTENT_DIR, 'image-sources'), { recursive: true })

// Clean existing content (except index.mdx)
console.log('🧹 Cleaning existing content...')
for (const dir of ['docs', 'images', 'image-sources']) {
  const fullPath = resolve(CONTENT_DIR, dir)
  try {
    const files = await fs.readdir(fullPath)
    for (const file of files) {
      await fs.rm(resolve(fullPath, file), { recursive: true, force: true })
    }
  } catch (err) {
    // Directory might be empty or not exist
  }
}

/**
 * Fix markdown links for Starlight compatibility
 */
function fixMarkdownLinks(content) {
  let fixed = content

  // Fix relative GitHub repository links
  fixed = fixed.replace(/\[([^\]]+)\]\(\.\.\/\.\.\/(?:\.\.\/)?([^)]+)\)/g, (match, text, path) => {
    // Handle wiki directory link
    if (path === 'wiki') {
      return `[${text}](/raspberry-builds/docs/home/)`
    }
    // Handle wiki links
    if (path.startsWith('wiki/')) {
      const wikiPath = path.replace('wiki/', '')
      const [pageName, anchor] = wikiPath.split('#')
      const pageNameLower = pageName.toLowerCase()
      const cat = pageName.startsWith('Image-') ? 'images' : 'docs'
      const anchorPart = anchor ? `#${anchor}` : '/'
      return `[${text}](/raspberry-builds/${cat}/${pageNameLower}${anchorPart})`
    }
    // Handle GitHub-specific paths
    if (path === 'actions' || path === 'issues' || path === 'discussions') {
      return `[${text}](https://github.com/Pikatsuto/raspberry-builds/${path})`
    }
    // Handle releases
    if (path === 'releases') {
      return `[${text}](/raspberry-builds/releases/)`
    }
    return match
  })

  // Fix relative parent directory links
  fixed = fixed.replace(/\[([^\]]+)\]\(\.\.\/([^)]+\.md)\)/g, (_match, text, file) => {
    return `[${text}](https://github.com/Pikatsuto/raspberry-builds/blob/main/${file})`
  })

  // Fix LICENSE link
  fixed = fixed.replace(/\]\(LICENSE\)/g, '](https://github.com/Pikatsuto/raspberry-builds/blob/main/LICENSE)')

  // Convert GitHub wiki links: [[Page Name]] -> [Page Name](/raspberry-builds/docs/page-name/)
  fixed = fixed.replace(/\[\[([^\]]+)\]\]/g, (_, pageName) => {
    const slug = pageName.replace(/\s+/g, '-').toLowerCase()
    const cat = pageName.startsWith('Image-') ? 'images' : 'docs'
    return `[${pageName}](/raspberry-builds/${cat}/${slug})`
  })

  // Fix relative wiki links: [text](Page-Name) -> [text](/raspberry-builds/docs/page-name/)
  fixed = fixed.replace(/\[([^\]]+)\]\((?!http|\/|#)([^)]+)\)/g, (_, text, link) => {
    if (link.includes('://') || link.startsWith('/') || link.startsWith('#')) {
      return `[${text}](${link})`
    }
    if (link === 'LICENSE' || link === 'CLAUDE.md') {
      return `[${text}](https://github.com/Pikatsuto/raspberry-builds/blob/main/${link})`
    }
    const cleanLink = link.replace(/\.md$/, '').toLowerCase()
    const cat = link.startsWith('Image-') ? 'images' : 'docs'
    return `[${text}](/raspberry-builds/${cat}/${cleanLink})`
  })

  return fixed
}

/**
 * Process markdown content to add frontmatter for Starlight
 */
function addFrontmatter(content, title, description = '') {
  const withoutFrontmatter = content.replace(/^---\n[\s\S]*?\n---\n/, '')
  const fixedContent = fixMarkdownLinks(withoutFrontmatter)

  // Properly quote YAML values to handle special characters
  const frontmatter = `---
title: "${title.replace(/"/g, '\\"')}"
description: "${description.replace(/"/g, '\\"')}"
---

`
  return frontmatter + fixedContent
}

/**
 * Process wiki files from /wiki directory
 */
async function processWiki() {
  console.log('📚 Processing wiki files...')

  try {
    const files = await fs.readdir(WIKI_DIR)
    const mdFiles = files.filter(f => f.endsWith('.md') && f !== '_Sidebar.md')

    let processed = 0
    for (const file of mdFiles) {
      const content = await fs.readFile(resolve(WIKI_DIR, file), 'utf-8')
      const name = basename(file, '.md')

      // Convert filename to title
      const title = name.replace(/-/g, ' ')

      // Determine category
      const isImageDoc = name.startsWith('Image-')
      const outputDir = isImageDoc
        ? resolve(CONTENT_DIR, 'images')
        : resolve(CONTENT_DIR, 'docs')

      // Process content
      const processedContent = addFrontmatter(
        content,
        title,
        `Wiki: ${title}`
      )

      // Write to content directory with lowercase filename
      const outputFile = file.toLowerCase()
      const outputPath = resolve(outputDir, outputFile)
      await fs.writeFile(outputPath, processedContent)
      processed++
    }

    console.log(`  ✅ Processed ${processed} wiki pages`)
  } catch (err) {
    console.log(`  ⚠️  Wiki directory not available: ${err.message}`)
  }
}

/**
 * Process main README files
 */
async function processReadmes() {
  console.log('📄 Processing README files...')

  const readmeFiles = [
    { path: 'README.md', title: 'Project Overview', slug: 'readme.md' },
    { path: '.github/README.md', title: 'GitHub Actions Documentation', slug: 'github-actions-ci.md' },
  ]

  let processed = 0
  for (const { path, title, slug } of readmeFiles) {
    const fullPath = resolve(REPO_ROOT, path)
    try {
      const content = await fs.readFile(fullPath, 'utf-8')
      const processedContent = addFrontmatter(
        content,
        title,
        `Documentation from ${path}`
      )

      const outputPath = resolve(CONTENT_DIR, slug)
      await fs.writeFile(outputPath, processedContent)
      processed++
    } catch (err) {
      console.log(`  ⚠️  Skipped ${path}: ${err.message}`)
    }
  }

  console.log(`  ✅ Processed ${processed} README files`)
}

/**
 * Process image configurations from /images directory
 */
async function processImageConfigs() {
  console.log('🖼️  Processing image configurations...')

  const imagesDir = resolve(REPO_ROOT, 'images')

  try {
    const images = await fs.readdir(imagesDir)
    let processed = 0

    for (const imageName of images) {
      const imagePath = resolve(imagesDir, imageName)
      let stat
      try {
        stat = await fs.stat(imagePath)
      } catch {
        continue
      }

      if (!stat.isDirectory()) continue

      const configPath = resolve(imagePath, 'config.sh')
      const readmePath = resolve(imagePath, 'README.md')

      let content = `# ${imageName}\n\n`

      try {
        // Try to read README if exists
        try {
          await fs.access(readmePath)
          const readme = await fs.readFile(readmePath, 'utf-8')
          content += readme + '\n\n'
        } catch {
          // No README
        }

        // Parse config.sh
        const config = await fs.readFile(configPath, 'utf-8')
        content += '## Configuration\n\n```bash\n' + config + '\n```\n\n'

        // Check for setup.sh
        const setupPath = resolve(imagePath, 'setup.sh')
        try {
          await fs.access(setupPath)
          const setup = await fs.readFile(setupPath, 'utf-8')
          content += '## Setup Script\n\n```bash\n' + setup + '\n```\n\n'
        } catch {
          // No setup.sh
        }

        // Add boot mode info
        let hasCloudInit = false
        let hasFirstBoot = false

        try {
          await fs.access(resolve(imagePath, 'cloudinit'))
          hasCloudInit = true
        } catch {}

        try {
          await fs.access(resolve(imagePath, 'first-boot'))
          hasFirstBoot = true
        } catch {}

        if (hasCloudInit) {
          content += '## Boot Mode\n\nThis image uses **cloud-init** for initial configuration.\n\n'
        } else if (hasFirstBoot) {
          content += '## Boot Mode\n\nThis image uses **first-boot service** for initial configuration.\n\n'
        }

        // Extract description from config
        const descMatch = config.match(/DESCRIPTION="([^"]+)"/)
        const description = descMatch ? descMatch[1] : `${imageName} image configuration`

        const processedContent = addFrontmatter(
          content,
          imageName,
          description
        )

        const outputPath = resolve(CONTENT_DIR, 'image-sources', `${imageName}.md`)
        await fs.writeFile(outputPath, processedContent)
        processed++
      } catch (err) {
        console.log(`  ⚠️  Skipped ${imageName}: ${err.message}`)
      }
    }

    console.log(`  ✅ Processed ${processed} image configurations`)
  } catch (err) {
    console.log(`  ⚠️  Images directory not found: ${err.message}`)
  }
}

// Run all processing steps
try {
  await processWiki()
  await processReadmes()
  await processImageConfigs()

  console.log('\n✨ Content aggregation completed successfully!')
} catch (err) {
  console.error('\n❌ Error during content aggregation:', err)
  process.exit(1)
}