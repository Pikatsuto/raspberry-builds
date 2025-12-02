#!/usr/bin/env node

import { promises as fs } from 'fs'
import { resolve, dirname, basename } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const REPO_ROOT = resolve(__dirname, '../..')
const DOCS_ROOT = resolve(__dirname, '..')
const CONTENT_DOCS_DIR = resolve(DOCS_ROOT, 'src/content/docs')
const CONTENT_IMAGE_DOCS_DIR = resolve(DOCS_ROOT, 'src/content/image-docs')
const CONTENT_IMAGE_SOURCES_DIR = resolve(DOCS_ROOT, 'src/content/image-sources')
const WIKI_DIR = resolve(REPO_ROOT, 'wiki')

console.log('🚀 Starting content aggregation for Astro...\n')

// Ensure content directories exist
await fs.mkdir(CONTENT_DOCS_DIR, { recursive: true })
await fs.mkdir(CONTENT_IMAGE_DOCS_DIR, { recursive: true })
await fs.mkdir(CONTENT_IMAGE_SOURCES_DIR, { recursive: true })

// Clean existing content
console.log('🧹 Cleaning existing content...')
for (const dir of [CONTENT_DOCS_DIR, CONTENT_IMAGE_DOCS_DIR, CONTENT_IMAGE_SOURCES_DIR]) {
  try {
    const files = await fs.readdir(dir)
    for (const file of files) {
      await fs.rm(resolve(dir, file), { recursive: true, force: true })
    }
  } catch (err) {
    // Directory might be empty
  }
}

/**
 * Fix markdown links for Astro compatibility
 */
function fixMarkdownLinks(content) {
  let fixed = content

  // Convert GitHub wiki links: [[Page Name]] -> [Page Name](/raspberry-builds/docs/Page-Name) or [Page Name](/raspberry-builds/images/Page-Name)
  fixed = fixed.replace(/\[\[([^\]]+)\]\]/g, (_, pageName) => {
    const slug = pageName.replace(/\s+/g, '-')
    const cat = slug.startsWith('Image-') ? 'images' : 'docs'
    return `[${pageName}](/raspberry-builds/${cat}/${slug})`
  })

  // Fix relative wiki links: [text](Page-Name) -> [text](/raspberry-builds/docs/Page-Name)
  fixed = fixed.replace(/\[([^\]]+)\]\((?!http|\/|#)([^)]+)\)/g, (_, text, link) => {
    if (link.includes('://') || link.startsWith('/') || link.startsWith('#')) {
      return `[${text}](${link})`
    }
    const cleanLink = link.replace(/\.md$/, '')
    const cat = cleanLink.startsWith('Image-') ? 'images' : 'docs'
    return `[${text}](/raspberry-builds/${cat}/${cleanLink})`
  })

  // Fix GitHub URLs that point to the wiki
  fixed = fixed.replace(/https:\/\/github\.com\/[^\/]+\/[^\/]+\/wiki\/([^\s)]+)/g, (_, page) => {
    const cat = page.startsWith('Image-') ? 'images' : 'docs'
    return `/raspberry-builds/${cat}/${page}`
  })

  return fixed
}

/**
 * Process markdown content to add frontmatter
 */
function addFrontmatter(content, title, description = '') {
  // Remove existing frontmatter if present
  const withoutFrontmatter = content.replace(/^---\n[\s\S]*?\n---\n/, '')

  // Fix markdown links
  const fixedContent = fixMarkdownLinks(withoutFrontmatter)

  const frontmatter = `---
title: "${title}"
description: "${description}"
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

      // Determine category: Wiki pages starting with "Image-" go to image-docs
      const isImageDoc = name.startsWith('Image-')
      const outputDir = isImageDoc ? CONTENT_IMAGE_DOCS_DIR : CONTENT_DOCS_DIR

      // Process content
      const processedContent = addFrontmatter(
        content,
        title,
        `Wiki: ${title}`
      )

      // Write to content directory
      const outputPath = resolve(outputDir, file)
      await fs.writeFile(outputPath, processedContent)
      processed++
    }

    console.log(`  ✅ Processed ${processed} wiki pages`)
  } catch (err) {
    console.log(`  ⚠️  Wiki directory not available: ${err.message}`)
  }
}

/**
 * Process main README files (excluding CLAUDE.md)
 */
async function processReadmes() {
  console.log('📄 Processing README files...')

  const readmeFiles = [
    { path: 'README.md', title: 'Project Overview' },
    { path: '.github/README.md', title: 'GitHub Actions Documentation' },
  ]

  let processed = 0
  for (const { path, title } of readmeFiles) {
    const fullPath = resolve(REPO_ROOT, path)
    try {
      const content = await fs.readFile(fullPath, 'utf-8')
      const processedContent = addFrontmatter(
        content,
        title,
        `Documentation from ${path}`
      )

      const outputName = basename(dirname(path)) === '.'
        ? basename(path)
        : `${basename(dirname(path))}-${basename(path)}`

      const outputPath = resolve(CONTENT_DOCS_DIR, outputName)
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

        const outputPath = resolve(CONTENT_IMAGE_SOURCES_DIR, `${imageName}.md`)
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