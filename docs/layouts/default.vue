<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <UContainer>
      <header class="py-8 border-b border-gray-200 dark:border-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <NuxtLink to="/" class="flex items-center space-x-3">
              <UIcon name="i-heroicons-cpu-chip" class="w-8 h-8 text-primary" />
              <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                  Raspberry Pi Builds
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400">
                  Hybrid Debian ARM64 Images for Raspberry Pi
                </p>
              </div>
            </NuxtLink>
          </div>
          <div class="flex items-center space-x-4">
            <UButton
              to="https://github.com/Pikatsuto/raspberry-builds"
              target="_blank"
              icon="i-heroicons-code-bracket"
              color="gray"
              variant="ghost"
            >
              GitHub
            </UButton>
            <UColorModeButton />
          </div>
        </div>
      </header>

      <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 py-8">
        <!-- Sidebar Navigation -->
        <aside class="lg:col-span-3">
          <nav class="sticky top-8 space-y-1">
            <UButton
              to="/"
              block
              color="gray"
              variant="ghost"
              class="justify-start"
            >
              Home
            </UButton>
            <UButton
              to="/releases"
              block
              color="gray"
              variant="ghost"
              class="justify-start"
              icon="i-heroicons-arrow-down-tray"
            >
              Releases
            </UButton>
            <UDivider class="my-4" />
            <div class="space-y-1">
              <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 px-3 mb-2">
                DOCUMENTATION
              </p>
              <UButton
                v-for="page in navigation?.docs || []"
                :key="page._path"
                :to="page._path"
                block
                color="gray"
                variant="ghost"
                class="justify-start"
              >
                {{ page.title }}
              </UButton>
            </div>
            <UDivider class="my-4" />
            <div class="space-y-1">
              <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 px-3 mb-2">
                IMAGES
              </p>
              <UButton
                v-for="page in navigation?.images || []"
                :key="page._path"
                :to="page._path"
                block
                color="gray"
                variant="ghost"
                class="justify-start"
              >
                {{ page.title }}
              </UButton>
            </div>
          </nav>
        </aside>

        <!-- Main Content -->
        <main class="lg:col-span-9">
          <slot />
        </main>
      </div>

      <footer class="py-8 border-t border-gray-200 dark:border-gray-800 mt-12">
        <div class="text-center text-sm text-gray-600 dark:text-gray-400">
          <p>
            Built with
            <ULink to="https://nuxt.com" target="_blank" class="text-primary">Nuxt</ULink>
            and
            <ULink to="https://ui.nuxt.com" target="_blank" class="text-primary">Nuxt UI</ULink>
          </p>
          <p class="mt-2">
            &copy; {{ new Date().getFullYear() }} Raspberry Pi Builds Project
          </p>
        </div>
      </footer>
    </UContainer>
  </div>
</template>

<script setup lang="ts">
const { data: navigation } = await useAsyncData('navigation', () =>
  queryContent()
    .only(['_path', 'title', 'category'])
    .find()
    .then(pages => ({
      docs: pages
        .filter(p => p.category === 'docs' && p.title)
        .sort((a, b) => (a.title || '').localeCompare(b.title || '')),
      images: pages
        .filter(p => p.category === 'images' && p.title)
        .sort((a, b) => (a.title || '').localeCompare(b.title || ''))
    }))
)
</script>