# Sample Audit Output

> **Note**: This is a static example for illustration purposes. Dates, scores, and file paths are fictional.

This is an example of what `web-seo-audit` produces when run against a Next.js 14 e-commerce project.

---

# Tech SEO Audit Report

**Project**: acme-store
**Framework**: Next.js 14.2.3
**Router**: App Router
**Date**: 2025-01-15

---

## SEO Health Score: 72/100 (C) — WARNING

| Category | Score | Status | Issues |
|----------|-------|--------|--------|
| Technical SEO | 77/100 | WARNING | 0C 1H 4M 3L |
| Performance | 65/100 | WARNING | 1C 1H 3M 2L |
| Next.js Patterns | 70/100 | WARNING | 1C 0H 5M 2L |
| Meta & Structured Data | 84/100 | PASS | 0C 2H 0M 0L |
| Image Optimization | 62/100 | WARNING | 0C 2H 4M 1L |
| AI Search Readiness | 64/100 | WARNING | 1C 0H 4M 2L |

---

## Executive Summary

Your site has solid technical SEO foundations but two critical issues are suppressing rankings on your most important pages. The product listing page — your highest-traffic page — is invisible to search engines because it renders entirely via client-side JavaScript. Additionally, AI search engines (ChatGPT, Perplexity, Claude) cannot cite your content because retrieval bots are blocked in robots.txt.

**Estimated ranking impact**: These issues are likely suppressing rankings for product-related queries. Fixing the product listing page rendering and unblocking AI retrieval bots would have the highest impact on organic visibility.

---

## Core Web Vitals Risk Assessment

| Metric | Risk Level | Key Factors |
|--------|-----------|-------------|
| LCP | MEDIUM | Hero images missing `priority`, client-side data fetching on product pages |
| INP | LOW | Event handlers are lightweight, good use of `startTransition` |
| CLS | HIGH | 12 images missing dimensions, dynamic banner injection without reserved space |

---

## Critical Issues (3)

### [CRITICAL] Performance: SPA-style rendering on product listing page

- **ID**: `no-ssr:app/products/page.tsx:1`
- **Location**: `app/products/page.tsx:1`
- **Problem**: Product listing page uses `'use client'` and fetches all products via `useEffect`. Content is invisible to search engine crawlers on initial render.
- **Impact**: Product listing page (highest traffic page) is not indexable. Googlebot sees empty content.
- **Fix**: Convert to Server Component with async data fetching.
- **Fixability**: manual
- **Confidence**: HIGH

<details>
<summary>Code evidence</summary>

```tsx
// Before (actual code from project) — app/products/page.tsx:1-8
'use client';
import { useState, useEffect } from 'react';
import { ProductGrid } from '@/components/ProductGrid';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  useEffect(() => {
    fetch('/api/products').then(r => r.json()).then(setProducts);
  }, []);
  return <ProductGrid products={products} />;
}

// After (fixed)
import { ProductGrid } from '@/components/ProductGrid';
import { getProducts } from '@/lib/products';

export default async function ProductsPage() {
  const products = await getProducts();
  return <ProductGrid products={products} />;
}
```

</details>

### [CRITICAL] Next.js Patterns: Client Component page with metadata export

- **ID**: `client-metadata:app/products/page.tsx:3`
- **Location**: `app/products/page.tsx:3`
- **Problem**: Page has `'use client'` directive AND exports `metadata`. In App Router, metadata exports are ignored in Client Components.
- **Impact**: Product listing page has no title tag, no meta description, no OG tags in the rendered HTML.
- **Fix**: Remove `'use client'` from the page (see fix above), or extract interactive parts into a child Client Component.
- **Fixability**: manual
- **Confidence**: HIGH

### [CRITICAL] AI Search Readiness: AI retrieval bots blocked in robots.txt

- **ID**: `blocked-ai-bot:public/robots.txt:1`
- **Location**: `public/robots.txt:1`
- **Problem**: robots.txt contains `User-agent: *` with `Disallow: /` and no specific `Allow` rules for AI retrieval bots. ChatGPT-User, PerplexityBot, and ClaudeBot are blocked from fetching content.
- **Impact**: Site content will not appear in AI search results (ChatGPT, Perplexity, Claude). AI-generated answers cannot cite this site.
- **Fix**: Add explicit Allow rules for AI retrieval bots above the blanket Disallow rule.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

<details>
<summary>Code evidence</summary>

```
// Before (actual code from project) — public/robots.txt:1-2
User-agent: *
Disallow: /

// After (fixed)
User-agent: ChatGPT-User
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: Applebot-Extended
Allow: /

User-agent: *
Disallow: /private/
Sitemap: https://acme-store.com/sitemap.xml
```

</details>

---

## High Priority Issues (5)

### [HIGH] Technical SEO: No sitemap.xml or robots.txt

- **ID**: `missing-sitemap:site-wide`
- **Location**: site-wide
- **Problem**: No `app/sitemap.ts`, `public/sitemap.xml`, `app/robots.ts`, or `public/robots.txt` found.
- **Impact**: Search engines have no guidance on which pages to crawl or discover. All 47 routes must be found through link crawling.
- **Fix**: Add `app/sitemap.ts` and `app/robots.ts`.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

### [HIGH] Performance: Hero image missing priority loading

- **ID**: `img-priority:components/Hero.tsx:15`
- **Location**: `components/Hero.tsx:15`
- **Problem**: Hero image uses `next/image` but doesn't have the `priority` prop. It will be lazy-loaded by default, increasing LCP risk.
- **Impact**: LCP risk increased as the hero image is deferred until after JavaScript hydration.
- **Fix**: Add `priority` prop to hero Image component.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

### [HIGH] Image Optimization: 12 images missing width/height

- **ID**: `img-dimensions:components/ProductCard.tsx:22`
- **Location**: `components/ProductCard.tsx:22`, `components/Banner.tsx:8`, +10 more
- **Problem**: Using `<img>` tags without `width` and `height` attributes. Browser cannot reserve space.
- **Impact**: CLS > 0.25 likely. Images shift content as they load.
- **Fix**: Add explicit `width` and `height` or use `next/image` with dimensions.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

### [HIGH] Image Optimization: 8 raw `<img>` tags instead of next/image

- **ID**: `raw-img:components/ProductCard.tsx:22`
- **Location**: `components/ProductCard.tsx:22`, `components/TeamSection.tsx:14`, +6 more
- **Problem**: Using native `<img>` instead of `next/image`. Missing automatic optimization, responsive sizing, and format conversion.
- **Impact**: Images served in original format (PNG/JPG) at full size. No WebP/AVIF, no responsive srcset.
- **Fix**: Replace `<img>` with `next/image` component.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

### [MEDIUM] AI Search Readiness: No llms.txt file

- **ID**: `missing-llms-txt:site-wide`
- **Location**: site-wide
- **Problem**: No `llms.txt` file found at project root (`public/llms.txt`). AI systems have no structured way to discover site content, documentation, and key pages.
- **Impact**: AI search engines must rely solely on crawling to understand the site. A well-structured `llms.txt` directly tells AI systems what content is available (emerging best practice).
- **Fix**: Create `public/llms.txt` with site description and links to key content.
- **Fixability**: confirm-fix
- **Effort**: small
- **Confidence**: HIGH

### [HIGH] Meta & Structured Data: Missing structured data on product pages

- **ID**: `missing-schema:app/products/[slug]/page.tsx:1`
- **Location**: `app/products/[slug]/page.tsx`
- **Problem**: Product pages have no JSON-LD structured data. Missing Product schema with price, availability, and reviews. Verified: no `JsonLd`, `Schema`, or `application/ld+json` in the page file or its imports.
- **Impact**: No rich results (price, stars, availability) in Google search results for products.
- **Fix**: Add Product schema JSON-LD.
- **Fixability**: confirm-fix
- **Confidence**: HIGH

---

## Medium Priority Issues (16)

### [MEDIUM] Meta: Title tags exceed 60 characters on 3 pages

- **ID**: `title-length:app/products/[slug]/page.tsx:8`
- **Location**: `app/products/[slug]/page.tsx:8`, `app/blog/[slug]/page.tsx:12`, `app/about/page.tsx:5`
- **Problem**: Title tags exceed 60 characters — Google truncates longer titles in search results.
- **Impact**: Truncated titles reduce click-through rates and may obscure key information.
- **Fix**: Shorten titles to ≤60 characters while keeping primary keywords.
- **Fixability**: manual
- **Effort**: small
- **Confidence**: HIGH

### [MEDIUM] Performance: `lodash` imported as full package

- **ID**: `heavy-import:components/utils.tsx:1`
- **Location**: `components/utils.tsx:1`, `components/DataTable.tsx:3`
- **Problem**: Full `lodash` package imported (`import _ from 'lodash'`) instead of individual functions. Pulls entire library into the bundle.
- **Impact**: Adds unnecessary weight to the JavaScript bundle, increasing LCP risk.
- **Fix**: Replace with individual imports (`import get from 'lodash/get'`) or use `lodash-es` for tree-shaking.
- **Fixability**: confirm-fix
- **Effort**: medium
- **Confidence**: HIGH

<details>
<summary>Code evidence</summary>

```tsx
// Before (actual code from project) — components/utils.tsx:1
import _ from 'lodash';

export const deepGet = (obj, path) => _.get(obj, path);

// After (fixed)
import get from 'lodash/get';

export const deepGet = (obj, path) => get(obj, path);
```

</details>

### [MEDIUM] Next.js: Using `<a>` tags for internal navigation (5 instances)

- **ID**: `raw-anchor:components/Footer.tsx:22`
- **Location**: `components/Footer.tsx:22`, `components/Sidebar.tsx:15`, `components/Breadcrumb.tsx:8`, +2 more
- **Problem**: Using native `<a href="/...">` for internal links instead of `next/link`. Missing client-side navigation, prefetching, and route optimization.
- **Impact**: Each internal `<a>` click causes a full page reload instead of a client-side transition, hurting performance and UX.
- **Fix**: Replace `<a href="/path">` with `<Link href="/path">` from `next/link`.
- **Fixability**: confirm-fix
- **Effort**: small
- **Confidence**: HIGH

*+ 12 additional MEDIUM issues (see full format in collapsible section below)*

<details>
<summary>Remaining MEDIUM issues</summary>

- **`og-image:app/blog/[slug]/page.tsx:14`** — Missing Open Graph images on blog pages. Effort: small
- **`meta-desc-short:app/categories/[slug]/page.tsx:6`** — Meta descriptions below 70 characters on category pages. Effort: small
- **`bundle-analyzer:site-wide`** — No `@next/bundle-analyzer` configured. Effort: small
- **`font-loading:app/layout.tsx:3`** — Google Fonts loaded via `<link>` instead of `next/font`. Effort: medium
- **`static-params:app/blog/[slug]/page.tsx:1`** — Missing `generateStaticParams` on `[slug]` routes. Effort: medium
- **`raw-script:app/layout.tsx:28`** — Raw `<script>` tags for analytics instead of `next/script`. Effort: small
- **`missing-loading:app/products/page.tsx:1`** — No `loading.tsx` files for Suspense boundaries. Effort: small
- **`img-sizes:components/ProductCard.tsx:18`** — Missing `sizes` prop on 3 fill-mode Images. Effort: trivial
- **`img-format:public/team/`** — Serving PNG images that should be WebP (6 files in `public/team/`). Effort: medium
- **`missing-datemod:components/ArticleSchema.tsx:12`** — Articles missing `dateModified` in JSON-LD structured data. Effort: small
- **`missing-main:app/layout.tsx:15`** — No `<main>` element in root layout — AI crawlers can't identify primary content area. Effort: trivial
- **`missing-faq-schema:app/support/page.tsx:1`** — FAQ section on support page lacks FAQPage schema. Effort: medium

</details>

## Low Priority Issues (10)

### [LOW] Technical: Missing `lang` attribute on `<html>` in root layout

- **ID**: `missing-lang:app/layout.tsx:8`
- **Location**: `app/layout.tsx:8`
- **Problem**: `<html>` element is missing the `lang` attribute. Search engines and screen readers use this to identify the page language.
- **Fix**: Add `lang="en"` to the `<html>` tag.
- **Fixability**: auto-fix
- **Effort**: trivial
- **Confidence**: HIGH

*+ 9 additional LOW issues:*

- **`trailing-slash:site-wide`** — Trailing slash inconsistency across internal links. Effort: small
- **`rel-noopener:components/Footer.tsx:34`** — Missing `rel="noopener"` on 2 external links. Effort: trivial
- **`missing-csp:site-wide`** — No Content-Security-Policy header configured. Effort: medium
- **`missing-preconnect:app/layout.tsx:1`** — Missing `preconnect` hint for API domain. Effort: trivial
- **`missing-og-gen:app/blog/[slug]/`** — No `opengraph-image.tsx` for dynamic OG generation. Effort: medium
- **`missing-not-found:app/`** — No `not-found.tsx` custom error page. Effort: small
- **`decorative-alt:components/Divider.tsx:5`** — Decorative images with non-empty alt text. Effort: trivial
- **`no-question-headings:app/blog/`** — No question-format headings on blog posts. Effort: small
- **`no-author-pages:site-wide`** — No dedicated author pages — weakens E-E-A-T signals for AI. Effort: large

---

## Summary & Recommendations

### Top 3 Priorities (in order)
1. **Fix product listing page rendering** — Convert from Client Component with `useEffect` to Server Component. This alone fixes 2 CRITICAL issues (indexability + metadata) and could improve the score by ~25 points.
   - **Unblocks**: Metadata export fix (metadata only works in Server Components), structured data addition
   - **Effort**: large
2. **Fix robots.txt and add sitemap.ts** — Unblock AI retrieval bots and improve crawlability for all 47 routes.
   - **Effort**: small
3. **Fix image dimensions and use next/image** — Addresses 20 image-related issues, dramatically reduces CLS risk.
   - **Effort**: medium

### Fix Dependencies
- Fix product page rendering (CRITICAL) → enables metadata export fix (CRITICAL) → enables structured data addition (HIGH)

### Quick Wins
- Add `priority` prop to hero image (trivial — 1 line change, improves LCP)
- Add `lang="en"` to root layout `<html>` tag (trivial)
- Create `llms.txt` with site info (small — improves AI discovery)

### Long-term Improvements
- Implement JSON-LD structured data across all page types (Product, Article, BreadcrumbList)
- Add `generateStaticParams` to all dynamic routes for SSG
- Set up `next/font` for font loading optimization
- Configure security headers in `next.config.js`
- Add entity-optimized properties (`sameAs`, `dateModified`, `mainEntityOfPage`) to all structured data
- Build dedicated author pages with Person schema for E-E-A-T signals

---

## Audit Summary (JSON)

```json
{
  "score": 72,
  "grade": "C",
  "status": "WARNING",
  "date": "2025-01-15",
  "framework": "next",
  "frameworkVersion": "14.2",
  "categories": {
    "technical-seo": { "score": 77, "status": "WARNING", "issues": { "critical": 0, "high": 1, "medium": 4, "low": 3 } },
    "performance": { "score": 65, "status": "WARNING", "issues": { "critical": 1, "high": 1, "medium": 3, "low": 2 } },
    "framework-patterns": { "score": 70, "status": "WARNING", "issues": { "critical": 1, "high": 0, "medium": 5, "low": 2 } },
    "meta-structured-data": { "score": 84, "status": "PASS", "issues": { "critical": 0, "high": 2, "medium": 0, "low": 0 } },
    "image-optimization": { "score": 62, "status": "WARNING", "issues": { "critical": 0, "high": 2, "medium": 4, "low": 1 } },
    "ai-search-readiness": { "score": 64, "status": "WARNING", "issues": { "critical": 1, "high": 0, "medium": 4, "low": 2 } }
  },
  "cwvRisk": { "lcp": "MEDIUM", "inp": "LOW", "cls": "HIGH" },
  "issueCount": { "critical": 3, "high": 6, "medium": 20, "low": 10, "total": 39 }
}
```
