#!/bin/bash

echo "🚀 Starting Docusaurus setup for DubAI AI Orchestration Hub documentation..."
echo "----------------------------------------------------------------------"

# Define the project directory
PROJECT_DIR="dubai-docs"

# --- Step 1: Check for Node.js and npm ---
echo "Checking for Node.js and npm..."
if ! command -v node &> /dev/null
then
    echo "ERROR: Node.js is not found. Please install Node.js (which includes npm) to proceed."
    echo "Recommended: https://nodejs.org/en/download/"
    exit 1
fi
if ! command -v npm &> /dev/null
then
    echo "ERROR: npm is not found. Please install npm (comes with Node.js) to proceed."
    echo "Recommended: https://nodejs.org/en/download/"
    exit 1
fi
echo "Node.js and npm found. Proceeding..."

# --- Step 2: Create Docusaurus Project ---
if [ -d "$PROJECT_DIR" ]; then
    read -p "Directory '$PROJECT_DIR' already exists. Do you want to remove it and create a new one? (y/N): " -n 1 -r REPLY
    echo # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing '$PROJECT_DIR'..."
        rm -rf "$PROJECT_DIR"
    else
        echo "Exiting. Please remove or rename '$PROJECT_DIR' manually if you wish to run the script."
        exit 1
    fi
fi

echo "Creating new Docusaurus project in '$PROJECT_DIR'..."
# Fixed: Remove the problematic --typescript flag and use proper syntax
npx create-docusaurus@latest "$PROJECT_DIR" classic --skip-install
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create Docusaurus project. Exiting."
    exit 1
fi
echo "Docusaurus project created successfully."

# --- IMPORTANT: Change into the project directory for all subsequent operations ---
echo "Changing into project directory: $PROJECT_DIR"
cd "$PROJECT_DIR" || { echo "ERROR: Failed to enter project directory. Exiting."; exit 1; }

# --- Step 3: Install all dependencies first, then add Mermaid Plugin ---
echo "Installing Docusaurus dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Docusaurus dependencies. Check npm logs for details. Exiting."
    exit 1
fi
echo "Docusaurus dependencies installed."

echo "Installing @docusaurus/theme-mermaid..."
# Note: Using the official Docusaurus mermaid theme instead of the third-party plugin
npm install --save @docusaurus/theme-mermaid
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install @docusaurus/theme-mermaid. Check npm logs for details. Exiting."
    exit 1
fi
echo "Mermaid theme installed."

# --- Step 4: Create Content Directories & Placeholder Markdown Files ---
echo "Setting up content directories and placeholder markdown files..."

mkdir -p docs/architecture
mkdir -p docs/overview
mkdir -p docs/success-stories

# Architecture diagrams
ARCH_DIR="docs/architecture"
touch "$ARCH_DIR/c4-system-context.md"
touch "$ARCH_DIR/c4-container-diagram.md"
touch "$ARCH_DIR/c4-openwebui-components.md"
touch "$ARCH_DIR/c4-litellm-proxy-components.md"

# Overview content
OVERVIEW_DIR="docs/overview"
touch "$OVERVIEW_DIR/executive-summary.md"
touch "$OVERVIEW_DIR/challenge-solution.md"

# Customer Success Stories (placeholders)
SUCCESS_STORIES_DIR="docs/success-stories"
touch "$SUCCESS_STORIES_DIR/telecommunications.md"
touch "$SUCCESS_STORIES_DIR/healthcare.md"
touch "$SUCCESS_STORIES_DIR/manufacturing.md"
touch "$SUCCESS_STORIES_DIR/media-entertainment.md"
touch "$SUCCESS_STORIES_DIR/government.md"
touch "$SUCCESS_STORIES_DIR/education.md"
touch "$SUCCESS_STORIES_DIR/energy-utilities.md"
touch "$SUCCESS_STORIES_DIR/transportation-logistics.md"
touch "$SUCCESS_STORIES_DIR/financial-services.md"
touch "$SUCCESS_STORIES_DIR/retail-e-commerce.md"

echo "Placeholder markdown files created. Remember to copy your actual content here!"

# --- Step 5: Configure Docusaurus ---

echo "Configuring docusaurus.config.js and sidebars.js..."

# Create a backup of the original config
cp docusaurus.config.js docusaurus.config.js.bak

# Create a new docusaurus.config.js with our configuration
cat > docusaurus.config.js << 'DOCUSAURUS_CONFIG'
// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'DubAI AI Orchestration Hub',
  tagline: 'Enterprise AI orchestration and deployment platform',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://your-docusaurus-test-site.com',
  // Set the /<baseUrl>/ pathname under which your site is served
  baseUrl: '/',

  // GitHub pages deployment config
  organizationName: 'dubai', // Usually your GitHub org/user name
  projectName: 'dubai-docs', // Usually your repo name

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

  themes: [
    '@docusaurus/theme-mermaid'
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'DubAI Orchestration Hub',
        logo: {
          alt: 'DubAI Logo',
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
            href: 'https://github.com/your-org/dubai',
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
          {
            title: 'Community',
            items: [
              {
                label: 'Stack Overflow',
                href: 'https://stackoverflow.com/questions/tagged/dubai',
              },
              {
                label: 'Discord',
                href: 'https://discordapp.com/invite/dubai',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Blog',
                to: '/blog',
              },
              {
                label: 'GitHub',
                href: 'https://github.com/your-org/dubai',
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} DubAI. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['yaml', 'json', 'bash', 'hcl', 'diff', 'docker'],
      },
      mermaid: {
        theme: { light: 'default', dark: 'dark' },
      },
    }),
};

module.exports = config;
DOCUSAURUS_CONFIG

# Create/Update sidebars.js with our structure
cat > sidebars.js << 'SIDEBARS_CONFIG'
/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  // Custom sidebar for DubAI documentation
  dubaiSidebar: [
    {
      type: 'category',
      label: 'Overview',
      collapsed: false,
      items: [
        'overview/executive-summary',
        'overview/challenge-solution',
      ],
    },
    {
      type: 'category',
      label: 'Architecture Diagrams',
      collapsed: false,
      items: [
        'architecture/c4-system-context',
        'architecture/c4-container-diagram',
        'architecture/c4-openwebui-components',
        'architecture/c4-litellm-proxy-components',
      ],
    },
    {
      type: 'category',
      label: 'Customer Success Stories',
      collapsed: true,
      items: [
        'success-stories/telecommunications',
        'success-stories/healthcare',
        'success-stories/manufacturing',
        'success-stories/media-entertainment',
        'success-stories/government',
        'success-stories/education',
        'success-stories/energy-utilities',
        'success-stories/transportation-logistics',
        'success-stories/financial-services',
        'success-stories/retail-e-commerce',
      ],
    },
  ],
};

module.exports = sidebars;
SIDEBARS_CONFIG

echo "Docusaurus configuration updated and sidebar structure defined."

# Add a sample markdown file to test Mermaid support
cat > docs/architecture/c4-system-context.md << 'SAMPLE_MD'
---
sidebar_position: 1
title: C4 System Context Diagram
---

# C4 Level 1: System Context Diagram

This diagram shows the high-level context of the DubAI AI Orchestration Hub.

## System Context

```mermaid
graph TB
    subgraph "External Systems"
        ES1[External Applications]
        ES2[Development Teams]
        ES3[Operations Teams]
    end

    subgraph "DubAI System"
        DUBAI[DubAI AI Orchestration Hub]
    end

    subgraph "AI Services"
        AIS1[OpenAI]
        AIS2[Anthropic]
        AIS3[Google AI]
        AIS4[Local LLMs]
    end

    ES1 --> DUBAI
    ES2 --> DUBAI
    ES3 --> DUBAI
    DUBAI --> AIS1
    DUBAI --> AIS2
    DUBAI --> AIS3
    DUBAI --> AIS4