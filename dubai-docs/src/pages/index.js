import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext'; // Keep this import as it's part of the standard Docusaurus template, even if siteConfig isn't used in HomepageHeader directly now
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';

import Heading from '@theme/Heading';
import styles from './index.module.css';

function HomepageHeader() {
  // const {siteConfig} = useDocusaurusContext(); // Removed direct usage
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <img
          src="/img/logo.svg"
          alt="CognicellAI Logo"
          className={styles.heroImage}
        />
        {/* Main Headline */}
        <Heading as="h1" className="hero__title">
          CognicellAI: Your Enterprise AI Orchestration Hub
        </Heading>
        {/* Tagline */}
        <p className="hero__subtitle">
          Unleash the **Agentic Operation Ecosystem**: Intelligent, Adaptive AI for Business Transformation.
        </p>
        {/* Elevator Pitch */}
        <div className={styles.heroDescription}>
          CognicellAI empowers organizations to securely integrate, manage, and scale diverse AI models within their own infrastructure, accelerating innovation across sectors.
        </div>
        {/* Call to Action Buttons */}
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/overview/executive-summary">
            Explore Documentation
          </Link>
          {/*<Link*/}
          {/*  className="button button--secondary button--lg"*/}
          {/*  to="https://github.com/your-org/dubai/community"> /!* Placeholder for community link *!/*/}
          {/*  Join Our Community*/}
          {/*</Link>*/}
        </div>
        {/* Sector Impact Marquee */}
        <div className={styles.sectorMarquee}>
          <p>
            Solving critical challenges across: &nbsp;
            <span className={styles.sectorHighlight}>Manufacturing</span> • &nbsp;
            <span className={styles.sectorHighlight}>Financial Services</span> • &nbsp;
            <span className={styles.sectorHighlight}>Healthcare</span> • &nbsp;
            <span className={styles.sectorHighlight}>Media & Entertainment</span> • &nbsp; and more!
          </p>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext(); // Keeping this for the default Layout title/description
  return (
    <Layout
      title={`Home | ${siteConfig.title}`}
      description="Automate, orchestrate, and scale enterprise AI with CognicellAI's Agentic Operation Ecosystem.">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}