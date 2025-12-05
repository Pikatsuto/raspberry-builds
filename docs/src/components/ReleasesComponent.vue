<template>
  <div class="releases-container">
    <div v-if="loading" class="loading">
      <p>Loading releases...</p>
    </div>

    <div v-else-if="error" class="error">
      <p>{{ error }}</p>
      <a :href="githubReleasesUrl" target="_blank" rel="noopener noreferrer">
        View releases on GitHub
      </a>
    </div>

    <div v-else class="releases-list">
      <div v-for="release in displayedReleases" :key="release.id" class="release-card">
        <div class="release-header">
          <div class="release-info">
            <div class="release-title-row">
              <h3>{{ release.tag_name }}</h3>
              <span v-if="release.prerelease" class="badge badge-prerelease">Pre-release</span>
              <span v-else class="badge badge-stable">Stable</span>
            </div>
            <p class="release-name">{{ release.name }}</p>
            <p v-if="release.published_at" class="release-date">
              Released: {{ formatDate(release.published_at) }}
            </p>
          </div>
          <a
            :href="release.html_url"
            target="_blank"
            rel="noopener noreferrer"
            class="btn-primary"
          >
            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            View Release
          </a>
        </div>

        <div v-if="release.assets && release.assets.length > 0" class="release-assets">
          <h4>Download Assets:</h4>
          <div class="assets-list">
            <a
              v-for="asset in release.assets"
              :key="asset.id"
              :href="asset.browser_download_url"
              class="asset-link"
            >
              <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              {{ asset.name }} ({{ formatSize(asset.size) }})
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'

interface Props {
  prerelease?: boolean
  limit?: number
}

const props = withDefaults(defineProps<Props>(), {
  prerelease: false,
  limit: 5
})

const releases = ref<any[]>([])
const loading = ref(true)
const error = ref<string | null>(null)

const githubReleasesUrl = 'https://github.com/Pikatsuto/raspberry-builds/releases'

const displayedReleases = computed(() => {
  const filtered = releases.value.filter((r: any) =>
    props.prerelease ? r.prerelease : !r.prerelease
  )
  return filtered.slice(0, props.limit)
})

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatSize = (bytes: number) => {
  const mb = bytes / 1024 / 1024
  return mb.toFixed(2) + ' MB'
}

onMounted(async () => {
  try {
    const response = await fetch('https://api.github.com/repos/Pikatsuto/raspberry-builds/releases')
    if (!response.ok) {
      throw new Error('Failed to fetch releases')
    }
    releases.value = await response.json()
  } catch (err) {
    error.value = 'Failed to load releases. Please try again later.'
    console.error('Error fetching releases:', err)
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
.releases-container {
  margin: 2rem 0;
}

.loading, .error {
  padding: 2rem;
  text-align: center;
  border-radius: 0.5rem;
  background: var(--sl-color-gray-6);
}

.error a {
  color: var(--sl-color-accent);
  text-decoration: underline;
}

.releases-list {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.release-card {
  border: 1px solid var(--sl-color-gray-5);
  border-radius: 0.5rem;
  padding: 1.5rem;
  background: var(--sl-color-bg);
}

.release-header {
  display: flex;
  justify-content: space-between;
  align-items: start;
  margin-bottom: 1rem;
  gap: 1rem;
}

.release-info {
  flex: 1;
}

.release-title-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
  flex-wrap: wrap;
}

.release-title-row h3 {
  margin: 0;
  font-size: 1.5rem;
}

.badge {
  padding: 0.25rem 0.75rem;
  border-radius: 0.25rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
}

.badge-stable {
  background: var(--sl-color-green-high);
  color: var(--sl-color-green-low);
}

.badge-prerelease {
  background: var(--sl-color-orange-high);
  color: var(--sl-color-orange-low);
}

.release-name {
  margin: 0.25rem 0;
  color: var(--sl-color-gray-2);
}

.release-date {
  margin: 0.5rem 0 0;
  font-size: 0.875rem;
  color: var(--sl-color-gray-3);
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  background: var(--sl-color-accent);
  color: white;
  border-radius: 0.375rem;
  text-decoration: none;
  font-weight: 500;
  white-space: nowrap;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: var(--sl-color-accent-high);
}

.release-assets {
  border-top: 1px solid var(--sl-color-gray-5);
  padding-top: 1rem;
}

.release-assets h4 {
  margin: 0 0 0.75rem;
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--sl-color-gray-2);
}

.assets-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.asset-link {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--sl-color-accent);
  text-decoration: none;
  font-size: 0.875rem;
}

.asset-link:hover {
  text-decoration: underline;
}

@media (max-width: 768px) {
  .release-header {
    flex-direction: column;
  }

  .btn-primary {
    width: 100%;
    justify-content: center;
  }
}
</style>