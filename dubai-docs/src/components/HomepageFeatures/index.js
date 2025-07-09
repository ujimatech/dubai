import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Secure & Sovereign AI',
    // Placeholder SVG - ideally replace with a relevant icon (e.g., a lock, shield, cloud icon etc.)
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        Keep sensitive data within your secure, on-premise or private cloud environments,
        ensuring uncompromised privacy and regulatory compliance.
      </>
    ),
  },
  {
    title: 'Rapid Time-to-Value',
    // Placeholder SVG - ideally replace with a relevant icon (e.g., a clock, speed meter, upward arrow)
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        Transform AI concepts into operational realities faster, leveraging rapid
        prototyping and agile deployment capabilities that drive immediate business impact.
      </>
    ),
  },
  {
    title: 'Intelligent AI Orchestration',
    // Placeholder SVG - ideally replace with a relevant icon (e.g., interconnected nodes, a conductor)
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        Orchestrate complex, multi-step AI workflows by intelligently connecting
        various models (LLMs, ML) with your internal systems.
      </>
    ),
  },
  {
    title: 'Future-Proof Scalability',
    // Placeholder SVG - ideally replace with a relevant icon (e.g., a growing graph, a flexible system)
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default, // Reusing for now, but distinct would be better
    description: (
      <>
        Build a resilient AI infrastructure that seamlessly integrates new technologies
        and scales effortlessly to meet evolving business demands.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}