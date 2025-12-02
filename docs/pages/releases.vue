<template>
  <div>
    <UCard>
      <template #header>
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold">Pre-built Images</h1>
            <p class="text-gray-600 dark:text-gray-400 mt-2">
              Download ready-to-use Raspberry Pi hybrid images
            </p>
          </div>
          <UButton
            to="https://github.com/Pikatsuto/raspberry-builds/releases"
            target="_blank"
            icon="i-heroicons-arrow-top-right-on-square"
            color="gray"
          >
            View on GitHub
          </UButton>
        </div>
      </template>

      <!-- Loading State -->
      <div v-if="pending" class="flex items-center justify-center py-12">
        <div class="text-center">
          <UIcon name="i-heroicons-arrow-path" class="w-8 h-8 animate-spin text-primary mx-auto mb-4" />
          <p class="text-gray-600 dark:text-gray-400">Loading releases...</p>
        </div>
      </div>

      <!-- Error State -->
      <UAlert
        v-else-if="error"
        color="red"
        variant="soft"
        icon="i-heroicons-exclamation-triangle"
        title="Error loading releases"
        :description="error.message"
        class="mb-6"
      />

      <!-- Releases Content -->
      <div v-else class="space-y-8">
        <!-- Stable Releases -->
        <div v-if="stableReleases.length > 0">
          <div class="flex items-center space-x-2 mb-4">
            <UIcon name="i-heroicons-check-badge" class="w-6 h-6 text-green-600 dark:text-green-400" />
            <h2 class="text-2xl font-bold">Stable Releases</h2>
          </div>

          <div class="space-y-4">
            <UCard
              v-for="release in stableReleases"
              :key="release.id"
              class="hover:shadow-lg transition-shadow"
            >
              <template #header>
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center space-x-3">
                      <h3 class="text-xl font-semibold">{{ release.tag_name }}</h3>
                      <UBadge color="green" variant="soft">Stable</UBadge>
                    </div>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Released {{ formatDate(release.published_at) }}
                    </p>
                  </div>
                </div>
              </template>

              <div v-if="release.body" class="prose dark:prose-invert max-w-none mb-4">
                <div class="text-sm" v-html="parseMarkdown(release.body)"></div>
              </div>

              <!-- Assets -->
              <div v-if="getImageAssets(release).length > 0" class="space-y-2">
                <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                  Available Images ({{ getImageAssets(release).length }})
                </h4>
                <div class="grid grid-cols-1 gap-2">
                  <div
                    v-for="asset in getImageAssets(release)"
                    :key="asset.id"
                    class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                  >
                    <div class="flex items-center space-x-3 flex-1 min-w-0">
                      <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5 text-primary flex-shrink-0" />
                      <div class="min-w-0 flex-1">
                        <p class="font-medium text-sm truncate">{{ asset.name }}</p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          {{ formatSize(asset.size) }} • {{ asset.download_count }} downloads
                        </p>
                      </div>
                    </div>
                    <UButton
                      :to="asset.browser_download_url"
                      target="_blank"
                      size="sm"
                      icon="i-heroicons-arrow-down-tray"
                      color="primary"
                    >
                      Download
                    </UButton>
                  </div>
                </div>
              </div>
            </UCard>
          </div>
        </div>

        <!-- Pre-releases -->
        <div v-if="preReleases.length > 0">
          <div class="flex items-center space-x-2 mb-4">
            <UIcon name="i-heroicons-beaker" class="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            <h2 class="text-2xl font-bold">Pre-releases</h2>
          </div>

          <UAlert
            color="yellow"
            variant="soft"
            icon="i-heroicons-exclamation-triangle"
            class="mb-4"
          >
            <template #title>Experimental Builds</template>
            <template #description>
              Pre-release versions are automatically built from development branches.
              They may contain bugs or incomplete features.
            </template>
          </UAlert>

          <div class="space-y-4">
            <UCard
              v-for="release in preReleases"
              :key="release.id"
              class="hover:shadow-lg transition-shadow"
            >
              <template #header>
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center space-x-3">
                      <h3 class="text-xl font-semibold">{{ release.tag_name }}</h3>
                      <UBadge color="yellow" variant="soft">Pre-release</UBadge>
                    </div>
                    <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Released {{ formatDate(release.published_at) }}
                    </p>
                  </div>
                </div>
              </template>

              <div v-if="release.body" class="prose dark:prose-invert max-w-none mb-4">
                <div class="text-sm" v-html="parseMarkdown(release.body)"></div>
              </div>

              <!-- Assets -->
              <div v-if="getImageAssets(release).length > 0" class="space-y-2">
                <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                  Available Images ({{ getImageAssets(release).length }})
                </h4>
                <div class="grid grid-cols-1 gap-2">
                  <div
                    v-for="asset in getImageAssets(release)"
                    :key="asset.id"
                    class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                  >
                    <div class="flex items-center space-x-3 flex-1 min-w-0">
                      <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5 text-primary flex-shrink-0" />
                      <div class="min-w-0 flex-1">
                        <p class="font-medium text-sm truncate">{{ asset.name }}</p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          {{ formatSize(asset.size) }} • {{ asset.download_count }} downloads
                        </p>
                      </div>
                    </div>
                    <UButton
                      :to="asset.browser_download_url"
                      target="_blank"
                      size="sm"
                      icon="i-heroicons-arrow-down-tray"
                      color="yellow"
                    >
                      Download
                    </UButton>
                  </div>
                </div>
              </div>
            </UCard>
          </div>
        </div>

        <!-- No Releases -->
        <div v-if="stableReleases.length === 0 && preReleases.length === 0" class="text-center py-12">
          <UIcon name="i-heroicons-inbox" class="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 class="text-xl font-semibold text-gray-700 dark:text-gray-300 mb-2">
            No releases yet
          </h3>
          <p class="text-gray-600 dark:text-gray-400">
            Check back later for pre-built images
          </p>
        </div>
      </div>
    </UCard>
  </div>
</template>

<script setup lang="ts">
interface GitHubAsset {
  id: number
  name: string
  size: number
  download_count: number
  browser_download_url: string
}

interface GitHubRelease {
  id: number
  tag_name: string
  name: string
  body: string
  published_at: string
  prerelease: boolean
  assets: GitHubAsset[]
}

// Fetch releases from GitHub API
const { data: releases, pending, error } = await useFetch<GitHubRelease[]>(
  'https://api.github.com/repos/Pikatsuto/raspberry-builds/releases',
  {
    headers: {
      'Accept': 'application/vnd.github.v3+json'
    }
  }
)

// Separate stable and pre-releases
const stableReleases = computed(() => {
  return (releases.value || []).filter(r => !r.prerelease)
})

const preReleases = computed(() => {
  return (releases.value || []).filter(r => r.prerelease)
})

// Get only image assets (.img.xz files)
function getImageAssets(release: GitHubRelease) {
  return release.assets.filter(asset =>
    asset.name.endsWith('.img.xz') || asset.name.endsWith('.img')
  )
}

// Format file size
function formatSize(bytes: number): string {
  const units = ['B', 'KB', 'MB', 'GB']
  let size = bytes
  let unitIndex = 0

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024
    unitIndex++
  }

  return `${size.toFixed(2)} ${units[unitIndex]}`
}

// Format date
function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffTime = Math.abs(now.getTime() - date.getTime())
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))

  if (diffDays === 0) return 'today'
  if (diffDays === 1) return 'yesterday'
  if (diffDays < 7) return `${diffDays} days ago`
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`
  if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`

  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

// Simple markdown to HTML conversion (basic support)
function parseMarkdown(text: string): string {
  if (!text) return ''

  return text
    // Headers
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    // Bold
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    // Italic
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    // Links
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" class="text-primary hover:underline">$1</a>')
    // Line breaks
    .replace(/\n/g, '<br>')
}

// Set page title
useHead({
  title: 'Pre-built Images - Raspberry Pi Builds'
})
</script>