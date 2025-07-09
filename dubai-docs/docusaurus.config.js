// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const {themes} = require('prism-react-renderer');
const lightCodeTheme = themes.github;
const darkCodeTheme = themes.dracula;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'CognicellAI AI Orchestration Hub',
  tagline: 'Intelligent Foundations. Infinite Possibilities.',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://CognicellAI.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  baseUrl: '/',

  // GitHub pages deployment config for your organization
  organizationName: 'CognicellAI', // Your GitHub organization name
  projectName: 'CognicellAI.github.io', // Your GitHub repository MUST be named this for an Org site
  trailingSlash: false, // Recommended for cleaner URLs

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          editUrl: 'https://github.com/your-org/dubai-docs/tree/main/',
        },
        blog: {
          showReadingTime: true,
          editUrl: 'https://github.com/your-org/dubai-docs/tree/main/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
    ],
  ],
  markdown: {
    mermaid: true, // Enable Mermaid support in Markdown
  },
  themes: [
    '@docusaurus/theme-mermaid'
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'CognicellAI Orchestration Hub',
        logo: {
          alt: 'CognicellAI Logo',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'dubaiSidebar',
            position: 'left',
            label: 'Documentation',
          },
          {
            href: 'https://github.com/CognicellAI/CognicellAI.github.io',
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Documentation',
            items: [
              {
                label: 'Overview',
                to: '/docs/overview/executive-summary',
              },
              {
                label: 'Architecture',
                to: '/docs/architecture/c4-system-context',
              },
              {
                label: 'Success Stories',
                to: '/docs/success-stories/telecommunications',
              },
            ],
          },
          // {
          //   title: 'Community',
          //   items: [
          //     {
          //       label: 'Stack Overflow',
          //       href: 'https://stackoverflow.com/questions/tagged/dubai',
          //     },
          //     {
          //       label: 'Discord',
          //       href: 'https://discordapp.com/invite/dubai',
          //     },
          //   ],
          // },
          // {
          //   title: 'More',
          //   items: [
          //     {
          //       label: 'Blog',
          //       to: '/blog',
          //     },
          //     {
          //       label: 'GitHub',
          //       href: 'https://github.com/your-org/dubai',
          //     },
          //   ],
          // },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} CognicellAI. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['yaml', 'json', 'bash', 'hcl', 'diff', 'docker'],
      },
      mermaid: {
        theme: { light: 'neutral', dark: 'forest' },
      },
    }),
};

module.exports = config;
