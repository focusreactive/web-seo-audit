# Sample Audit Output

This is an example of what `web-seo-audit` produces when run against a Next.js 14 e-commerce project.

---

# Tech SEO Audit Report

**Project**: acme-store
**Framework**: Next.js 14.2.3
**Router**: App Router
**Date**: 2026-03-01

---

## SEO Health Score: 71/100 (C) — WARNING

| Category | Score | Status | Issues |
|----------|-------|--------|--------|
| Technical SEO | 77/100 | WARNING | 0C 1H 4M 3L |
| Performance | 65/100 | WARNING | 1C 1H 3M 2L |
| Next.js Patterns | 70/100 | WARNING | 1C 0H 5M 2L |
| Meta & Structured Data | 84/100 | PASS | 0C 2H 0M 0L |
| Image Optimization | 62/100 | WARNING | 0C 2H 4M 1L |
| AI Search Readiness | 55/100 | FAIL | 1C 1H 3M 2L |

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

- **Location**: `app/products/page.tsx:1`
- **Problem**: Product listing page uses `'use client'` and fetches all products via `useEffect`. Content is invisible to search engine crawlers on initial render.
- **Impact**: Product listing page (highest traffic page) is not indexable. Googlebot sees empty content.
- **Fix**: Convert to Server Component with async data fetching.

<details>
<summary>Code example</summary>

```tsx
// Before (problematic)
'use client';
export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  useEffect(() => {
    fetch('/api/products').then(r => r.json()).then(setProducts);
  }, []);
  return <ProductGrid products={products} />;
}

// After (fixed)
export default async function ProductsPage() {
  const products = await getProducts();
  return <ProductGrid products={products} />;
}
```

</details>

### [CRITICAL] Next.js Patterns: Client Component page with metadata export

- **Location**: `app/products/page.tsx:3`
- **Problem**: Page has `'use client'` directive AND exports `metadata`. In App Router, metadata exports are ignored in Client Components.
- **Impact**: Product listing page has no title tag, no meta description, no OG tags in the rendered HTML.
- **Fix**: Remove `'use client'` from the page (see fix above), or extract interactive parts into a child Client Component.

### [CRITICAL] AI Search Readiness: AI retrieval bots blocked in robots.txt

- **Location**: `public/robots.txt:1`
- **Problem**: robots.txt contains `User-agent: *` with `Disallow: /` and no specific `Allow` rules for AI retrieval bots. ChatGPT-User, PerplexityBot, and ClaudeBot are blocked from fetching content.
- **Impact**: Site content will not appear in AI search results (ChatGPT, Perplexity, Claude). AI-generated answers cannot cite this site.
- **Fix**: Add explicit Allow rules for AI retrieval bots above the blanket Disallow rule.

<details>
<summary>Code example</summary>

```
# Before (problematic)
User-agent: *
Disallow: /

# After (fixed) — add before the blanket rule
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

## High Priority Issues (6)

### [HIGH] Technical SEO: No sitemap.xml or robots.txt

- **Location**: site-wide
- **Problem**: No `app/sitemap.ts`, `public/sitemap.xml`, `app/robots.ts`, or `public/robots.txt` found.
- **Impact**: Search engines have no guidance on which pages to crawl or discover. All 47 routes must be found through link crawling.
- **Fix**: Add `app/sitemap.ts` and `app/robots.ts`.

### [HIGH] Performance: Hero image missing priority loading

- **Location**: `components/Hero.tsx:15`
- **Problem**: Hero image uses `next/image` but doesn't have the `priority` prop. It will be lazy-loaded by default, delaying LCP.
- **Impact**: LCP delayed by ~200-500ms as the hero image is deferred.
- **Fix**: Add `priority` prop to hero Image component.

### [HIGH] Image Optimization: 12 images missing width/height

- **Location**: `components/ProductCard.tsx:22`, `components/Banner.tsx:8`, +10 more
- **Problem**: Using `<img>` tags without `width` and `height` attributes. Browser cannot reserve space.
- **Impact**: CLS > 0.25 likely. Images shift content as they load.
- **Fix**: Add explicit `width` and `height` or use `next/image` with dimensions.

### [HIGH] Image Optimization: 8 raw `<img>` tags instead of next/image

- **Location**: `components/ProductCard.tsx:22`, `components/TeamSection.tsx:14`, +6 more
- **Problem**: Using native `<img>` instead of `next/image`. Missing automatic optimization, responsive sizing, and format conversion.
- **Impact**: Images served in original format (PNG/JPG) at full size. No WebP/AVIF, no responsive srcset.
- **Fix**: Replace `<img>` with `next/image` component.

### [HIGH] AI Search Readiness: No llms.txt file

- **Location**: site-wide
- **Problem**: No `llms.txt` file found at project root (`public/llms.txt`). AI systems have no structured way to discover site content, documentation, and key pages.
- **Impact**: AI search engines must rely solely on crawling to understand the site. A well-structured `llms.txt` directly tells AI systems what content is available and how the site is organized.
- **Fix**: Create `public/llms.txt` with site description and links to key content.

### [HIGH] Meta & Structured Data: Missing structured data on product pages

- **Location**: `app/products/[slug]/page.tsx`
- **Problem**: Product pages have no JSON-LD structured data. Missing Product schema with price, availability, and reviews.
- **Impact**: No rich results (price, stars, availability) in Google search results for products.
- **Fix**: Add Product schema JSON-LD.

---

## Medium Priority Issues (15)

- [MEDIUM] Meta: Title tags exceed 60 characters on 3 pages
- [MEDIUM] Meta: Missing Open Graph images on blog pages
- [MEDIUM] Meta: Meta descriptions below 70 characters on category pages
- [MEDIUM] Performance: `lodash` imported as full package (318KB)
- [MEDIUM] Performance: No `@next/bundle-analyzer` configured
- [MEDIUM] Performance: Google Fonts loaded via `<link>` instead of `next/font`
- [MEDIUM] Next.js: Missing `generateStaticParams` on `[slug]` routes
- [MEDIUM] Next.js: Using `<a>` tags for internal navigation (5 instances)
- [MEDIUM] Next.js: Raw `<script>` tags for analytics instead of `next/script`
- [MEDIUM] Next.js: No `loading.tsx` files for Suspense boundaries
- [MEDIUM] Next.js: Missing `sizes` prop on 3 fill-mode Images
- [MEDIUM] Images: Serving PNG images that should be WebP (public/team/*.png)
- [MEDIUM] AEO: Articles missing `dateModified` in JSON-LD structured data
- [MEDIUM] AEO: No `<main>` element — AI crawlers can't identify primary content area
- [MEDIUM] AEO: FAQ section on support page lacks FAQPage schema

## Low Priority Issues (10)

- [LOW] Technical: Missing `lang` attribute on `<html>` in root layout
- [LOW] Technical: Trailing slash inconsistency across internal links
- [LOW] Technical: Missing `rel="noopener"` on 2 external links
- [LOW] Performance: No Content-Security-Policy header configured
- [LOW] Performance: Missing `preconnect` hint for API domain
- [LOW] Next.js: No `opengraph-image.tsx` for dynamic OG generation
- [LOW] Next.js: No `not-found.tsx` custom error page
- [LOW] Images: Decorative images with non-empty alt text
- [LOW] AEO: No question-format headings on blog posts (missed AI query matching)
- [LOW] AEO: No dedicated author pages — weakens E-E-A-T signals for AI

---

## Summary & Recommendations

### Top 3 Priorities
1. **Fix product listing page rendering** — Convert from Client Component with `useEffect` to Server Component. This alone fixes 2 CRITICAL issues (indexability + metadata) and could improve the score by ~25 points.
2. **Add sitemap.ts and robots.ts** — Takes 10 minutes, improves crawlability for all 47 routes.
3. **Fix image dimensions and use next/image** — Addresses 20 image-related issues, dramatically reduces CLS risk.

### Quick Wins
- Add `priority` prop to hero image (1 line change, improves LCP)
- Switch from `lodash` to `lodash/get` imports (reduce bundle by ~300KB)
- Add `lang="en"` to root layout `<html>` tag

### Long-term Improvements
- Implement JSON-LD structured data across all page types (Product, Article, BreadcrumbList)
- Add `generateStaticParams` to all dynamic routes for SSG
- Set up `next/font` for font loading optimization
- Configure security headers in `next.config.js`
- Create `llms.txt` with structured site information for AI discovery
- Add entity-optimized properties (`sameAs`, `dateModified`, `mainEntityOfPage`) to all structured data
- Build dedicated author pages with Person schema for E-E-A-T signals
