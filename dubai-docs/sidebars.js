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
  // Custom sidebar for CognicellAI documentation
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
        'success-stories/overview',
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
