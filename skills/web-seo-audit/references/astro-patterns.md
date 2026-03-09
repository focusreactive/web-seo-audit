# Astro SEO Patterns Reference

## Overview

This reference covers SEO-related patterns for Astro 2, 3, and 4. Each pattern includes detection rules (grep/glob patterns), correct implementation, common anti-patterns, and **version gates** indicating the minimum Astro version required.

**Version gate notation**: `[v2+]` means the check only applies to Astro >= 2. `[v3+]` means >= 3. `[v4+]` means >= 4. `[any]` means all supported versions. Checks without a version gate apply to all versions.

## Version Detection

Determine the Astro version before applying version-gated rules:

```
# Astro version from package.json
grep: "\"astro\":\s*\"[~^]?(\d+)" package.json
grep: "\"astro\":\s*\"[~^]?(\d+)" package-lock.json
grep: "\"astro\":\s*\"[~^]?(\d+)" pnpm-lock.yaml
grep: "\"astro\":\s*\"[~^]?(\d+)" yarn.lock

# Astro config file
glob: astro.config.{mjs,ts,js,cjs}
```

**Rules**:
- Extract major version number: `2`, `3`, or `4`
- If version cannot be determined, assume latest stable and note LOW confidence
- Check `astro.config.*` for integrations, output mode, and adapter configuration

---

## Head & Metadata Patterns [any]

### `<head>` in Layouts

**Detection**: `grep "<head>" src/layouts/**/*.astro`

**Correct**:
```astro
---
// src/layouts/BaseLayout.astro
interface Props {
  title: string;
  description: string;
}

const { title, description } = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title}</title>
    <meta name="description" content={description} />
    <link rel="canonical" href={Astro.url.href} />
    <slot name="head" />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Anti-patterns**:
- Missing `<head>` in layout files entirely
- Pages defining their own `<head>` instead of using a shared layout
- Missing `lang` attribute on `<html>`
- Missing `<meta charset>` or `<meta name="viewport">`

**Detection for anti-pattern**: `grep -L "<head>" src/layouts/**/*.astro`

### Astro.props for Meta

**Detection**: `grep "Astro.props" src/layouts/**/*.astro`

**Correct**:
```astro
---
// src/layouts/BaseLayout.astro
interface Props {
  title: string;
  description: string;
  ogImage?: string;
  ogType?: string;
  canonicalURL?: string;
  noindex?: boolean;
}

const {
  title,
  description,
  ogImage = '/default-og.jpg',
  ogType = 'website',
  canonicalURL = Astro.url.href,
  noindex = false,
} = Astro.props;
---

<html lang="en">
  <head>
    <title>{title}</title>
    <meta name="description" content={description} />
    {noindex && <meta name="robots" content="noindex, nofollow" />}
    <meta property="og:title" content={title} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={new URL(ogImage, Astro.site)} />
    <meta property="og:type" content={ogType} />
    <link rel="canonical" href={canonicalURL} />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Anti-patterns**:
- Hardcoded meta tags in layout instead of using props
- Missing TypeScript interface for props (loose typing leads to missing fields)
- Not providing default values for optional SEO fields

**Detection for anti-pattern**: `grep "<title>.*[^{].*</title>" src/layouts/**/*.astro` (hardcoded titles without expressions)

### Frontmatter Metadata

**Detection**: `grep "^title:|^description:|^ogImage:" src/content/**/*.{md,mdx}`

**Correct**:
```markdown
---
title: "How to Optimize Astro Sites for SEO"
description: "A comprehensive guide to SEO best practices in Astro, covering metadata, content collections, and performance."
pubDate: 2024-01-15
updatedDate: 2024-02-10
ogImage: "./blog-hero.jpg"
author: "Jane Smith"
tags: ["astro", "seo", "web-performance"]
---

Content starts here...
```

**Anti-patterns**:
- Missing `title` or `description` in frontmatter
- Title longer than 60 characters or description longer than 160 characters without truncation handling
- No `pubDate` or `updatedDate` for blog content (important for freshness signals)

**Detection for anti-pattern**: `grep -L "^description:" src/content/**/*.{md,mdx}`

### BaseHead Component Pattern

**Detection**: `glob src/components/BaseHead.astro src/components/Head.astro src/components/SEO.astro`

**Correct**:
```astro
---
// src/components/BaseHead.astro
interface Props {
  title: string;
  description: string;
  image?: string;
  canonicalURL?: string;
  type?: string;
}

const {
  title,
  description,
  image = '/social-card.jpg',
  canonicalURL = Astro.url.href,
  type = 'website',
} = Astro.props;

const resolvedImage = new URL(image, Astro.site).toString();
---

<!-- Global Meta -->
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<meta name="generator" content={Astro.generator} />

<!-- Canonical URL -->
<link rel="canonical" href={canonicalURL} />

<!-- Primary Meta Tags -->
<title>{title}</title>
<meta name="title" content={title} />
<meta name="description" content={description} />

<!-- Open Graph / Facebook -->
<meta property="og:type" content={type} />
<meta property="og:url" content={canonicalURL} />
<meta property="og:title" content={title} />
<meta property="og:description" content={description} />
<meta property="og:image" content={resolvedImage} />

<!-- Twitter -->
<meta property="twitter:card" content="summary_large_image" />
<meta property="twitter:url" content={canonicalURL} />
<meta property="twitter:title" content={title} />
<meta property="twitter:description" content={description} />
<meta property="twitter:image" content={resolvedImage} />
```

**Usage in layout**:
```astro
---
// src/layouts/BaseLayout.astro
import BaseHead from '../components/BaseHead.astro';

const { title, description } = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <BaseHead title={title} description={description} />
    <slot name="head" />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Anti-patterns**:
- Duplicating meta tags across multiple layouts instead of using a shared component
- Not resolving relative image paths against `Astro.site`
- Missing `Astro.site` configuration in `astro.config.mjs` (required for absolute URLs)

**Detection for anti-pattern**: `grep "site:" astro.config.{mjs,ts,js}` (missing site config)

---

## Content Collections [v2+]

### Content Collections with Schemas

**Detection**: `glob src/content/config.{ts,js} src/content.config.{ts,js}`

**Correct**:
```ts
// src/content/config.ts (v2-v3)
// src/content.config.ts (v4+, moved to project root of src)
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string().max(60),
    description: z.string().max(160),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    ogImage: z.string().optional(),
    author: z.string(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
    canonicalURL: z.string().url().optional(),
  }),
});

export const collections = { blog };
```

**Anti-patterns**:
- Content collections without Zod schema validation (no type safety for SEO fields)
- Missing `title` or `description` in the schema (not enforced at build time)
- No `max()` constraints on title/description length
- Not using `z.coerce.date()` for date fields (breaks date formatting)

**Detection for anti-pattern**: `grep "defineCollection" src/content/config.{ts,js} src/content.config.{ts,js}` then check for `schema:` presence

### image() in Schemas [v3+]

**Detection**: `grep "image()" src/content/config.{ts,js} src/content.config.{ts,js}`

**Correct**:
```ts
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: ({ image }) => z.object({
    title: z.string(),
    description: z.string(),
    cover: image().refine((img) => img.width >= 1080, {
      message: "Cover image must be at least 1080px wide for OG images",
    }),
    coverAlt: z.string(),
  }),
});

export const collections = { blog };
```

**Anti-patterns**:
- Using `z.string()` for image paths instead of the `image()` helper (skips image optimization and validation)
- Missing `coverAlt` or equivalent alt text field alongside image fields
- Not setting minimum dimension constraints for OG images

**Detection for anti-pattern**: `grep "z.string()" src/content/config.{ts,js}` and cross-reference with fields named `image`, `cover`, `hero`, `ogImage`

### Collection Queries

**Detection**: `grep "getCollection\|getEntry" src/pages/**/*.astro`

**Correct**:
```astro
---
// src/pages/blog/[...slug].astro
import { getCollection } from 'astro:content';
import BlogLayout from '../../layouts/BlogLayout.astro';

export async function getStaticPaths() {
  const posts = await getCollection('blog', ({ data }) => !data.draft);
  return posts.map((post) => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content } = await post.render();
---

<BlogLayout
  title={post.data.title}
  description={post.data.description}
  ogImage={post.data.ogImage}
  pubDate={post.data.pubDate}
>
  <Content />
</BlogLayout>
```

**Anti-patterns**:
- Not filtering draft posts in `getCollection` (draft content gets indexed)
- Missing `getStaticPaths` on dynamic collection routes
- Not passing collection metadata to layout for SEO tags

**Detection for anti-pattern**: `grep -L "getStaticPaths" src/pages/**/*[*.astro` (dynamic routes without getStaticPaths)

---

## Image Optimization [v3+]

### `<Image>` Component [v3+]

**Detection**: `grep "astro:assets\|<Image " src/**/*.astro`

**Correct**:
```astro
---
// src/pages/index.astro
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<!-- Above-the-fold: use loading="eager" -->
<Image
  src={heroImage}
  alt="Descriptive alt text for the hero image"
  width={1200}
  height={600}
  loading="eager"
  format="webp"
/>

<!-- Below-the-fold: lazy loads by default -->
<Image
  src={heroImage}
  alt="Descriptive alt text"
  width={400}
  height={300}
/>

<!-- Remote images (requires domains config) -->
<Image
  src="https://example.com/remote-image.jpg"
  alt="Remote image"
  width={800}
  height={400}
  inferSize
/>
```

**Anti-patterns**:
- Using raw `<img>` tags instead of `<Image>` component (no optimization)
- Missing `alt` attribute or empty `alt=""` on meaningful images
- Not setting `loading="eager"` on above-the-fold images
- Missing `width` and `height` (causes layout shift)

**Detection for anti-pattern**: `grep "<img " src/**/*.astro`

### `<Picture>` Component [v3+]

**Detection**: `grep "<Picture " src/**/*.astro`

**Correct**:
```astro
---
import { Picture } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<Picture
  src={heroImage}
  formats={['avif', 'webp']}
  alt="Descriptive alt text"
  width={1200}
  height={600}
  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 75vw, 1200px"
  loading="eager"
/>
```

**Anti-patterns**:
- Using `<Image>` when `<Picture>` would provide better format negotiation
- Not specifying `sizes` attribute for responsive images
- Missing `formats` array (defaults may not include avif)

### Assets Folder

**Detection**:
```
# Images properly in src/assets/
glob: src/assets/**/*.{jpg,jpeg,png,webp,avif,gif,svg}

# Images incorrectly in public/ (not optimized)
glob: public/**/*.{jpg,jpeg,png,webp,avif,gif}
```

**Correct**:
```astro
---
// Importing from src/assets — gets optimized
import logo from '../assets/logo.png';
import { Image } from 'astro:assets';
---

<Image src={logo} alt="Company logo" />
```

**Anti-patterns**:
- Storing images in `public/` instead of `src/assets/` — images in `public/` are served as-is without optimization
- Exception: favicons, social card fallbacks, and images referenced from external services should remain in `public/`

**Detection for anti-pattern**: `glob public/**/*.{jpg,jpeg,png}` (large unoptimized images in public)

**Rules**:
- Count images in `public/` (excluding `favicon`, `icon`, `apple-touch`, `og-`, `social-`)
- \>5 non-excluded images in public/ = MEDIUM — consider moving to `src/assets/` for optimization
- \>20 non-excluded images in public/ = HIGH — significant optimization opportunity missed

---

## Island Architecture [any]

Astro ships zero JavaScript by default. Interactive components must opt in via client directives. This is the primary performance advantage of Astro for SEO.

### client:load

**Detection**: `grep "client:load" src/**/*.astro`

**Rules**:
- `client:load` hydrates the component immediately on page load
- Use only for components that must be interactive on first paint (e.g., header navigation, authentication status)
- Every `client:load` adds JavaScript to the initial bundle

**Correct**:
```astro
---
import MobileNav from '../components/MobileNav.jsx';
---

<!-- Navigation must be interactive immediately -->
<MobileNav client:load />
```

### client:idle

**Detection**: `grep "client:idle" src/**/*.astro`

**Rules**:
- `client:idle` hydrates when the browser is idle (uses `requestIdleCallback`)
- Good for components needed soon but not on first paint
- Better than `client:load` for non-critical interactive elements

**Correct**:
```astro
---
import SearchWidget from '../components/SearchWidget.jsx';
---

<!-- Search can wait until browser is idle -->
<SearchWidget client:idle />
```

### client:visible

**Detection**: `grep "client:visible" src/**/*.astro`

**Rules**:
- `client:visible` hydrates when the component enters the viewport (uses `IntersectionObserver`)
- Best for below-the-fold interactive components
- Significantly reduces initial JavaScript payload

**Correct**:
```astro
---
import CommentsSection from '../components/CommentsSection.jsx';
import NewsletterSignup from '../components/NewsletterSignup.jsx';
---

<!-- Below-fold components: hydrate only when scrolled into view -->
<CommentsSection client:visible />
<NewsletterSignup client:visible />
```

### client:media

**Detection**: `grep "client:media" src/**/*.astro`

**Rules**:
- `client:media` hydrates only when a CSS media query matches
- Useful for mobile-only or desktop-only interactive components

**Correct**:
```astro
---
import MobileMenu from '../components/MobileMenu.jsx';
---

<!-- Only hydrate on mobile viewports -->
<MobileMenu client:media="(max-width: 768px)" />
```

### No Client Directive (Server-Only)

**Detection**: Count framework components without any `client:*` directive — these render as static HTML.

```
# Find framework components used in .astro files
grep: "import.*from.*components.*\.(jsx|tsx|svelte|vue)" src/**/*.astro

# Find client directives
grep: "client:(load|idle|visible|media|only)" src/**/*.astro
```

**Rules**:
- Components without a `client:*` directive render to static HTML with zero JavaScript — this is the default and best for SEO
- Ensure most components remain server-only unless interactivity is needed

**Correct**:
```astro
---
import Card from '../components/Card.jsx';
import Footer from '../components/Footer.astro';
---

<!-- No client directive = zero JS, just HTML -->
<Card title="Static card" description="Rendered at build time" />
<Footer />
```

### Island Architecture Anti-Patterns

**Detection**:
```
# Count client:load vs client:visible/client:idle
grep: "client:load" src/**/*.astro
grep: "client:visible|client:idle" src/**/*.astro
```

**Rules**:
- Ratio of `client:load` to total client directives > 60% = MEDIUM — most interactive components hydrate immediately, consider `client:idle` or `client:visible` for below-fold
- \>10 `client:load` directives across the site = HIGH — excessive eager hydration undermines Astro's zero-JS advantage

---

## Integrations [any]

### @astrojs/sitemap

**Detection**: `grep "@astrojs/sitemap" package.json astro.config.{mjs,ts,js}`

**Correct**:
```js
// astro.config.mjs
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://example.com',
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/admin/') && !page.includes('/draft/'),
      changefreq: 'weekly',
      priority: 0.7,
      lastmod: new Date(),
    }),
  ],
});
```

**Anti-patterns**:
- Missing `site` in `astro.config.mjs` (sitemap integration requires it for absolute URLs)
- Not filtering admin, draft, or utility pages from the sitemap
- No sitemap integration at all

**Detection for anti-pattern**: `grep -L "sitemap" astro.config.{mjs,ts,js}` and `grep -L "site:" astro.config.{mjs,ts,js}`

### @astrojs/rss

**Detection**: `grep "@astrojs/rss" package.json`

**Correct**:
```ts
// src/pages/rss.xml.ts
import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = await getCollection('blog', ({ data }) => !data.draft);
  return rss({
    title: 'My Blog',
    description: 'A blog about web development',
    site: context.site,
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: `/blog/${post.slug}/`,
    })),
    customData: '<language>en-us</language>',
  });
}
```

**Anti-patterns**:
- Content site with blog collection but no RSS feed
- RSS feed not filtering draft posts
- Missing `pubDate` in RSS items

**Detection for anti-pattern**: `glob src/pages/rss.xml.{ts,js}` (missing RSS endpoint for content sites)

### Astro SEO Integration

**Detection**: `grep "astro-seo" package.json`

**Correct**:
```astro
---
import { SEO } from 'astro-seo';
---

<head>
  <SEO
    title="Page Title"
    description="Page description"
    openGraph={{
      basic: {
        title: "Page Title",
        type: "website",
        image: "https://example.com/og-image.jpg",
      },
      optional: {
        description: "Page description",
      },
    }}
    twitter={{
      card: "summary_large_image",
      title: "Page Title",
      description: "Page description",
      image: "https://example.com/og-image.jpg",
    }}
    extend={{
      link: [{ rel: "canonical", href: "https://example.com/page" }],
    }}
  />
</head>
```

**Rules**:
- Using `astro-seo` is valid but not required — native Astro components with props work equally well
- If `astro-seo` is installed, check that it is actually used consistently across pages
- LOW priority — informational only

---

## Routing & Pages [any]

### File-Based Routing

**Detection**: `glob src/pages/**/*.astro src/pages/**/*.{md,mdx}`

**Correct**:
```
src/pages/
├── index.astro          → /
├── about.astro          → /about
├── blog/
│   ├── index.astro      → /blog
│   └── [slug].astro     → /blog/:slug
├── [...slug].astro      → catch-all route
└── rss.xml.ts           → /rss.xml
```

**Anti-patterns**:
- Content pages outside `src/pages/` that are not part of a content collection (unreachable by router)
- Orphan pages with no internal links pointing to them
- Using query parameters for content that should be separate pages

### getStaticPaths

**Detection**: `grep "getStaticPaths" src/pages/**/*.astro`

**Correct**:
```astro
---
// src/pages/blog/[slug].astro
import { getCollection } from 'astro:content';

export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map((post) => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content } = await post.render();
---

<html>
  <head><title>{post.data.title}</title></head>
  <body><Content /></body>
</html>
```

**Anti-patterns**:
- Dynamic routes `[slug].astro` or `[...slug].astro` without `getStaticPaths` (build error in static mode, runtime 404 risk in SSR)
- Not passing props through `getStaticPaths` (causes redundant data fetching)
- Returning empty or incomplete paths array

**Detection for anti-pattern**: `grep -rL "getStaticPaths" src/pages/**/*[*.astro src/pages/**/*...*.astro`

### 404.astro

**Detection**: `glob src/pages/404.astro`

**Correct**:
```astro
---
// src/pages/404.astro
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="Page Not Found" description="The page you are looking for does not exist.">
  <main>
    <h1>404 — Page Not Found</h1>
    <p>The page you are looking for does not exist.</p>
    <a href="/">Go back to the homepage</a>
  </main>
</BaseLayout>
```

**Anti-patterns**:
- Missing `404.astro` (Astro shows a default error page with no branding or navigation)
- 404 page without a link back to the homepage
- 404 page not using the site layout (missing navigation, inconsistent UX)
- Missing `noindex` meta tag on 404 page (optional but recommended)

**Detection for anti-pattern**: Missing `src/pages/404.astro`

### View Transitions [v3+]

**Detection**: `grep "ViewTransitions\|ClientRouter" src/**/*.astro`

**Correct (v3)**:
```astro
---
// src/layouts/BaseLayout.astro
import { ViewTransitions } from 'astro:transitions';
---

<html lang="en">
  <head>
    <ViewTransitions />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Correct (v4)** — renamed to `ClientRouter`:
```astro
---
// src/layouts/BaseLayout.astro
import { ClientRouter } from 'astro:transitions';
---

<html lang="en">
  <head>
    <ClientRouter />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Anti-patterns**:
- Using `ViewTransitions` in v4+ (deprecated, use `ClientRouter`)
- View transitions without `transition:animate` directives on key elements (no visible effect)
- View transitions breaking analytics page-view tracking (need to listen for `astro:after-swap`)

**Detection for anti-pattern**: `grep "ViewTransitions" src/**/*.astro` in v4+ projects

**SEO rules**:
- View transitions use client-side navigation — verify that `<title>` and `<meta>` tags update correctly on navigation
- LOW priority — view transitions do not affect crawler behavior since crawlers load pages individually

---

## Performance Patterns [any]

### Zero JS by Default

**Detection**:
```
# Count client directives (each adds JS)
grep: "client:(load|idle|visible|media|only)" src/**/*.astro

# Check output build for JS files
glob: dist/**/*.js
```

**Rules**:
- Astro ships zero JavaScript by default; every `client:*` directive adds JS
- Pages with zero `client:*` directives should produce no JavaScript in the output
- If JS is unexpectedly present, check for integrations that inject scripts

**Correct**:
```astro
---
// A fully static page — zero JS shipped
import BaseLayout from '../layouts/BaseLayout.astro';
import Card from '../components/Card.astro';
---

<BaseLayout title="About Us" description="Learn about our company.">
  <main>
    <h1>About Us</h1>
    <Card title="Our Mission" body="Building fast websites." />
  </main>
</BaseLayout>
```

### Inline Styles (Scoped CSS)

**Detection**: `grep "<style>" src/**/*.astro`

**Correct**:
```astro
---
// Astro scopes styles automatically
---

<div class="card">
  <h2>Title</h2>
  <p>Content</p>
</div>

<style>
  .card {
    padding: 1rem;
    border: 1px solid #eee;
    border-radius: 8px;
  }

  h2 {
    margin: 0 0 0.5rem;
  }
</style>
```

**Anti-patterns**:
- Using `<style is:global>` excessively — global styles defeat scoping and can cause specificity conflicts
- Large CSS files imported in layout that could be scoped to individual components
- Not leveraging Astro's built-in scoping (adding manual BEM or CSS modules unnecessarily)

**Detection for anti-pattern**: `grep "is:global" src/**/*.astro`

**Rules**:
- \>5 `is:global` style blocks = MEDIUM — excessive global styles, consider scoped styles
- `is:global` in layout file for base/reset styles = acceptable

### Prefetch [v3+]

**Detection**: `grep "prefetch" astro.config.{mjs,ts,js}` and `grep "data-astro-prefetch" src/**/*.astro`

**Correct**:
```js
// astro.config.mjs
export default defineConfig({
  prefetch: {
    prefetchAll: false,
    defaultStrategy: 'hover',
  },
});
```

```astro
<!-- Per-link prefetch control -->
<a href="/about" data-astro-prefetch>About Us</a>
<a href="/blog" data-astro-prefetch="viewport">Blog</a>

<!-- Opt out of prefetch on a specific link -->
<a href="/large-page" data-astro-prefetch="false">Large Page</a>
```

**Anti-patterns**:
- `prefetchAll: true` on sites with many pages (excessive network requests)
- Not using any prefetch strategy (missed performance opportunity)

**Rules**:
- `prefetchAll: true` with \>50 pages = MEDIUM — consider `hover` or `viewport` strategy instead
- No prefetch configuration at all = LOW — informational, consider enabling for better navigation

### content-visibility CSS

**Detection**: `grep "content-visibility" src/**/*.{astro,css}`

**Correct**:
```astro
<style>
  .below-fold-section {
    content-visibility: auto;
    contain-intrinsic-size: 0 500px;
  }
</style>

<section class="below-fold-section">
  <!-- Long content section below the fold -->
</section>
```

**Rules**:
- `content-visibility: auto` on long below-fold sections improves rendering performance
- Must include `contain-intrinsic-size` to prevent layout shifts
- LOW priority — optimization hint, not a requirement

---

## Structured Data [any]

### JSON-LD in Layouts

**Detection**: `grep "application/ld+json" src/layouts/**/*.astro src/pages/**/*.astro src/components/**/*.astro`

**Correct**:
```astro
---
// src/components/SchemaOrg.astro
interface Props {
  schema: Record<string, unknown>;
}

const { schema } = Astro.props;
---

<script type="application/ld+json" set:html={JSON.stringify(schema)} />
```

**Usage**:
```astro
---
// src/layouts/BaseLayout.astro
import SchemaOrg from '../components/SchemaOrg.astro';

const { title, description } = Astro.props;

const websiteSchema = {
  '@context': 'https://schema.org',
  '@type': 'WebSite',
  name: title,
  description: description,
  url: Astro.site,
};
---

<html lang="en">
  <head>
    <SchemaOrg schema={websiteSchema} />
  </head>
  <body>
    <slot />
  </body>
</html>
```

**Anti-patterns**:
- Using `innerHTML` or template literals directly in `<script>` tags (XSS risk, escaping issues)
- Hardcoded JSON-LD strings instead of building from data
- Missing `@context` or `@type` in schema objects

**Detection for anti-pattern**: `grep "innerHTML.*ld.json" src/**/*.astro`

### Dynamic Structured Data

**Detection**: `grep "application/ld+json" src/pages/**/*.astro src/layouts/**/*.astro`

**Correct**:
```astro
---
// src/pages/blog/[slug].astro
import SchemaOrg from '../../components/SchemaOrg.astro';
import { getCollection } from 'astro:content';

export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map((post) => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content } = await post.render();

const articleSchema = {
  '@context': 'https://schema.org',
  '@type': 'BlogPosting',
  headline: post.data.title,
  description: post.data.description,
  datePublished: post.data.pubDate.toISOString(),
  dateModified: post.data.updatedDate?.toISOString() ?? post.data.pubDate.toISOString(),
  author: {
    '@type': 'Person',
    name: post.data.author,
  },
  image: post.data.ogImage
    ? new URL(post.data.ogImage, Astro.site).toString()
    : undefined,
};
---

<html lang="en">
  <head>
    <title>{post.data.title}</title>
    <SchemaOrg schema={articleSchema} />
  </head>
  <body>
    <article>
      <Content />
    </article>
  </body>
</html>
```

**Anti-patterns**:
- Static structured data on pages with dynamic content (hardcoded dates, titles)
- Not using frontmatter/collection data to populate schema fields
- Missing `dateModified` on content that has been updated

---

## Common Anti-Patterns Summary

### Excessive client:load

**Detection**:
```
grep: "client:load" src/**/*.astro
grep: "client:visible|client:idle" src/**/*.astro
```

**Rules**:
- Components below the fold using `client:load` instead of `client:visible` = MEDIUM per instance
- Components not needed immediately using `client:load` instead of `client:idle` = MEDIUM per instance
- Apply per-template deduction, not per-page

**Correct**:
```astro
<!-- Above fold: client:load is appropriate -->
<HeaderNav client:load />

<!-- Below fold: use client:visible -->
<CommentsSection client:visible />
<RelatedPosts client:visible />

<!-- Not urgent: use client:idle -->
<AnalyticsWidget client:idle />
```

**Anti-pattern**:
```astro
<!-- Everything using client:load -->
<HeaderNav client:load />
<CommentsSection client:load />  <!-- Below fold -->
<RelatedPosts client:load />     <!-- Below fold -->
<AnalyticsWidget client:load />  <!-- Not urgent -->
```

### Missing Frontmatter SEO Fields

**Detection**: `grep -L "description" src/content/**/*.{md,mdx}`

**Rules**:
- Content pages missing `title` in frontmatter = HIGH
- Content pages missing `description` in frontmatter = HIGH
- Content pages missing `pubDate` = MEDIUM (blog/article content only)

### No `<head>` in Layout

**Detection**: `grep -L "<head>" src/layouts/**/*.astro`

**Rules**:
- Layout file without `<head>` = CRITICAL — pages using this layout will have no metadata, viewport, or charset declarations

### Images in public/ Instead of src/assets/

**Detection**:
```
glob: public/**/*.{jpg,jpeg,png,gif}
glob: src/assets/**/*.{jpg,jpeg,png,webp,avif,gif}
```

**Rules**:
- Large images (jpg, png) in `public/` = MEDIUM per image group — skips Astro's built-in image optimization pipeline
- SVGs and favicons in `public/` = acceptable (already optimized or need exact paths)
- Count non-excluded images: >5 = MEDIUM, >20 = HIGH

### Missing Astro.site Configuration

**Detection**: `grep "site:" astro.config.{mjs,ts,js}`

**Rules**:
- Missing `site` in Astro config = HIGH — required for canonical URLs, sitemap generation, RSS feeds, and absolute OG image URLs
- `Astro.site` returns `undefined` without this setting, breaking meta tag generation

**Correct**:
```js
// astro.config.mjs
export default defineConfig({
  site: 'https://example.com',
});
```

### Output Mode Awareness

**Detection**: `grep "output:" astro.config.{mjs,ts,js}`

**Rules**:
- `output: 'server'` — full SSR mode, requires adapter, check for proper caching headers
- `output: 'hybrid'` [v2+] — static by default, opt-in SSR per route
- `output: 'static'` — default, fully pre-rendered (best for SEO)
- In v4+, `hybrid` is the default and `prerender` is opt-in per page

```astro
---
// Opt-in to prerendering in hybrid/server mode
export const prerender = true;
---
```

**Anti-patterns**:
- Using `output: 'server'` for a content site that could be fully static
- Missing `export const prerender = true` on content pages in hybrid mode (renders at request time unnecessarily)

**Detection for anti-pattern**: `grep "output.*server" astro.config.{mjs,ts,js}` then check if content pages have `prerender`
