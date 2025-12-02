<template>
  <div>
    <UCard class="text-center py-12">
      <UIcon name="i-heroicons-document-magnifying-glass" class="w-20 h-20 mx-auto text-gray-400 mb-6" />
      <h1 class="text-4xl font-bold text-gray-900 dark:text-white mb-4">
        Page Not Found
      </h1>
      <p class="text-lg text-gray-600 dark:text-gray-400 mb-8">
        The page you're looking for doesn't exist or has been moved.
      </p>
      <div class="flex justify-center space-x-4">
        <UButton to="/" icon="i-heroicons-home" size="lg">
          Go Home
        </UButton>
        <UButton
          to="https://github.com/Pikatsuto/raspberry-builds"
          target="_blank"
          color="gray"
          variant="ghost"
          icon="i-heroicons-arrow-top-right-on-square"
          size="lg"
        >
          View Repository
        </UButton>
      </div>
    </UCard>
  </div>
</template>

<script setup lang="ts">
useHead({
  title: 'Page Not Found - Raspberry Pi Builds'
})
</script>