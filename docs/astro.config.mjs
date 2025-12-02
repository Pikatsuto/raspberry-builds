import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import mdx from '@astrojs/mdx';
import vue from '@astrojs/vue';

// https://astro.build/config
export default defineConfig({
  site: 'https://pikatsuto.github.io',
  base: '/raspberry-builds',
  integrations: [
    tailwind(),
    mdx(),
    vue()
  ],
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      wrap: true
    }
  },
  output: 'static'
});