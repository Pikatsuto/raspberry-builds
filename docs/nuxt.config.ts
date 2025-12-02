// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  modules: ['@nuxt/content', '@nuxt/ui'],

  devtools: { enabled: true },

  css: ['~/assets/css/main.css'],

  content: {
    highlight: {
      theme: {
        default: 'github-light',
        dark: 'github-dark',
      },
      preload: ['bash', 'shell', 'yaml', 'json', 'markdown']
    },
    markdown: {
      toc: {
        depth: 3,
        searchDepth: 3
      }
    }
  },

  app: {
    baseURL: '/raspberry-builds/',
    head: {
      title: 'Raspberry Pi Builds Documentation',
      meta: [
        { charset: 'utf-8' },
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        {
          name: 'description',
          content: 'Documentation for Raspberry Pi hybrid image builder - combining RaspiOS boot with custom Debian ARM64 rootfs'
        }
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/raspberry-builds/favicon.ico' }
      ]
    }
  },

  nitro: {
    preset: 'static',
    output: {
      publicDir: '../dist'
    }
  },

  compatibilityDate: '2024-11-01'
})