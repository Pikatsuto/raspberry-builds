// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import vue from '@astrojs/vue';

// https://astro.build/config
export default defineConfig({
	site: 'https://pikatsuto.github.io',
	base: '/raspberry-builds',
	integrations: [
		starlight({
			title: 'Raspberry Pi Builds',
			description: 'Documentation for Raspberry Pi hybrid images with RaspiOS boot + Debian ARM64 rootfs',
			logo: {
				src: './public/favicon.svg',
			},
			favicon: '/favicon.svg',
			defaultLocale: 'root',
			locales: {
				root: {
					label: 'English',
					lang: 'en',
				},
			},
			social: [
				{
					icon: 'github',
					label: 'GitHub',
					href: 'https://github.com/Pikatsuto/raspberry-builds',
				},
			],
			customCss: [
				'./src/styles/custom.css',
			],
			tableOfContents: {
				minHeadingLevel: 2,
				maxHeadingLevel: 4,
			},
			sidebar: [
				{
					label: 'Getting Started',
					items: [
						{ label: 'Project Overview', slug: 'readme' },
						{ label: 'Quick Start', slug: 'docs/home' },
					],
				},
				{
					label: 'Documentation',
					autogenerate: { directory: 'docs' },
				},
				{
					label: 'Image Sources',
					autogenerate: { directory: 'image-sources' },
				},
				{
					label: 'Releases',
					items: [
						{ label: 'Stable Releases', link: '/releases' },
						{ label: 'Test Releases', link: '/test-releases' },
						{ label: 'Preview Releases', link: '/preview-releases' },
					],
				},
			],
			components: {
				Head: './src/components/Head.astro',
				Header: './src/components/Header.astro',
			},
		}),
		vue(),
	],
});
