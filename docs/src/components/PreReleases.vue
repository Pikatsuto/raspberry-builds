<template>
  <div>
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <div class="text-center">
        <svg class="w-8 h-8 animate-spin text-blue-600 mx-auto mb-4" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="text-gray-600 dark:text-gray-400">Loading releases...</p>
      </div>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-6">
      <div class="flex items-start">
        <svg class="w-6 h-6 text-red-600 dark:text-red-400 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
          <h3 class="text-red-900 dark:text-red-200 font-semibold">Error loading releases</h3>
          <p class="text-red-800 dark:text-red-300 text-sm">{{ error }}</p>
        </div>
      </div>
    </div>

    <!-- Releases Content -->
    <div v-else class="space-y-8">
      <!-- Pre-releases -->
      <div v-if="preReleases.length > 0">
        <div class="flex items-center space-x-2 mb-4">
          <svg class="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z" />
          </svg>
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Pre-releases</h2>
        </div>

        <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 mb-4">
          <div class="flex items-start">
            <svg class="w-6 h-6 text-yellow-600 dark:text-yellow-400 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
            <div>
              <h3 class="text-yellow-900 dark:text-yellow-200 font-semibold">Experimental Builds</h3>
              <p class="text-yellow-800 dark:text-yellow-300 text-sm">
                Pre-release versions are automatically built from development branches.
                They may contain bugs or incomplete features.
              </p>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div
            v-for="release in preReleases"
            :key="release.id"
            class="bg-white dark:bg-gray-700 rounded-lg shadow-sm hover:shadow-md transition-shadow border border-gray-200 dark:border-gray-600"
          >
            <div class="p-6">
              <div class="flex items-start justify-between mb-4">
                <div>
                  <div class="flex items-center space-x-3">
                    <h3 class="text-xl font-semibold text-gray-900 dark:text-white">{{ release.tag_name }}</h3>
                    <span class="px-2 py-1 text-xs font-medium bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 rounded">Pre-release</span>
                  </div>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    Released {{ formatDate(release.published_at) }}
                  </p>
                </div>
              </div>

              <div v-if="release.body" class="prose dark:prose-invert max-w-none mb-4 text-sm" v-html="parseMarkdown(release.body)"></div>

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
                      <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                      </svg>
                      <div class="min-w-0 flex-1">
                        <p class="font-medium text-sm truncate text-gray-900 dark:text-white">{{ asset.name }}</p>
                        <p class="text-xs text-gray-500 dark:text-gray-400">
                          {{ formatSize(asset.size) }} • {{ asset.download_count }} downloads
                        </p>
                      </div>
                    </div>
                    <a
                      :href="asset.browser_download_url"
                      target="_blank"
                      class="ml-4 inline-flex items-center px-3 py-1.5 text-white text-sm font-medium rounded transition-colors bg-yellow-600 hover:!bg-yellow-700"
                    >
                      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                      </svg>
                      Download
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- No Releases -->
      <div v-if="preReleases.length === 0" class="text-center py-12">
        <svg class="w-16 h-16 text-gray-400 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
        <h3 class="text-xl font-semibold text-gray-700 dark:text-gray-300 mb-2">
          No releases yet
        </h3>
        <p class="text-gray-600 dark:text-gray-400">
          Check back later for pre-built images
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const releases = ref([]);
const loading = ref(true);
const error = ref(null);

const stableReleases = computed(() => {
  return releases.value.filter(r => !r.prerelease);
});

const preReleases = computed(() => {
  return releases.value.filter(r => r.prerelease);
});

function getImageAssets(release) {
  return release.assets.filter(asset =>
    asset.name.endsWith('.img.xz') || asset.name.endsWith('.img')
  );
}

function formatSize(bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  let size = bytes;
  let unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }

  return `${size.toFixed(2)} ${units[unitIndex]}`;
}

function formatDate(dateString) {
  const date = new Date(dateString);
  const now = new Date();
  const diffTime = Math.abs(now.getTime() - date.getTime());
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return 'today';
  if (diffDays === 1) return 'yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`;

  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

function parseMarkdown(text) {
  if (!text) return '';

  return text
    .replace(/^### (.*$)/gim, '<h3>$1</h3>')
    .replace(/^## (.*$)/gim, '<h2>$1</h2>')
    .replace(/^# (.*$)/gim, '<h1>$1</h1>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline">$1</a>')
    .replace(/\n/g, '<br>');
}

onMounted(async () => {
  try {
    const response = await fetch('https://api.github.com/repos/Pikatsuto/raspberry-builds/releases');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    releases.value = await response.json();
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
});
</script>