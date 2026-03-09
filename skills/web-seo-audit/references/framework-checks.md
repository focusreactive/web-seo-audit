# Framework Check Registry

This reference defines which checks each agent should run based on the detected framework and version. The orchestrator uses this to build framework-conditional agent prompts — agents only receive checks relevant to the target project.

## How to Use This Registry

1. Detect framework and version (see SKILL.md Framework Detection Protocol)
2. Look up the framework in the tables below
3. For each agent, collect: **universal checks** + **framework-specific checks** (filtered by version)
4. Pass only the collected checks to the agent prompt

## Agent: web-seo-technical

### Universal Checks (all frameworks)

| Check | Priority | Description |
|-------|----------|-------------|
| robots.txt exists | HIGH | Site must have robots.txt |
| sitemap exists | HIGH | Site must have sitemap.xml or dynamic sitemap |
| canonical URLs | CRITICAL | Pages must have canonical URLs |
| title tags | HIGH | Every page must have a unique `<title>` |
| meta descriptions | HIGH | Every page must have a meta description |
| Open Graph tags | MEDIUM | Pages should have OG title, description, image |
| Twitter Card tags | MEDIUM | Pages should have twitter:card meta tags |
| HTTPS / mixed content | CRITICAL | No mixed content, enforce HTTPS |
| heading hierarchy | MEDIUM | No skipped heading levels, one H1 per page |
| `lang` attribute | LOW | `<html>` must have `lang` attribute |
| internal link quality | MEDIUM | No `href="#"`, `href=""`, or `javascript:` links |
| redirect chains | HIGH/MEDIUM | Flag chains > 2 hops, loops are CRITICAL |
| URL structure | MEDIUM | Route depth, URL length, trailing slash consistency |
| 404 error page | MEDIUM | 404 page should exist in source |
| 500 error page | LOW | For SSGs/static sites, 500 is handled by hosting platform — only flag as MEDIUM for server-rendered frameworks (Next.js, Nuxt, Express) |
| E-E-A-T signals | HIGH/MEDIUM | About page, author info, contact/privacy pages |
| JSON-LD structured data | HIGH | Content pages should have structured data |
| JSON-LD validation | MEDIUM | Check @context, absolute URLs, required properties |
| pagination markup | MEDIUM | `rel="next/prev"` on paginated content |
| hreflang / i18n | HIGH/MEDIUM | Validate hreflang bidirectional return links, self-references, x-default, language code format, URL consistency, and completeness across pages |
| keyword cannibalization | MEDIUM | Flag pages targeting same primary keyword in title + H1 |
| orphaned pages | HIGH | Pages with no incoming internal links from any other page |
| internal link graph | MEDIUM | Key pages with few outlinks, deep-only pages |

### Framework-Specific Checks

#### Next.js

| Check | Version | Router | Priority | Description |
|-------|---------|--------|----------|-------------|
| Metadata API usage | 13.2+ | App | HIGH | Pages should use `export const metadata` or `generateMetadata` |
| `next/head` usage | any | Pages | HIGH | Pages should use `<Head>` from `next/head` |
| No `next/head` in App Router | 13+ | App | HIGH | App Router must NOT use `next/head` |
| `robots.ts` typed route | 13+ | App | MEDIUM | Prefer `app/robots.ts` over `public/robots.txt` |
| `sitemap.ts` typed route | 13+ | App | MEDIUM | Prefer `app/sitemap.ts` over static sitemap |
| `_document.tsx` has `lang` | any | Pages | LOW | `<Html lang="en">` in `_document.tsx` |

#### Nuxt

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `useHead()` usage | 3+ | HIGH | Pages should use `useHead()` or `useSeoMeta()` composables |
| `nuxt.config.ts` app.head | 3+ | MEDIUM | Global head config should be set |
| `<NuxtLink>` usage | 3+ | MEDIUM | Internal links should use `<NuxtLink>` not `<a>` |
| `definePageMeta` for titles | 3+ | MEDIUM | Dynamic pages should use `definePageMeta` |
| Nuxt 2 `head()` method | 2.x | HIGH | Pages should use `head()` method in component options |

#### Gatsby

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `gatsby-plugin-react-helmet` | any | HIGH | Must use Helmet for meta tags |
| `gatsby-plugin-sitemap` | any | HIGH | Must have sitemap plugin |
| `gatsby-plugin-canonical-urls` | any | MEDIUM | Should have canonical URL plugin |
| GraphQL SEO data | any | MEDIUM | Pages should query SEO fields via GraphQL |

#### Astro

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `<head>` in layouts | any | HIGH | Astro layouts must include `<head>` with meta tags |
| `Astro.props` for meta | any | MEDIUM | Pages should pass title/description via props |
| `@astrojs/sitemap` | any | HIGH | Must have sitemap integration |
| Frontmatter meta fields | any | MEDIUM | Content pages should have title, description in frontmatter |
| ViewTransitions API | 3+ | LOW | Check for proper view transition handling |

#### Eleventy (11ty)

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| Meta tags in layouts | any | HIGH | Layout templates (`.njk`, `.liquid`, `.html`) must include `<title>` and `<meta name="description">` in `<head>` |
| Canonical URLs | any | CRITICAL | Layouts must include `<link rel="canonical">` |
| Nunjucks/Liquid template patterns | any | MEDIUM | Check for proper variable usage in meta tags (`{{ title }}`, `{{ description }}`) with fallbacks |
| Permalink configuration | any | MEDIUM | Check `.eleventy.js` or `eleventy.config.js` for permalink patterns and trailing slash consistency |
| Passthrough copy for static assets | any | LOW | Verify `addPassthroughCopy` for images, fonts, and static files |
| Collection-based sitemap | any | HIGH | Site should generate sitemap from collections |
| Pagination templates | any | MEDIUM | Paginated content should have `rel="next/prev"` |
| Data cascade for SEO fields | any | MEDIUM | Global data files (`_data/`) should provide SEO defaults (site name, base URL) |

**Template file patterns for Eleventy** (agents must search these in addition to standard patterns):
- Layouts: `src/_layouts/**/*.njk`, `src/_includes/**/*.njk`, `_includes/**/*.njk`, `_layouts/**/*.njk`
- Pages: `src/**/*.njk`, `src/**/*.md`, `src/**/*.html`
- Data: `src/_data/**/*.{js,json}`, `_data/**/*.{js,json}`
- Config: `.eleventy.js`, `eleventy.config.{js,mjs,cjs}`

#### Remix

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `meta()` export | 2+ | HIGH | Routes should export `meta()` function for title/description |
| `loader` for data | any | HIGH | Pages should use `loader` for server-side data, not client-side fetch |
| `<Link>` usage | any | MEDIUM | Internal links should use Remix `<Link>` not `<a>` |
| `links()` for assets | any | MEDIUM | Use `links()` export for preloading critical assets |
| Error boundaries | any | MEDIUM | Routes should have `ErrorBoundary` exports |

#### SvelteKit

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `+page.server.ts` data | any | HIGH | Pages should use server load functions for SEO-critical data |
| `<svelte:head>` | any | HIGH | Pages must use `<svelte:head>` for meta tags |
| Prerendering | any | MEDIUM | Static-eligible pages should have `export const prerender = true` |
| `<a>` with `data-sveltekit-preload-data` | any | LOW | Internal links benefit from preloading hints |

#### Qwik

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `routeLoader$` usage | any | HIGH | Pages should use `routeLoader$` for server data |
| `<head>` in layout | any | HIGH | Layout must include proper `<head>` with meta tags |
| `useDocumentHead` | any | MEDIUM | Dynamic pages should set head via `useDocumentHead` |

#### SPA Frameworks (React, Vue, Angular, Svelte)

| Check | Framework | Priority | Description |
|-------|-----------|----------|-------------|
| SSR/SSG availability | all | CRITICAL | SPAs without SSR have no indexable content |
| `react-helmet` / `react-helmet-async` | React | HIGH | Must manage meta tags dynamically |
| `vue-meta` / `@unhead/vue` | Vue | HIGH | Must manage meta tags dynamically |
| `@angular/platform-server` | Angular | CRITICAL | Must have SSR setup for SEO |
| `svelte:head` | Svelte | HIGH | Must use `<svelte:head>` for meta tags |
| Hash routing detection | all | HIGH | `/#/` routing is not crawlable |
| `react-router` SSR | React | MEDIUM | Check for server-side rendering support |
| Prerendering setup | all | HIGH | At minimum prerender key pages for SEO |

#### Static HTML

| Check | Priority | Description |
|-------|----------|-------------|
| Meta tags in `<head>` | HIGH | Every HTML file must have title and meta description |
| Sitemap.xml file | HIGH | Must have a static sitemap |
| Robots.txt file | HIGH | Must have robots.txt |
| All checks are HTML-native | — | No framework-specific patterns apply |

---

## Agent: web-seo-performance

### Universal Checks (all frameworks)

| Check | Priority | Description |
|-------|----------|-------------|
| Image format (WebP/AVIF) | MEDIUM | Images should use modern formats |
| Image dimensions | HIGH | `<img>` must have `width`/`height` or CSS `aspect-ratio` |
| Image lazy loading | MEDIUM | Below-fold images should use `loading="lazy"` |
| Image alt attributes | HIGH | Meaningful images must have `alt` text |
| Responsive images | MEDIUM | Images should use `srcset`/`sizes` |
| Above-fold image priority | HIGH | Hero/LCP images should have `fetchpriority="high"` |
| Font loading strategy | MEDIUM | `font-display: swap`, preload critical fonts |
| Render-blocking resources | HIGH | Non-critical CSS/JS should not block render |
| Third-party script loading | MEDIUM | Analytics/widgets should load deferred |
| Client-side rendering | CRITICAL | Main content must not depend on client-side JS fetch |
| Bundle size indicators | HIGH | Check for heavy imports, no tree-shaking |
| Skeleton/loading states | MEDIUM | Async content should show placeholders |
| CSS animation safety | MEDIUM | Use `transform`/`opacity`, not layout properties |

### Framework-Specific Checks

#### Next.js

| Check | Version | Router | Priority | Description |
|-------|---------|--------|----------|-------------|
| `next/image` usage | any | both | HIGH | Use `<Image>` not `<img>` |
| `next/image` `priority` prop | any | both | HIGH | Hero images must have `priority` |
| `next/image` `sizes` prop | any | both | MEDIUM | `fill` images must have `sizes` |
| `next/image` `unoptimized` | any | both | MEDIUM | Flag `unoptimized` without external CDN |
| `next/font` usage | 13+ | both | MEDIUM | Use `next/font` not Google Fonts CDN links |
| `next/script` strategy | any | both | MEDIUM | Scripts should use appropriate strategy |
| Server Components default | 13+ | App | HIGH | Pages should be Server Components |
| Excessive `'use client'` | 13+ | App | HIGH/MEDIUM | >60% client = HIGH, 40-60% = MEDIUM |
| Layout fetch caching | 13+ | App | HIGH | `fetch()` in layouts needs `next: { revalidate }` |
| Barrel file re-exports | 13+ | App | MEDIUM | Index barrel files defeat tree-shaking |
| Client wrapper pattern | 13+ | App | MEDIUM | Unnecessary `'use client'` wrappers |
| Dynamic import misuse | any | both | HIGH | Above-fold components must not be dynamically imported |
| Excessive dynamic imports | any | both | MEDIUM | >10 dynamic imports project-wide |
| Nested Context Providers | any | both | HIGH/MEDIUM | >5 = HIGH, 3-5 = MEDIUM |
| Heavy `_app.tsx` imports | any | Pages | HIGH | moment, lodash, MUI in `_app` |
| `getServerSideProps` overuse | any | Pages | MEDIUM | Use ISR when content is semi-static |
| Large inline JSON | any | both | MEDIUM | >50-line data objects in page components |
| Icon library root imports | any | both | MEDIUM | Must use subpath imports |
| Streaming / Suspense | 13+ | App | MEDIUM | Use `<Suspense>` for below-fold async content |
| `generateStaticParams` | 13+ | App | MEDIUM | Dynamic routes should have static params |
| Fetch cache defaults | 15+ | App | MEDIUM | v15 defaults to `no-store`, check explicit caching |
| Partial Prerendering | 14+ | App | LOW | Awareness of PPR for mixed static/dynamic |
| `React.memo` on context consumers | any | both | LOW | Expensive context consumers should memoize |

#### Nuxt

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `nuxt/image` usage | 3+ | HIGH | Use `<NuxtImg>` / `<NuxtPicture>` not raw `<img>` |
| Auto-imports tree-shaking | 3+ | MEDIUM | Check for bloated auto-imports |
| `useLazyFetch` pattern | 3+ | MEDIUM | Below-fold data should use lazy fetching |
| Nitro prerendering | 3+ | MEDIUM | Static-eligible routes should be prerendered |
| Component lazy loading | 3+ | MEDIUM | Use `<LazyComponent>` prefix for below-fold |

#### Gatsby

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `gatsby-plugin-image` | 3+ | HIGH | Use `<GatsbyImage>` / `<StaticImage>` |
| GraphQL image queries | any | MEDIUM | Images should use `gatsbyImageData` |
| `gatsby-plugin-sharp` | any | MEDIUM | Must have image processing plugin |
| Bundle analysis | any | MEDIUM | Check for heavy page-specific bundles |

#### Astro

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| `<Image>` component | 3+ | HIGH | Use Astro's `<Image>` for optimization |
| Island architecture | any | HIGH | Interactive components should be islands (`client:*`) |
| `client:visible` for below-fold | any | MEDIUM | Below-fold islands should use `client:visible` |
| `client:idle` for non-critical | any | MEDIUM | Non-critical interactivity should use `client:idle` |
| Content Collections images | 3+ | MEDIUM | Content collection images should use image() schema |

#### Eleventy (11ty)

| Check | Version | Priority | Description |
|-------|---------|----------|-------------|
| Image shortcodes / transforms | any | MEDIUM | Check for `@11ty/eleventy-img` plugin or image optimization shortcodes |
| Image dimensions in templates | any | HIGH | `<img>` tags in `.njk`/`.liquid` templates must have `width`/`height` |
| Image alt in templates | any | HIGH | `<img>` tags must have `alt` attributes |
| Inline JS/CSS in templates | any | MEDIUM | Check for large inline `<script>` or `<style>` blocks in layout heads |
| Third-party script loading | any | MEDIUM | External scripts should use `defer` or `async` |
| Font loading in layouts | any | MEDIUM | Check for `font-display: swap` and font preloading |
| Static asset formats | any | MEDIUM | Check `public/` or passthrough directories for non-WebP/AVIF images |

#### SPA Frameworks (React, Vue, Angular, Svelte)

| Check | Framework | Priority | Description |
|-------|-----------|----------|-------------|
| Code splitting setup | all | HIGH | Must have route-based code splitting |
| Image optimization library | all | MEDIUM | Should use an image optimization approach |
| SSR hydration mismatch | all | MEDIUM | Check for common hydration issues |
| Bundle analyzer evidence | all | LOW | Project should have bundle analysis tooling |

---

## Agent: web-seo-aeo

### Universal Checks (all frameworks)

All AEO checks are universal — they apply regardless of framework. The framework context only affects WHERE to look for patterns (file paths, component structure).

| Check | Priority | Description |
|-------|----------|-------------|
| `llms.txt` exists | MEDIUM | Should have `/llms.txt` for AI discovery (emerging best practice) |
| `llms.txt` format validation | MEDIUM | Must follow spec (H1, blockquote, markdown links) |
| `llms-full.txt` exists | LOW | Extended version for comprehensive AI context |
| AI retrieval bot rules | CRITICAL | ChatGPT-User, PerplexityBot, ClaudeBot must not be blocked |
| AI training bot management | LOW | GPTBot, Google-Extended, CCBot, Bytespider — note but don't penalize |
| Organization `sameAs` | MEDIUM | Organization schema should have `sameAs` for entity verification |
| Article `dateModified` | MEDIUM | Articles should have `dateModified` for freshness signals |
| Entity `@id` | LOW | Primary entities benefit from stable `@id` |
| `mainEntityOfPage` | LOW | Content pages benefit from declaring main entity |
| `speakable` markup | LOW | Content suitable for voice answers |
| FAQPage schema | LOW | Q&A content benefits from FAQPage schema |
| HowTo schema | LOW | Tutorial content benefits from HowTo schema |
| `<main>` landmark | MEDIUM | Pages must have `<main>` for content identification |
| `<article>` wrapper | LOW | Content pages benefit from `<article>` wrapper |
| Question-format headings | LOW | Content pages benefit from question headings |
| Content behind JS interactions | MEDIUM | FAQ/content in tabs/accordions must be in initial DOM |
| Author pages | LOW | Sites with articles should have dedicated author pages |
| SSR cross-reference | — | Note AI impact of client-only rendering (don't score, reference Performance) |

### Framework-Specific File Paths

The AEO agent needs to know WHERE to look for patterns based on framework:

| Framework | robots.txt location | llms.txt location | Structured data location |
|-----------|-------------------|------------------|------------------------|
| Next.js (App) | `app/robots.ts` or `public/robots.txt` | `public/llms.txt` or `app/llms.txt/route.ts` | Page components, JSON-LD in Server Components |
| Next.js (Pages) | `public/robots.txt` | `public/llms.txt` or `pages/api/llms.ts` | Page components with `next/head` |
| Nuxt | `public/robots.txt` or `server/routes/robots.txt.ts` | `public/llms.txt` or `server/routes/llms.txt.ts` | `useHead()` or `useSchemaOrg()` |
| Gatsby | `static/robots.txt` or via plugin | `static/llms.txt` | `gatsby-plugin-react-helmet` or `<Helmet>` |
| Astro | `public/robots.txt` or `src/pages/robots.txt.ts` | `public/llms.txt` or `src/pages/llms.txt.ts` | `<script type="application/ld+json">` in layouts/pages |
| Eleventy | `src/robots.txt` or root `robots.txt` (passthrough) | `src/llms.txt` or root `llms.txt` | `<script type="application/ld+json">` in layouts/includes, JS data files |
| SPA / Static | `public/robots.txt` | `public/llms.txt` | `<script type="application/ld+json">` in HTML |

---

## Agent: web-seo-framework (replaces web-seo-nextjs)

This agent is spawned ONLY when a recognized framework is detected. It runs deep framework-specific checks that go beyond what the universal agents cover.

### Spawn Conditions

| Framework | Spawn? | Agent focus |
|-----------|--------|-------------|
| Next.js | Yes | Metadata API, Server/Client Components, data fetching, routing config, image/font/script/link components |
| Nuxt | Yes | Composables, auto-imports, Nitro, NuxtLink, NuxtImg |
| Gatsby | Yes | GraphQL layer, plugin ecosystem, image pipeline |
| Astro | Yes | Island architecture, content collections, integrations |
| Remix | No | SSR meta-framework — detected to avoid false "No SSR" CRITICAL, but uses universal checks. Dedicated agent support planned. |
| SvelteKit | No | SSR meta-framework — detected to avoid false "No SSR" CRITICAL, but uses universal checks. Dedicated agent support planned. |
| Qwik | No | Resumable framework — detected to avoid false "No SSR" CRITICAL, but uses universal checks. Dedicated agent support planned. |
| Eleventy | No | Template-based SSG — universal agents cover all checks with Eleventy-specific file patterns. No dedicated agent needed. |
| React (no meta-framework) | No | Universal agents cover SPA checks |
| Vue (no meta-framework) | No | Universal agents cover SPA checks |
| Angular | No | Universal agents cover SPA checks |
| Svelte | No | Universal agents cover SPA checks |
| Static HTML | No | No framework-specific checks needed |

### Next.js Version Gates

Checks are filtered by the detected Next.js version. Only include checks where the project version >= the minimum version.

| Version Range | Features Available | Key Checks |
|---------------|-------------------|------------|
| < 13 | Pages Router only | `next/head`, `getStaticProps`/`getServerSideProps`, `_document`, `_app` |
| 13.0 - 13.1 | App Router (beta) | Pages Router checks + early App Router (metadata via `head.tsx`) |
| 13.2+ | App Router (stable metadata) | `export const metadata`, `generateMetadata`, Server Components |
| 13.3+ | OG image generation | `opengraph-image.tsx`, `twitter-image.tsx` |
| 14.0+ | Server Actions stable | `'use server'`, `revalidatePath`/`revalidateTag`, Partial Prerendering (experimental) |
| 14.2+ | Improved metadata | `staleTimes` config |
| 15.0+ | React 19, new defaults | Fetch defaults to `no-store`, async request APIs, Turbopack stable |

**Version filtering rule**: When building the framework agent prompt, ONLY include checks whose minimum version is <= the detected project version. For example, if the project is Next.js 13.1, do NOT include checks for `export const metadata` (requires 13.2+).

### Nuxt Version Gates

| Version Range | Key Checks |
|---------------|------------|
| 2.x | Options API `head()`, `asyncData`, `fetch`, `nuxt.config.js` |
| 3.0+ | `useHead()`, `useSeoMeta()`, `definePageMeta`, Nitro, `nuxt.config.ts`, `<NuxtLink>`, `<NuxtImg>` |
| 3.7+ | `useSeoMeta()` recommended over `useHead()` for flat meta tags |

### Gatsby Version Gates

| Version Range | Key Checks |
|---------------|------------|
| < 3 | `gatsby-image` (old), `gatsby-plugin-react-helmet` |
| 3+ | `gatsby-plugin-image` (`<GatsbyImage>`, `<StaticImage>`), Head API |
| 4+ | Head API (preferred over Helmet), `<Script>` component, Partial Hydration |

### Astro Version Gates

| Version Range | Key Checks |
|---------------|------------|
| < 3 | `<Image>` (experimental), basic island architecture |
| 3+ | `<Image>` stable, Content Collections v2, ViewTransitions, `<Picture>` |
| 4+ | Content Collections with `image()`, improved `<Image>` |

---

## Check Selection Algorithm

The orchestrator follows this algorithm when building agent prompts:

```
1. Detect framework (from package.json dependencies)
2. Detect version (from package.json version string)
3. Detect router type (for Next.js: App vs Pages vs both)
4. For each agent (technical, performance, aeo):
   a. Start with universal checks for that agent
   b. Look up framework-specific checks for the detected framework
   c. Filter framework-specific checks by version (only include if project version >= minimum version)
   d. Filter by router type if applicable (e.g., App Router only checks)
   e. Combine universal + filtered framework checks into the agent prompt
5. For the framework agent:
   a. Check if the framework warrants a dedicated agent (see Spawn Conditions)
   b. If yes: collect all framework-specific deep checks, filter by version
   c. Build the framework agent prompt with only applicable checks
   d. If no: skip spawning the framework agent entirely
6. Pass the check lists to agents via their prompt templates
```

## Example: Check Selection for Next.js 14.2 (App Router)

**web-seo-technical**: Universal checks + Next.js technical checks (Metadata API [13.2+ pass], robots.ts [13+ pass], sitemap.ts [13+ pass], no next/head in App Router [13+ pass])

**web-seo-performance**: Universal checks + Next.js performance checks (next/image [pass], next/font [13+ pass], Server Components [13+ pass], excessive 'use client' [13+ pass], layout fetch caching [13+ pass], barrel files [13+ pass], Suspense [13+ pass], generateStaticParams [13+ pass]). EXCLUDE: fetch cache defaults [15+ fail], Partial Prerendering [14+ pass but flag as experimental]

**web-seo-aeo**: Universal AEO checks (all apply). Use Next.js App Router file paths for detection.

**web-seo-framework (Next.js)**: All Next.js deep checks filtered to <= 14.2. Include App Router checks. Exclude Pages Router-only checks unless both routers detected.

## Example: Check Selection for Nuxt 3.8

**web-seo-technical**: Universal checks + Nuxt 3+ checks (useHead, NuxtLink, nuxt.config app.head, definePageMeta, useSeoMeta)

**web-seo-performance**: Universal checks + Nuxt 3+ checks (NuxtImg, auto-imports, useLazyFetch, Nitro prerendering, lazy components)

**web-seo-aeo**: Universal AEO checks. Use Nuxt file paths for detection.

**web-seo-framework (Nuxt)**: All Nuxt 3+ deep checks.

## Example: Check Selection for plain React SPA

**web-seo-technical**: Universal checks + SPA checks (SSR availability [CRITICAL], react-helmet, hash routing)

**web-seo-performance**: Universal checks + SPA checks (code splitting, image optimization library)

**web-seo-aeo**: Universal AEO checks. Use generic SPA file paths.

**web-seo-framework**: NOT spawned (plain React has no dedicated agent).
