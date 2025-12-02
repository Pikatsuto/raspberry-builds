<template>
  <div>
    <UCard>
      <template #header>
        <h1 class="text-3xl font-bold">Welcome to Raspberry Pi Builds</h1>
      </template>

      <div class="prose dark:prose-invert max-w-none">
        <p class="lead">
          A toolchain for creating hybrid Raspberry Pi images that combine Raspberry Pi OS boot/firmware
          with custom Debian ARM64 root filesystems.
        </p>

        <h2>Quick Start</h2>
        <UAlert
          icon="i-heroicons-light-bulb"
          color="primary"
          variant="soft"
          title="Getting Started"
          description="Build your first custom Raspberry Pi image in minutes"
        />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 my-8 not-prose">
          <UCard>
            <template #header>
              <div class="flex items-center space-x-2">
                <UIcon name="i-heroicons-book-open" class="w-5 h-5" />
                <h3 class="text-lg font-semibold">Documentation</h3>
              </div>
            </template>
            <p class="text-gray-600 dark:text-gray-400">
              Learn how to build, customize, and deploy hybrid Raspberry Pi images
            </p>
            <template #footer>
              <UButton to="/docs/readme" block>
                Read the Docs
              </UButton>
            </template>
          </UCard>

          <UCard>
            <template #header>
              <div class="flex items-center space-x-2">
                <UIcon name="i-heroicons-arrow-down-tray" class="w-5 h-5" />
                <h3 class="text-lg font-semibold">Pre-built Images</h3>
              </div>
            </template>
            <p class="text-gray-600 dark:text-gray-400">
              Download ready-to-use images from GitHub Releases
            </p>
            <template #footer>
              <UButton to="/releases" block color="gray">
                View Releases
              </UButton>
            </template>
          </UCard>
        </div>

        <h2>Features</h2>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 my-6 not-prose">
          <div class="flex flex-col items-center text-center p-4">
            <UIcon name="i-heroicons-cog-6-tooth" class="w-12 h-12 text-primary mb-2" />
            <h4 class="font-semibold">Full Hardware Support</h4>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Raspberry Pi kernel and firmware for complete hardware compatibility
            </p>
          </div>
          <div class="flex flex-col items-center text-center p-4">
            <UIcon name="i-heroicons-cube" class="w-12 h-12 text-primary mb-2" />
            <h4 class="font-semibold">Custom Debian Userspace</h4>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Pure Debian ARM64 userspace with APT package management
            </p>
          </div>
          <div class="flex flex-col items-center text-center p-4">
            <UIcon name="i-heroicons-arrow-path" class="w-12 h-12 text-primary mb-2" />
            <h4 class="font-semibold">Automated Builds</h4>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              CI/CD pipeline with GitHub Actions for continuous image builds
            </p>
          </div>
        </div>

        <h2>Latest Images</h2>
        <UAlert
          icon="i-heroicons-arrow-down-tray"
          color="blue"
          variant="soft"
          title="Download Pre-built Images"
        >
          <template #description>
            <div class="mt-2">
              <p>Browse all available releases including stable versions and pre-releases</p>
              <UButton
                to="/releases"
                color="blue"
                class="mt-3"
                icon="i-heroicons-arrow-down-tray"
              >
                View All Releases
              </UButton>
            </div>
          </template>
        </UAlert>
      </div>
    </UCard>
  </div>
</template>