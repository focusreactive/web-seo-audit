# Next.js SEO Patterns Reference

## Overview

This reference covers SEO-related patterns for both Next.js App Router and Pages Router. Each pattern includes detection rules (grep/glob patterns), correct implementation, and common anti-patterns.

## Router Detection

Determine which router is in use before applying rules:

```
# App Router indicators
glob: app/**/page.{tsx,jsx,ts,js}
glob: app/**/layout.{tsx,jsx,ts,js}
grep: "export.*metadata" in app/**/page.{tsx,jsx,ts,js}
grep: "export.*generateMetadata" in app/**/page.{tsx,jsx,ts,js}

# Pages Router indicators
glob: pages/**/*.{tsx,jsx,ts,js}
glob: pages/_app.{tsx,jsx,ts,js}
glob: pages/_document.{tsx,jsx,ts,js}
grep: "getStaticProps" in pages/**/*.{tsx,jsx,ts,js}
grep: "getServerSideProps" in pages/**/*.{tsx,jsx,ts,js}
```

Both routers can coexist. Check for both and report which is primary.

---

## App Router Patterns

### Metadata API

**Detection**: `grep "export.*metadata|generateMetadata" app/**/page.{tsx,jsx,ts,js} app/**/layout.{tsx,jsx,ts,js}`

**Correct — Static metadata**:
```tsx
// app/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Page Title',
  description: 'Page description for search engines',
  openGraph: {
    title: 'Page Title',
    description: 'Page description',
    images: ['/og-image.jpg'],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Page Title',
    description: 'Page description',
  },
  alternates: {
    canonical: 'https://example.com/page',
  },
};
```

**Correct — Dynamic metadata**:
```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from 'next';

export async function generateMetadata({ params }): Promise<Metadata> {
  const post = await getPost(params.slug);
  return {
    title: post.title,
    description: post.excerpt,
    openGraph: {
      title: post.title,
      description: post.excerpt,
      images: [post.image],
    },
  };
}
```

**Anti-patterns**:
- Using `<head>` directly in App Router pages instead of metadata API
- Using `next/head` in App Router (Pages Router only)
- Missing `generateMetadata` on dynamic routes
- Hardcoded metadata on pages that should be dynamic

**Detection for anti-pattern**: `grep "next/head" app/**/*.{tsx,jsx}`

### Server Components vs Client Components

**Detection**: `grep "'use client'" app/**/*.{tsx,jsx}`

**Rules**:
- Pages and layouts should be Server Components by default
- Only add `'use client'` for interactive components
- Keep data fetching in Server Components
- Metadata exports only work in Server Components

**Anti-patterns**:
- `'use client'` on page/layout files with metadata exports (metadata won't work)
- Entire page as Client Component when only a small section needs interactivity
- Data fetching with `useEffect` in Client Components that could be Server Components

**Detection**: `grep -l "'use client'" app/**/page.{tsx,jsx} app/**/layout.{tsx,jsx}`

### generateStaticParams

**Detection**: `grep "generateStaticParams" app/**/*.{tsx,jsx,ts,js}`

**Correct**:
```tsx
// app/blog/[slug]/page.tsx
export async function generateStaticParams() {
  const posts = await getAllPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

**Anti-patterns**:
- Dynamic routes without `generateStaticParams` (causes SSR on every request)
- Missing `dynamicParams = false` when all params are known at build time

### next/image

**Detection**: `grep "next/image|<img " app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

**Correct**:
```tsx
import Image from 'next/image';

// Above-the-fold: use priority
<Image src="/hero.webp" width={1200} height={600} alt="Descriptive alt text" priority />

// Below-the-fold: lazy loads by default
<Image src="/photo.webp" width={400} height={300} alt="Descriptive alt text" />

// Fill mode for responsive containers
<div style={{ position: 'relative', aspectRatio: '16/9' }}>
  <Image src="/photo.webp" fill alt="Descriptive alt text" sizes="(max-width: 768px) 100vw, 50vw" />
</div>
```

**Anti-patterns**:
- Using `<img>` tag directly instead of `next/image`
- Missing `alt` attribute or empty `alt=""` on meaningful images
- Missing `priority` on above-the-fold/hero images
- Missing `sizes` attribute when using `fill` or responsive layouts
- Using `unoptimized` prop without a CDN handling optimization

**Detection**: `grep "<img " app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

### next/link

**Detection**: `grep "<a href|next/link" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

**Correct**:
```tsx
import Link from 'next/link';
<Link href="/about">About Us</Link>
```

**Anti-patterns**:
- Using `<a>` tags for internal navigation instead of `next/link`
- Missing `href` on Link components
- Using `window.location` or `router.push` for navigation that should be a link (not crawlable)

**Detection**: `grep "<a href=\"/" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

### next/font

**Detection**: `grep "next/font" app/**/*.{tsx,jsx,ts,js}`

**Correct**:
```tsx
// app/layout.tsx
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'], display: 'swap' });

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={inter.className}>
      <body>{children}</body>
    </html>
  );
}
```

**Anti-patterns**:
- Loading fonts via `<link>` to Google Fonts (causes extra network requests)
- Loading fonts via CSS `@import` (render-blocking)
- Not specifying `display: 'swap'`
- Loading too many font weights/subsets

**Detection**: `grep "fonts.googleapis.com|fonts.gstatic.com" app/**/*.{tsx,jsx} public/**/*.html styles/**/*.css`

### next/script

**Detection**: `grep "next/script|<script" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

**Correct**:
```tsx
import Script from 'next/script';

// Analytics — load after page is interactive
<Script src="https://analytics.example.com/script.js" strategy="afterInteractive" />

// Non-critical — load when idle
<Script src="https://widget.example.com/embed.js" strategy="lazyOnload" />

// Critical inline script
<Script id="structured-data" type="application/ld+json" strategy="afterInteractive">
  {JSON.stringify(structuredData)}
</Script>
```

**Anti-patterns**:
- Using `<script>` tags directly (no optimization)
- Third-party scripts with `strategy="beforeInteractive"` that aren't truly critical
- Multiple analytics scripts without `strategy="lazyOnload"`

**Detection**: `grep "<script" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

### Route Configuration

**Detection**: `grep "export const dynamic|export const revalidate|export const runtime" app/**/*.{tsx,jsx,ts,js}`

**Key exports**:
```tsx
// Static by default — only add these when needed
export const dynamic = 'force-dynamic'; // Opt out of static rendering
export const revalidate = 3600; // ISR: revalidate every hour
export const dynamic = 'force-static'; // Force static even with dynamic functions
```

**Anti-patterns**:
- `dynamic = 'force-dynamic'` on pages that could be static
- No `revalidate` on content that changes periodically
- Using `dynamic = 'force-dynamic'` as a fix for build errors instead of fixing the root cause

### robots.ts and sitemap.ts

**Detection**: `glob app/robots.{ts,js} app/sitemap.{ts,js,xml}`

**Correct — robots.ts**:
```tsx
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: '*',
      allow: '/',
      disallow: ['/api/', '/admin/'],
    },
    sitemap: 'https://example.com/sitemap.xml',
  };
}
```

**Correct — sitemap.ts**:
```tsx
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getAllPosts();
  return [
    { url: 'https://example.com', lastModified: new Date(), changeFrequency: 'daily', priority: 1 },
    ...posts.map((post) => ({
      url: `https://example.com/blog/${post.slug}`,
      lastModified: post.updatedAt,
      changeFrequency: 'weekly' as const,
      priority: 0.8,
    })),
  ];
}
```

**Anti-patterns**:
- Static `public/robots.txt` instead of dynamic `app/robots.ts`
- No sitemap at all
- Sitemap missing dynamic pages

### OG Image Generation

**Detection**: `glob app/**/opengraph-image.{tsx,jsx,ts,js} app/**/twitter-image.{tsx,jsx,ts,js}`

**Correct**:
```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from 'next/og';

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function Image({ params }) {
  const post = await getPost(params.slug);
  return new ImageResponse(
    <div style={{ fontSize: 48, background: 'white', width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {post.title}
    </div>,
    { ...size }
  );
}
```

### Streaming and Suspense

**Detection**: `grep "Suspense|loading.tsx" app/**/*.{tsx,jsx}`

**Correct**:
```tsx
// app/page.tsx
import { Suspense } from 'react';

export default function Page() {
  return (
    <main>
      <h1>Page Title</h1> {/* Renders immediately — good for LCP */}
      <Suspense fallback={<ProductsSkeleton />}>
        <Products /> {/* Streams in when ready */}
      </Suspense>
    </main>
  );
}
```

**SEO benefit**: Above-the-fold content renders immediately, improving LCP while still allowing dynamic content below.

---

## Pages Router Patterns

### next/head

**Detection**: `grep "next/head" pages/**/*.{tsx,jsx}`

**Correct**:
```tsx
import Head from 'next/head';

export default function Page() {
  return (
    <>
      <Head>
        <title>Page Title</title>
        <meta name="description" content="Page description" />
        <meta property="og:title" content="Page Title" />
        <meta property="og:description" content="Page description" />
        <link rel="canonical" href="https://example.com/page" />
      </Head>
      <main>...</main>
    </>
  );
}
```

**Anti-patterns**:
- Missing `<Head>` component on pages
- Duplicate `<Head>` entries across components causing tag duplication
- Using `<head>` (lowercase) instead of `next/head`

### Data Fetching (Pages Router)

**Detection**: `grep "getStaticProps|getServerSideProps|getStaticPaths" pages/**/*.{tsx,jsx,ts,js}`

**Rules**:
- Use `getStaticProps` for pages that can be pre-rendered (blog posts, marketing pages)
- Use `getServerSideProps` only when data must be fresh on every request
- Use `getStaticPaths` with `getStaticProps` for dynamic routes
- Set `revalidate` in `getStaticProps` for ISR

**Anti-patterns**:
- Using `getServerSideProps` when `getStaticProps` with `revalidate` would suffice
- Missing `getStaticPaths` on dynamic routes with `getStaticProps`
- Client-side data fetching for content that should be SSR/SSG (harms SEO)
- `fallback: false` when new content is added regularly (should be `'blocking'`)

### _document.tsx

**Detection**: `glob pages/_document.{tsx,jsx,ts,js}`

**Correct**:
```tsx
// pages/_document.tsx
import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="en">
      <Head>
        {/* Global meta tags, fonts, favicons */}
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
```

**Anti-patterns**:
- Missing `lang` attribute on `<Html>`
- Page-specific meta tags in `_document` (should be in individual pages)
- Missing `_document.tsx` entirely (no `lang` attribute)

### _app.tsx

**Detection**: `glob pages/_app.{tsx,jsx,ts,js}`

**Anti-patterns**:
- Loading heavy libraries in `_app` that aren't needed on every page
- Font loading in `_app` without `next/font`
- Global state providers wrapping pages that don't need them (increases bundle for all pages)

---

## Common Anti-Patterns (Both Routers)

### Client-Side Only Rendering

**Detection**: `grep "useEffect.*fetch|useState.*null.*useEffect" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

**Problem**: Content invisible to search engine crawlers, poor LCP.

### Missing Semantic HTML

**Detection**: Check for heading hierarchy, landmark elements, structured content.

**Rules**:
- One `<h1>` per page
- No skipped heading levels (h1 → h3 without h2)
- Use `<main>`, `<nav>`, `<article>`, `<section>`, `<aside>`, `<footer>`
- Use `<button>` for actions, `<a>` for navigation

### Broken Internal Links

**Detection**: `grep "href=\"#\"|href=\"\"|href=\"javascript:" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}`

### Missing Error Pages

**Detection**:
```
# App Router
glob: app/not-found.{tsx,jsx}
glob: app/error.{tsx,jsx}

# Pages Router
glob: pages/404.{tsx,jsx}
glob: pages/500.{tsx,jsx}
```

### Console Errors During SSR

When analyzing code, flag patterns that would throw during SSR:
- Direct `window` or `document` access outside `useEffect`
- Browser-only APIs used in Server Components or during SSR

**Detection**: `grep "window\.|document\." app/**/page.{tsx,jsx} app/**/layout.{tsx,jsx} pages/**/*.{tsx,jsx}` (excluding files with `'use client'` at top)

---

## Performance Antipatterns

These are Next.js-specific performance antipatterns that hurt runtime performance, inflate bundles, or cause unnecessary re-renders. General CWV patterns are covered by `web-seo-performance`; these are framework-specific issues only.

### Excessive `'use client'` Boundaries (App Router)

**Detection**:
```
# Count total components in app/ and components/
glob: app/**/*.{tsx,jsx}
glob: components/**/*.{tsx,jsx}

# Count Client Components
grep: "'use client'" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- Calculate ratio: `clientComponents / totalComponents`
- \>60% client components = HIGH — most of the app opts out of Server Components, losing streaming, smaller bundles, and server-side data fetching
- 40-60% = MEDIUM — review whether some Client Components could be Server Components

**Correct** — push interactivity to leaf components:
```tsx
// app/page.tsx — Server Component (no directive)
import { ProductList } from '@/components/ProductList'; // Server Component
import { AddToCartButton } from '@/components/AddToCartButton'; // Client Component

export default async function Page() {
  const products = await getProducts(); // server-side fetch
  return (
    <main>
      <ProductList products={products} />
    </main>
  );
}
```

**Anti-pattern** — entire page as Client Component:
```tsx
// app/page.tsx
'use client'; // ❌ Makes entire page a Client Component
import { useState, useEffect } from 'react';

export default function Page() {
  const [products, setProducts] = useState([]);
  useEffect(() => { fetch('/api/products').then(…) }, []);
  return <main>{products.map(…)}</main>;
}
```

### Layout-Level Fetch Without Caching (App Router)

**Detection**:
```
grep: "fetch(" app/**/layout.{tsx,jsx,ts,js}
# Then check if matches contain next: { revalidate } or cache:
grep: "next:\s*\{.*revalidate|cache:" app/**/layout.{tsx,jsx,ts,js}
```

**Rules**:
- `fetch()` in layouts missing `next: { revalidate }` or `cache` option = HIGH — layouts run on every navigation, uncached fetches add latency to every page transition

**Correct**:
```tsx
// app/layout.tsx
async function getSettings() {
  const res = await fetch('https://api.example.com/settings', {
    next: { revalidate: 3600 }, // Cache for 1 hour
  });
  return res.json();
}
```

**Anti-pattern**:
```tsx
// app/layout.tsx
async function getSettings() {
  const res = await fetch('https://api.example.com/settings'); // ❌ No caching — re-fetches on every navigation
  return res.json();
}
```

### Barrel File Re-exports (App Router)

**Detection**:
```
# Find barrel files
grep: "export \* from|export \{.*\} from" **/index.{ts,tsx,js,jsx}

# Check if barrel files are imported in Server Components
grep: "from ['\"]\..*index['\"]|from ['\"]@/" app/**/*.{tsx,jsx,ts,js}
```

**Rules**:
- `export * from` in index files imported by Server Components = MEDIUM — barrel files defeat tree-shaking, pulling in unnecessary code and potentially pulling Client Components into Server Component bundles

**Correct** — direct imports:
```tsx
// app/page.tsx
import { Button } from '@/components/Button';
import { Card } from '@/components/Card';
```

**Anti-pattern** — barrel file re-export:
```tsx
// components/index.ts
export * from './Button';   // ❌ Pulls in ALL exports
export * from './Card';
export * from './HeavyChart'; // Even unused, this gets bundled

// app/page.tsx
import { Button } from '@/components'; // ❌ Triggers barrel file
```

### Client Component Wrapping Server Components (App Router)

**Detection**:
```
# Find Client Components that accept children
grep: "'use client'" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
# Then check if those files render {children}
grep: "\{children\}" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- `'use client'` wrapper that only provides context or event handlers around `{children}` = MEDIUM — forces all children to be Client Components unless explicitly separated. Consider extracting the interactive part.

**Correct** — separate interactive wrapper:
```tsx
// components/ThemeProvider.tsx
'use client';
import { createContext, useContext, useState } from 'react';

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setTheme] = useState('light');
  return <ThemeContext.Provider value={{ theme, setTheme }}>{children}</ThemeContext.Provider>;
}

// app/layout.tsx — Server Component
import { ThemeProvider } from '@/components/ThemeProvider';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html><body>
      <ThemeProvider>{children}</ThemeProvider> {/* children remain Server Components */}
    </body></html>
  );
}
```

**Anti-pattern** — unnecessary client boundary:
```tsx
// components/PageWrapper.tsx
'use client'; // ❌ Makes wrapper and potentially all children Client Components

export function PageWrapper({ children }: { children: React.ReactNode }) {
  return <div className="page-wrapper">{children}</div>; // No interactivity needed
}
```

### Heavy Imports in `_app.tsx` (Pages Router)

**Detection**:
```
# Check _app.tsx for heavy libraries at top level
grep: "moment|import.*lodash[^/]|@mui/material|antd|@chakra-ui" pages/_app.{tsx,jsx,ts,js}
```

**Rules**:
- Heavy libraries (`moment`, full `lodash`, `@mui/material`, `antd`) imported at the top level of `_app.tsx` = HIGH — these are included in EVERY page's bundle since `_app` wraps all pages

**Correct** — use lighter alternatives or dynamic imports:
```tsx
// pages/_app.tsx
import type { AppProps } from 'next/app';
// Only import what's truly needed on every page
import '@/styles/globals.css';

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
```

**Anti-pattern**:
```tsx
// pages/_app.tsx
import moment from 'moment'; // ❌ 300KB+ included on every page
import _ from 'lodash'; // ❌ 70KB+ included on every page
import { ThemeProvider } from '@mui/material'; // ❌ Pulls in entire MUI
```

### `getServerSideProps` Overuse (Pages Router)

**Detection**:
```
grep: "getServerSideProps" pages/**/*.{tsx,jsx,ts,js}
# Check if those pages have content that changes infrequently
```

**Rules**:
- `getServerSideProps` on pages with content that changes infrequently (blog posts, marketing pages, docs) = MEDIUM — use `getStaticProps` + `revalidate` (ISR) instead for faster TTFB

**Correct** — ISR for infrequently changing content:
```tsx
// pages/blog/[slug].tsx
export async function getStaticProps({ params }) {
  const post = await getPost(params.slug);
  return { props: { post }, revalidate: 60 }; // Regenerate every 60s
}

export async function getStaticPaths() {
  const posts = await getAllPosts();
  return {
    paths: posts.map((p) => ({ params: { slug: p.slug } })),
    fallback: 'blocking',
  };
}
```

**Anti-pattern**:
```tsx
// pages/blog/[slug].tsx
export async function getServerSideProps({ params }) { // ❌ SSR on every request
  const post = await getPost(params.slug);
  return { props: { post } };
}
```

### Excessive Dynamic Imports (Both Routers)

**Detection**:
```
grep: "dynamic\(|React\.lazy\(" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- \>10 `dynamic()` / `React.lazy()` calls project-wide = MEDIUM — excessive code splitting creates too many network requests, increasing load time instead of reducing it

### Dynamic Imports for Above-the-Fold Components (Both Routers)

**Detection**:
```
# Check if Hero, Header, Nav, Banner, or similar components use dynamic imports
grep: "dynamic\(.*Hero|dynamic\(.*Header|dynamic\(.*Nav|dynamic\(.*Banner|lazy\(.*Hero|lazy\(.*Header|lazy\(.*Nav" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- Above-the-fold components (Hero, Header, Nav, Banner) loaded via `dynamic()` or `React.lazy()` = HIGH — delays LCP since the component isn't in the initial bundle

**Correct**:
```tsx
// app/page.tsx
import { Hero } from '@/components/Hero'; // ✅ Static import for above-fold

export default function Page() {
  return <Hero />;
}
```

**Anti-pattern**:
```tsx
// app/page.tsx
import dynamic from 'next/dynamic';
const Hero = dynamic(() => import('@/components/Hero')); // ❌ Delays LCP

export default function Page() {
  return <Hero />;
}
```

### Too Many Nested Context Providers (Both Routers)

**Detection**:
```
# In App Router: check root layout
grep: "Provider" app/layout.{tsx,jsx}

# In Pages Router: check _app
grep: "Provider" pages/_app.{tsx,jsx,ts,js}
```

**Rules**:
- \>5 nested Context Providers in root layout or `_app` = HIGH — deep provider nesting causes cascading re-renders when any context value changes
- 3-5 providers = MEDIUM — consider consolidating or lazy-loading providers

**Correct** — consolidate providers:
```tsx
// app/providers.tsx
'use client';
export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <AuthProvider>
        {children}
      </AuthProvider>
    </ThemeProvider>
  );
}
```

**Anti-pattern**:
```tsx
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <ThemeProvider>
      <AuthProvider>
        <I18nProvider>
          <AnalyticsProvider>
            <FeatureFlagProvider>
              <ToastProvider> {/* ❌ 6+ nested providers */}
                {children}
              </ToastProvider>
            </FeatureFlagProvider>
          </AnalyticsProvider>
        </I18nProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
```

### Large Inline JSON in Pages (Both Routers)

**Detection**:
```
# Look for large object/array literals in page files
grep: "const .* = \[|const .* = \{" app/**/page.{tsx,jsx} pages/**/*.{tsx,jsx}
# Manual check: flag objects/arrays > ~50 lines or containing hardcoded data
```

**Rules**:
- Large data objects (>50 items or >50 lines) inlined in page components = MEDIUM — inflates the JavaScript bundle sent to the client. Move data to a separate file, API endpoint, or fetch at build time.

**Correct**:
```tsx
// data/countries.ts (separate file)
export const countries = [...]; // Data file, can be tree-shaken

// app/page.tsx
import { countries } from '@/data/countries';
```

**Anti-pattern**:
```tsx
// app/page.tsx
const countries = [ // ❌ 200+ items inline in the page component
  { code: 'US', name: 'United States' },
  { code: 'GB', name: 'United Kingdom' },
  // ... 200 more entries
];
```

### Missing React.memo on Context Consumers (Both Routers)

**Detection**:
```
# Find components using useContext
grep: "useContext" components/**/*.{tsx,jsx}
# Check if those components are wrapped in React.memo
grep: "React.memo|memo(" components/**/*.{tsx,jsx}
```

**Rules**:
- Expensive components (with heavy render logic or many children) that consume context via `useContext` without `React.memo` = LOW — they re-render on every context change even if the consumed value hasn't changed

### Importing Entire Icon Libraries (Both Routers)

**Detection**:
```
# Root imports from icon libraries
grep: "from 'react-icons'$|from \"react-icons\"$|from '@fortawesome/fontawesome'|from 'lucide-react'$|import \* as.*Icons" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
# Correct subpath imports
grep: "from 'react-icons/|from '@fortawesome/free-solid-svg-icons'|from 'lucide-react'" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- Root-level icon library imports instead of subpath imports = MEDIUM — pulls the entire icon library into the bundle instead of just the icons used

**Correct**:
```tsx
import { FaGithub } from 'react-icons/fa'; // ✅ Subpath import
import { ArrowRight } from 'lucide-react'; // ✅ Named export (tree-shakeable)
```

**Anti-pattern**:
```tsx
import * as Icons from 'react-icons'; // ❌ Entire library
import { icons } from 'lucide-react'; // ❌ All icons object
```
