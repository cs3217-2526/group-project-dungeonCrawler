import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Dungeon Crawler',
  tagline: 'A dungeon crawling RPG for iOS',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://cs3217-2526.github.io',
  baseUrl: '/group-project-dungeonCrawler/',

  organizationName: 'cs3217-2526',
  projectName: 'group-project-dungeonCrawler',
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'throw',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          path: '.',
          routeBasePath: '/',
          exclude: ['**/node_modules/**', 'README.md'],
        },
        blog: false,
        theme: {},
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Dungeon Crawler',
      logo: {
        alt: 'Dungeon Crawler Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'devGuideSidebar',
          position: 'left',
          label: 'Dev Guide',
        },
        {
          type: 'docSidebar',
          sidebarId: 'gameManualSidebar',
          position: 'left',
          label: 'Game Manual',
        },
        {
          href: 'https://github.com/cs3217-2526/group-project-dungeonCrawler',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Introduction',
              to: '/dev-guide/ecs',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/cs3217-2526/group-project-dungeonCrawler',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Dungeon Crawler. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
