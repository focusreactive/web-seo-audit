# Gatsby SEO Patterns Reference

## Overview

SEO patterns for Gatsby 3, 4, and 5. Each pattern includes detection rules, correct implementation, anti-patterns, and **version gates**.

**Version gate notation**: `[v4+]` = Gatsby >= 4. `[v3+]` = Gatsby >= 3. `[any]` = all versions.

## Version Detection

```
grep: "\"gatsby\":\s*\"[\^~]?5" package.json   # v5
grep: "\"gatsby\":\s*\"[\^~]?4" package.json   # v4
grep: "\"gatsby\":\s*\"[\^~]?3" package.json   # v3
glob: gatsby-config.{js,ts,mjs}
glob: gatsby-node.{js,ts,mjs}
```

**Rules**: v5 requires React 18 / Node 18+. v4 requires React 17+ / Node 14+. v3 requires React 16.9+ / Node 12+. Default to v4 if unknown.

---

## Head API Patterns [v4+]

### Head API [v4.19+]

**Detection**: `grep "export.*Head|export const Head|export function Head" src/**/*.{tsx,jsx,ts,js}`

**Correct — Static Head**:
```tsx
// src/pages/index.tsx
export default function IndexPage() {
  return <main><h1>Welcome</h1></main>;
}

export function Head() {
  return (
    <>
      <title>Home | My Site</title>
      <meta name="description" content="Site description" />
      <meta property="og:title" content="Home | My Site" />
      <meta property="og:image" content="https://example.com/og.jpg" />
      <link rel="canonical" href="https://example.com/" />
    </>
  );
}
```

**Correct — Dynamic Head with page query data**:
```tsx
// src/pages/{mdx.frontmatter__slug}.tsx
import { graphql, HeadFC } from 'gatsby';

export const Head: HeadFC = ({ data }) => (
  <>
    <title>{data.mdx.frontmatter.title} | My Blog</title>
    <meta name="description" content={data.mdx.frontmatter.excerpt} />
    <link rel="canonical" href={`https://example.com/blog/${data.mdx.frontmatter.slug}`} />
  </>
);

export const query = graphql`
  query ($id: String!) {
    mdx(id: { eq: $id }) { frontmatter { title excerpt slug } body }
  }
`;
```

**Anti-patterns**:
- Using `react-helmet` in Gatsby v4+ instead of Head API
- Missing `export` on Head (must be a named export)
- Using Head in non-page components (only works in pages/templates)
- Placing `<html>`/`<body>` attributes in Head (use `gatsby-ssr.js` `onRenderBody`)

**Detection for anti-pattern**: `grep "react-helmet|gatsby-plugin-react-helmet" src/pages/**/*.{tsx,jsx} package.json`

### gatsby-plugin-react-helmet (Legacy) [v3]

**Detection**: `grep "gatsby-plugin-react-helmet|react-helmet" package.json`

**Correct**:
```tsx
// src/components/seo.tsx
import { Helmet } from 'react-helmet';
import { useStaticQuery, graphql } from 'gatsby';

export function SEO({ title, description, pathname }) {
  const { site } = useStaticQuery(graphql`
    query { site { siteMetadata { title description siteUrl image } } }
  `);
  const seo = {
    title, description: description || site.siteMetadata.description,
    url: `${site.siteMetadata.siteUrl}${pathname || ''}`,
  };
  return (
    <Helmet titleTemplate={`%s | ${site.siteMetadata.title}`}>
      <title>{seo.title}</title>
      <meta name="description" content={seo.description} />
      <meta property="og:title" content={seo.title} />
      <link rel="canonical" href={seo.url} />
    </Helmet>
  );
}
```

**Anti-patterns**:
- Missing `gatsby-plugin-react-helmet` in `gatsby-config.js` plugins (Helmet won't SSR)
- Using Helmet without the plugin (client-side only, invisible to crawlers)

**Detection for anti-pattern**: `grep "react-helmet" src/**/*.{tsx,jsx}` then verify `grep "gatsby-plugin-react-helmet" gatsby-config.{js,ts}`

---

## Data Layer Patterns [any]

### GraphQL SEO Queries [any]

**Detection**: `grep "useStaticQuery|graphql\`|export const query" src/**/*.{tsx,jsx,ts,js}`

**Correct — useStaticQuery for reusable SEO data**:
```tsx
// src/hooks/use-site-metadata.ts
import { graphql, useStaticQuery } from 'gatsby';

export function useSiteMetadata() {
  const data = useStaticQuery(graphql`
    query {
      site { siteMetadata { title description siteUrl image twitterUsername } }
    }
  `);
  return data.site.siteMetadata;
}
```

**Anti-patterns**:
- Queries omitting SEO fields (title, description, excerpt, image)
- Using `fetch()`/`axios` at runtime for content that should be queried at build time
- Missing `siteUrl` in siteMetadata (needed for canonical URLs and OG tags)

**Detection for anti-pattern**: `grep "useEffect.*fetch|axios\.get" src/pages/**/*.{tsx,jsx} src/templates/**/*.{tsx,jsx}`

### gatsby-config.js siteMetadata [any]

**Detection**: `grep "siteMetadata" gatsby-config.{js,ts,mjs}`

**Correct**:
```js
module.exports = {
  siteMetadata: {
    title: 'My Gatsby Site',
    description: 'A comprehensive description for search engines',
    siteUrl: 'https://example.com',
    image: '/default-og-image.jpg',
    twitterUsername: '@example',
  },
};
```

**Anti-patterns**:
- Missing `siteMetadata` entirely
- Missing `siteUrl` (breaks canonical URLs, sitemap, OG tags) — flag as HIGH
- Hardcoding URLs in components instead of using `siteMetadata.siteUrl`

### SEO Component Pattern [any]

**Detection**: `glob src/components/{seo,SEO,Seo}.{tsx,jsx,ts,js}`

**Correct — Reusable SEO component (v4+ Head API)**:
```tsx
// src/components/seo.tsx
import { useSiteMetadata } from '../hooks/use-site-metadata';

export function SEO({ title, description, pathname, image, children }) {
  const defaults = useSiteMetadata();
  const seo = {
    title: title || defaults.title,
    description: description || defaults.description,
    url: `${defaults.siteUrl}${pathname || ''}`,
    image: `${defaults.siteUrl}${image || defaults.image}`,
  };
  return (
    <>
      <title>{seo.title}</title>
      <meta name="description" content={seo.description} />
      <meta property="og:title" content={seo.title} />
      <meta property="og:description" content={seo.description} />
      <meta property="og:url" content={seo.url} />
      <meta property="og:image" content={seo.image} />
      <meta name="twitter:card" content="summary_large_image" />
      {children}
    </>
  );
}
// Usage: export const Head = () => <SEO title="About" pathname="/about" />
```

**Anti-patterns**:
- No shared SEO component (every page defines meta tags independently)
- SEO component without fallback values from siteMetadata

---

## Image Optimization [v3+]

### gatsby-plugin-image [v3+]

**Detection**: `grep "gatsby-plugin-image|GatsbyImage|StaticImage" src/**/*.{tsx,jsx} package.json`

**Correct — StaticImage**:
```tsx
import { StaticImage } from 'gatsby-plugin-image';
<StaticImage src="../images/hero.jpg" alt="Descriptive alt text"
  placeholder="blurred" layout="fullWidth" formats={['auto', 'webp', 'avif']} />
```

**Correct — GatsbyImage for queried images**:
```tsx
import { GatsbyImage, getImage } from 'gatsby-plugin-image';
const image = getImage(data.mdx.frontmatter.featuredImage);
{image && <GatsbyImage image={image} alt={data.mdx.frontmatter.featuredImageAlt} />}
```

**Anti-patterns**:
- Plain `<img>` tags instead of `StaticImage`/`GatsbyImage`
- Missing `alt` attribute on meaningful images
- `StaticImage` with dynamic `src` props (src must be a static string)
- Missing `placeholder` prop (causes layout shift)

**Detection for anti-pattern**: `grep "<img " src/**/*.{tsx,jsx}`

### gatsby-image (Legacy) [v2]

**Detection**: `grep "gatsby-image" package.json`

**Rules**: If Gatsby >= 3 and project still uses `gatsby-image`, flag as MEDIUM — migrate to `gatsby-plugin-image`.

### Image Processing Pipeline [any]

**Detection**: `grep "gatsby-plugin-sharp|gatsby-transformer-sharp" gatsby-config.{js,ts,mjs}`

**Correct**:
```js
plugins: [
  'gatsby-plugin-sharp', 'gatsby-transformer-sharp',
  { resolve: 'gatsby-source-filesystem', options: { name: 'images', path: `${__dirname}/src/images` } },
  'gatsby-plugin-image',
]
```

**Anti-patterns**:
- Missing `gatsby-plugin-sharp` or `gatsby-transformer-sharp` (image queries fail)
- Missing `gatsby-source-filesystem` for image directories
- `gatsby-plugin-image` without `gatsby-plugin-sharp` — flag as HIGH

---

## Plugin Ecosystem [any]

### gatsby-plugin-sitemap [any]

**Detection**: `grep "gatsby-plugin-sitemap" gatsby-config.{js,ts,mjs} package.json`

**Correct**:
```js
{
  resolve: 'gatsby-plugin-sitemap',
  options: {
    excludes: ['/404', '/404.html', '/dev-404-page'],
    serialize: ({ path, pageContext }) => ({
      url: path,
      changefreq: path === '/' ? 'daily' : 'weekly',
      priority: path === '/' ? 1.0 : 0.7,
      lastmod: pageContext?.lastModified || new Date().toISOString(),
    }),
  },
},
```

**Anti-patterns**:
- Missing sitemap plugin entirely — flag as HIGH
- Missing `siteUrl` in siteMetadata (plugin requires it)
- Not excluding utility pages (404, dev-404-page)

### gatsby-plugin-canonical-urls [any]

**Detection**: `grep "gatsby-plugin-canonical-urls" gatsby-config.{js,ts,mjs} package.json`

**Correct**:
```js
{ resolve: 'gatsby-plugin-canonical-urls', options: { siteUrl: 'https://example.com', stripQueryString: true } }
```

**Anti-patterns**:
- No canonical URL strategy (neither plugin nor manual `<link rel="canonical">`)
- Trailing slash mismatch between canonical URL and actual URL
- Both plugin and manual canonical links (duplicates)

### gatsby-plugin-robots-txt [any]

**Detection**: `grep "gatsby-plugin-robots-txt" gatsby-config.{js,ts,mjs} package.json`

**Correct**:
```js
{
  resolve: 'gatsby-plugin-robots-txt',
  options: {
    host: 'https://example.com',
    sitemap: 'https://example.com/sitemap-index.xml',
    resolveEnv: () => process.env.GATSBY_ENV || process.env.NODE_ENV,
    env: {
      development: { policy: [{ userAgent: '*', disallow: ['/'] }] },
      production: { policy: [{ userAgent: '*', allow: '/' }] },
    },
  },
},
```

**Anti-patterns**:
- No robots.txt at all (neither plugin nor static file)
- Blocking crawlers in production
- No staging/production differentiation (staging indexed by search engines)

### gatsby-plugin-manifest [any]

**Detection**: `grep "gatsby-plugin-manifest" gatsby-config.{js,ts,mjs} package.json`

**Correct**:
```js
{
  resolve: 'gatsby-plugin-manifest',
  options: {
    name: 'My Gatsby Site', short_name: 'MySite', start_url: '/',
    background_color: '#ffffff', theme_color: '#663399', display: 'standalone',
    icon: 'src/images/icon.png',
  },
},
```

**Anti-patterns**: Missing manifest plugin (no PWA signal), missing `icon` field (no favicon).

---

## Routing & Pages [any]

### Page Creation via createPage API [any]

**Detection**: `grep "createPage" gatsby-node.{js,ts,mjs}`

**Correct**:
```js
// gatsby-node.js
exports.createPages = async ({ graphql, actions }) => {
  const { createPage } = actions;
  const result = await graphql(`
    query { allMdx { nodes { id frontmatter { slug title description date }
      internal { contentFilePath } } } }
  `);
  if (result.errors) throw result.errors;

  const template = require.resolve('./src/templates/blog-post.tsx');
  result.data.allMdx.nodes.forEach((node) => {
    createPage({
      path: `/blog/${node.frontmatter.slug}`,
      component: `${template}?__contentFilePath=${node.internal.contentFilePath}`,
      context: { id: node.id, title: node.frontmatter.title,
        description: node.frontmatter.description, lastModified: node.frontmatter.date },
    });
  });
};
```

**Anti-patterns**:
- `createPage` without SEO fields in `context` (title, description missing)
- Missing error handling on GraphQL result (silent build failures)
- Not using `createRedirect` for URL changes (breaks backlinks)
- Inconsistent trailing slashes in generated paths

### Custom 404 Page [any]

**Detection**: `glob src/pages/404.{tsx,jsx,ts,js}`

**Correct**:
```tsx
import { Link } from 'gatsby';

export default function NotFoundPage() {
  return (
    <main>
      <h1>Page Not Found</h1>
      <Link to="/">Go back to the homepage</Link>
    </main>
  );
}

export function Head() {
  return (
    <>
      <title>404: Page Not Found</title>
      <meta name="robots" content="noindex" />
    </>
  );
}
```

**Anti-patterns**:
- Missing 404 page entirely — flag as MEDIUM
- 404 page without `noindex` meta tag
- Missing Head export on 404 page

---

## Performance Patterns

### Script Component [v4.15+]

**Detection**: `grep "<Script |from 'gatsby'" src/**/*.{tsx,jsx,ts,js}` and verify `Script` import

**Correct**:
```tsx
import { Script } from 'gatsby';

<Script src="https://analytics.example.com/script.js" strategy="idle" />
<Script src="https://widget.example.com/embed.js" strategy="post-hydrate" />
<Script id="schema-org" strategy="post-hydrate">
  {JSON.stringify({ "@context": "https://schema.org", "@type": "WebSite", "name": "My Site" })}
</Script>
```

**Strategies**: `post-hydrate` (after React hydration), `idle` (browser idle time), `off-main-thread` (Partytown web worker).

**Anti-patterns**:
- Raw `<script>` tags instead of `<Script>` component
- Third-party scripts without loading strategy (render-blocking)
- `off-main-thread` for scripts needing DOM access

**Detection for anti-pattern**: `grep "<script " src/**/*.{tsx,jsx}` (excluding `gatsby-ssr.js`)

### Partial Hydration [v5+]

**Detection**: `grep "use client|PARTIAL_HYDRATION" gatsby-config.{js,ts,mjs} src/**/*.{tsx,jsx}`

**Rules**: Gatsby 5 Partial Hydration is experimental. LOW priority — informational. If enabled, verify interactive components are marked with `"use client"`.

### Bundle Analysis [any]

**Detection**: `grep "gatsby-plugin-webpack-bundle-analyzer" gatsby-config.{js,ts,mjs} package.json`

**Rules**: LOW priority — informational. Presence indicates performance awareness.

### Gatsby Link [any]

**Detection**: `grep "<a href|from 'gatsby'" src/**/*.{tsx,jsx}`

**Correct**:
```tsx
import { Link } from 'gatsby';
<Link to="/about">About Us</Link>
<Link to="/blog" activeClassName="active" partiallyActive={true}>Blog</Link>
// External links use <a>
<a href="https://external.com" rel="noopener noreferrer" target="_blank">External</a>
```

**Anti-patterns**:
- `<a href="/about">` for internal navigation (no prefetching, full reload)
- Gatsby `Link` for external URLs (will break)
- `window.location`/`navigate()` for links that should be crawlable

**Detection for anti-pattern**: `grep "<a href=\"/" src/**/*.{tsx,jsx}`

---

## Common Anti-Patterns (All Versions)

### Missing SEO Plugin Ecosystem

**Detection**:
```
grep "gatsby-plugin-sitemap" gatsby-config.{js,ts,mjs}
grep "gatsby-plugin-robots-txt" gatsby-config.{js,ts,mjs}
grep "gatsby-plugin-canonical-urls" gatsby-config.{js,ts,mjs}
grep "gatsby-plugin-image" gatsby-config.{js,ts,mjs}
```

**Rules**: Missing sitemap = HIGH. Missing robots.txt = HIGH. No canonical strategy = MEDIUM. Missing image optimization = MEDIUM. If 3+ missing, compound penalty — CRITICAL "Missing SEO foundation".

### Client-Side Data Fetching for SEO Content

**Detection**: `grep "useEffect.*fetch|axios\.|window\.fetch" src/pages/**/*.{tsx,jsx} src/templates/**/*.{tsx,jsx}`

**Problem**: Gatsby builds static HTML at build time. Content fetched client-side via `useEffect` won't be in static HTML — invisible to crawlers.

**Anti-pattern**:
```tsx
export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  useEffect(() => { fetch('/api/products').then(r => r.json()).then(setProducts); }, []);
  return <main>{products.map(p => <h2 key={p.id}>{p.name}</h2>)}</main>;
}
```

**Correct**: Use GraphQL page queries to fetch data at build time.

### GraphQL Queries Without SEO Fields

**Detection**: `grep "graphql\`" src/pages/**/*.{tsx,jsx} src/templates/**/*.{tsx,jsx}`

**Rules**: Page queries lacking `title`/`description`/`excerpt` = MEDIUM. Template queries without image fields = LOW. Verify queried SEO fields are used in Head API or SEO component.

### Missing Image Optimization Pipeline

**Detection**: `grep "<img " src/**/*.{tsx,jsx}` cross-referenced with `grep "gatsby-plugin-image" gatsby-config.{js,ts,mjs}`

**Rules**: `<img>` tags without `gatsby-plugin-image` configured = HIGH. `gatsby-plugin-image` without `gatsby-plugin-sharp` = HIGH.

---

## Performance Anti-Patterns (Gatsby-Specific)

### Heavy gatsby-browser.js [any]

**Detection**: `grep "import" gatsby-browser.{js,ts,mjs}`

**Rules**: Heavy libraries in `gatsby-browser.js` = HIGH — runs on every page.

**Anti-pattern**:
```js
import 'bootstrap/dist/css/bootstrap.min.css'; // 200KB+ on every page
import moment from 'moment'; // 300KB+ on every page
```

### Missing Trailing Slash Consistency [v4.7+]

**Detection**: `grep "trailingSlash" gatsby-config.{js,ts,mjs}`

**Correct**: `trailingSlash: 'always'` (or `'never'`) in gatsby-config.

**Rules**: Missing setting = MEDIUM — causes duplicate content (both `/about` and `/about/` indexed). Verify `Link` `to` props and canonical URLs match the setting.

### Importing Full Libraries [any]

**Detection**: `grep "from 'lodash'$|from \"lodash\"$|import moment|from '@mui/material'$" src/**/*.{tsx,jsx,ts,js}`

**Rules**: Root-level imports = MEDIUM. Use subpath imports (`lodash/get`) or lighter alternatives (`date-fns`).

### SSR-Unsafe Code [any]

**Detection**: `grep "window\.|document\.|navigator\." src/**/*.{tsx,jsx,ts,js}`

**Problem**: Direct browser API access outside `useEffect` or `typeof window !== 'undefined'` guards causes build failures.

**Anti-pattern**:
```tsx
const isDesktop = window.innerWidth > 768; // Crashes during gatsby build
```

**Correct**: Wrap in `useEffect` or guard with `typeof window !== 'undefined'`.

**Detection for anti-pattern**: Verify matches are inside `useEffect` or guarded by `typeof window !== 'undefined'`

### Excessive useStaticQuery Calls [any]

**Detection**: `grep "useStaticQuery" src/components/**/*.{tsx,jsx}` — count occurrences.

**Rules**: >10 calls = MEDIUM — consider consolidating queries or lifting to page level.
