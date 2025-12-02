<template>
  <div>
    <UCard v-if="page">
      <article class="prose dark:prose-invert max-w-none">
        <ContentRenderer :value="page" />
      </article>

      <!-- Table of Contents -->
      <template #footer v-if="page.body?.toc?.links?.length">
        <UDivider class="my-6" />
        <div class="mt-6">
          <h3 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
            Table of Contents
          </h3>
          <ul class="space-y-2 text-sm">
            <li v-for="link in page.body.toc.links" :key="link.id">
              <a
                :href="`#${link.id}`"
                class="text-gray-600 dark:text-gray-400 hover:text-primary"
              >
                {{ link.text }}
              </a>
            </li>
          </ul>
        </div>
      </template>
    </UCard>

    <UCard v-else class="text-center py-12">
      <UIcon name="i-heroicons-document-magnifying-glass" class="w-16 h-16 mx-auto text-gray-400 mb-4" />
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
        Page Not Found
      </h2>
      <p class="text-gray-600 dark:text-gray-400 mb-6">
        The page you're looking for doesn't exist.
      </p>
      <UButton to="/" icon="i-heroicons-home">
        Back to Home
      </UButton>
    </UCard>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const { data: page } = await useAsyncData(`content-${route.path}`, () =>
  queryContent(route.path).findOne()
)

// Set page title
if (page.value) {
  useHead({
    title: `${page.value.title} - Raspberry Pi Builds`
  })
}
</script>