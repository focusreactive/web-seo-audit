# Nuxt SEO Patterns Reference

## Overview

This reference covers SEO-related patterns for both Nuxt 3 (Composition API, Nitro) and Nuxt 2 (Options API, Webpack). Each pattern includes detection rules (grep/glob patterns), correct implementation, common anti-patterns, and **version gates** indicating the minimum Nuxt version required.

**Version gate notation**: `[v3+]` means the check only applies to Nuxt >= 3. `[v3.7+]` means Nuxt >= 3.7. `[v2.x]` means Nuxt 2 only. `[any]` means all versions. Checks without a version gate apply to all versions.

## Version Detection

Determine which Nuxt version is in use before applying rules:

```
# Nuxt 3 indicators
grep: "\"nuxt\": \"\\^3|\"nuxt\": \"3|\"nuxt\": \"~3" package.json
glob: nuxt.config.ts
glob: app.vue
glob: server/api/**/*.{ts,js}
glob: composables/**/*.{ts,js}
grep: "defineNuxtConfig" nuxt.config.{ts,js}

# Nuxt 2 indicators
grep: "\"nuxt\": \"\\^2|\"nuxt\": \"2|\"nuxt\": \"~2" package.json
grep: "\"@nuxt/bridge\"" package.json
glob: nuxt.config.js
glob: store/**/*.js
grep: "export default {" pages/**/*.vue
grep: "asyncData" pages/**/*.vue
```

Nuxt 2 projects using `@nuxt/bridge` may support some Nuxt 3 APIs. Check for its presence before flagging v2-only patterns.

---

## Nuxt 3 Patterns [v3+]

Skip this entire section if the project does not use Nuxt 3.

### useHead() Composable [v3+]

**Detection**: `grep "useHead" app.vue pages/**/*.vue components/**/*.vue composables/**/*.{ts,js} layouts/**/*.vue`

**Correct — Static head in a page**:
```vue
<!-- pages/about.vue -->
<script setup lang="ts">
useHead({
  title: 'About Us',
  meta: [
    { name: 'description', content: 'Learn more about our company and mission.' },
    { property: 'og:title', content: 'About Us' },
    { property: 'og:description', content: 'Learn more about our company and mission.' },
    { property: 'og:image', content: 'https://example.com/og-about.jpg' },
    { name: 'twitter:card', content: 'summary_large_image' },
  ],
  link: [
    { rel: 'canonical', href: 'https://example.com/about' },
  ],
});
</script>
```

**Correct — Reactive head with computed values**:
```vue
<!-- pages/blog/[slug].vue -->
<script setup lang="ts">
const { data: post } = await useFetch(`/api/posts/${useRoute().params.slug}`);

useHead({
  title: () => post.value?.title ?? 'Blog',
  meta: [
    { name: 'description', content: () => post.value?.excerpt ?? '' },
    { property: 'og:title', content: () => post.value?.title ?? '' },
    { property: 'og:image', content: () => post.value?.image ?? '' },
  ],
});
</script>
```

**Anti-patterns**:
- Using raw `<meta>` tags in `<template>` instead of `useHead()`
- Using `useHead()` inside a client-only component for SEO-critical meta (won't be SSR'd)
- Missing `useHead()` entirely on pages — no title or description rendered

**Detection for anti-pattern**: `grep "<meta " pages/**/*.vue layouts/**/*.vue`

### useSeoMeta() [v3.7+]

**Detection**: `grep "useSeoMeta" pages/**/*.vue components/**/*.vue layouts/**/*.vue composables/**/*.{ts,js}`

**Correct**:
```vue
<!-- pages/product/[id].vue -->
<script setup lang="ts">
const { data: product } = await useFetch(`/api/products/${useRoute().params.id}`);

useSeoMeta({
  title: () => product.value?.name ?? 'Product',
  description: () => product.value?.description ?? '',
  ogTitle: () => product.value?.name ?? 'Product',
  ogDescription: () => product.value?.description ?? '',
  ogImage: () => product.value?.image ?? '',
  ogType: 'product',
  twitterCard: 'summary_large_image',
  twitterTitle: () => product.value?.name ?? '',
  twitterDescription: () => product.value?.description ?? '',
  robots: 'index, follow',
});
</script>
```

**Rules**:
- Prefer `useSeoMeta()` over `useHead()` for meta tags — it provides type safety, flat API, and prevents duplicate tags
- `useSeoMeta()` should not be used for `<link>` or `<script>` tags — use `useHead()` for those
- Reactive getters (arrow functions) are supported and recommended for dynamic content

**Anti-patterns**:
- Using `useHead()` with nested `meta` arrays when `useSeoMeta()` would be cleaner
- Missing reactive getters for dynamic data — meta won't update when data changes

**Detection for anti-pattern**: Check Nuxt version >= 3.7 and presence of `useHead` with `meta:` arrays in pages.
```
grep "useHead.*meta:" pages/**/*.vue
```

### definePageMeta() [v3+]

**Detection**: `grep "definePageMeta" pages/**/*.vue`

**Correct**:
```vue
<!-- pages/admin/dashboard.vue -->
<script setup lang="ts">
definePageMeta({
  layout: 'admin',
  middleware: 'auth',
  keepalive: true,
});

useSeoMeta({
  title: 'Admin Dashboard',
  robots: 'noindex, nofollow',
});
</script>
```

**Rules**:
- `definePageMeta()` is for page-level routing metadata (layout, middleware, keepalive), not for SEO head tags
- SEO meta tags should use `useHead()` or `useSeoMeta()`, not `definePageMeta()`
- `definePageMeta()` is a compiler macro — it must be in `<script setup>` at the top level

**Anti-patterns**:
- Putting `title` or `description` in `definePageMeta()` expecting them to render as `<title>` or `<meta>` tags
- Confusing `definePageMeta()` with `useSeoMeta()`

### nuxt.config.ts app.head [v3+]

**Detection**: `grep "app:" nuxt.config.{ts,js}` then check for `head:` nested within

**Correct**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      charset: 'utf-8',
      viewport: 'width=device-width, initial-scale=1',
      title: 'My Site — Default Title',
      meta: [
        { name: 'description', content: 'Default site description for pages without overrides.' },
        { property: 'og:site_name', content: 'My Site' },
        { name: 'theme-color', content: '#ffffff' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' },
      ],
    },
  },
});
```

**Anti-patterns**:
- Missing `lang` attribute in `htmlAttrs`
- Missing `charset` or `viewport` meta — causes rendering issues on mobile
- Putting page-specific meta in global config (should be per-page via `useHead()` / `useSeoMeta()`)

**Detection for anti-pattern**:
```
grep "htmlAttrs" nuxt.config.{ts,js}
# If missing, flag missing lang attribute
```

### NuxtLink Component [v3+]

**Detection**: `grep "<NuxtLink|<nuxt-link|<a href" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

**Correct**:
```vue
<template>
  <nav>
    <NuxtLink to="/">Home</NuxtLink>
    <NuxtLink to="/about">About</NuxtLink>
    <NuxtLink to="/blog" prefetch>Blog</NuxtLink>

    <!-- External links use <a> with rel attributes -->
    <a href="https://github.com/example" target="_blank" rel="noopener noreferrer">GitHub</a>
  </nav>
</template>
```

**Rules**:
- Use `<NuxtLink>` for all internal navigation — it handles prefetching, SPA transitions, and renders a proper `<a>` tag for crawlers
- Use raw `<a>` tags only for external links
- External links should include `rel="noopener noreferrer"` when using `target="_blank"`
- `<NuxtLink>` with `external` prop can also be used for external links

**Anti-patterns**:
- Using `<a href="/about">` for internal navigation instead of `<NuxtLink>`
- Using `navigateTo()` or `router.push()` for navigation that should be a crawlable link
- Missing `href`/`to` on link elements

**Detection for anti-pattern**: `grep "<a href=\"/" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

### NuxtImg / NuxtPicture (@nuxt/image) [v3+]

**Detection**: `grep "<NuxtImg|<nuxt-img|<NuxtPicture|<nuxt-picture|@nuxt/image" pages/**/*.vue components/**/*.vue nuxt.config.{ts,js}`

**Correct**:
```vue
<template>
  <div>
    <!-- Above-the-fold hero image: preload with priority -->
    <NuxtImg
      src="/hero.jpg"
      width="1200"
      height="600"
      alt="Descriptive hero image alt text"
      loading="eager"
      preload
      sizes="100vw md:80vw lg:1200px"
      format="webp"
    />

    <!-- Below-the-fold: lazy loaded by default -->
    <NuxtImg
      src="/product.jpg"
      width="400"
      height="300"
      alt="Product description"
      loading="lazy"
      sizes="(max-width: 768px) 100vw, 400px"
    />

    <!-- Art direction with NuxtPicture -->
    <NuxtPicture
      src="/banner.jpg"
      width="1200"
      height="400"
      alt="Banner description"
      format="avif,webp"
      sizes="100vw"
    />
  </div>
</template>
```

**Anti-patterns**:
- Using raw `<img>` tags instead of `<NuxtImg>` when `@nuxt/image` is installed
- Missing `alt` attribute or empty `alt=""` on meaningful images
- Missing `width`/`height` attributes — causes CLS (Cumulative Layout Shift)
- Missing `loading="eager"` or `preload` on hero/LCP images
- Using `<NuxtImg>` without configuring `@nuxt/image` module in `nuxt.config.ts`

**Detection for anti-pattern**: `grep "<img " pages/**/*.vue components/**/*.vue layouts/**/*.vue`

**Module detection**:
```
grep "@nuxt/image" nuxt.config.{ts,js}
grep "@nuxt/image" package.json
```

### Nitro Prerendering and Route Rules [v3+]

**Detection**: `grep "routeRules|prerender" nuxt.config.{ts,js}`

**Correct**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  routeRules: {
    // Prerender static pages at build time
    '/': { prerender: true },
    '/about': { prerender: true },
    '/pricing': { prerender: true },

    // ISR for blog — revalidate every hour
    '/blog/**': { isr: 3600 },

    // SSR for dynamic user-specific pages
    '/dashboard/**': { ssr: true },

    // SWR for API routes
    '/api/products': { swr: 600 },

    // Redirect rules
    '/old-page': { redirect: '/new-page' },
  },

  // Prerender specific routes for sitemap/robots
  nitro: {
    prerender: {
      routes: ['/sitemap.xml', '/robots.txt'],
      crawlLinks: true,
    },
  },
});
```

**Anti-patterns**:
- No `routeRules` at all on a content-heavy site — all pages rendered on demand
- Missing `prerender: true` for static marketing/landing pages
- Using SSR for pages that never change (e.g., legal pages, docs)
- Missing `nitro.prerender.crawlLinks` — pages reachable only through navigation won't be prerendered

**Detection for anti-pattern**:
```
grep "routeRules" nuxt.config.{ts,js}
# If absent, check if there are static-eligible pages
glob: pages/about.vue
glob: pages/pricing.vue
glob: pages/contact.vue
```

### useLazyFetch / useLazyAsyncData [v3+]

**Detection**: `grep "useLazyFetch\|useLazyAsyncData\|useFetch\|useAsyncData" pages/**/*.vue components/**/*.vue`

**Correct**:
```vue
<!-- pages/index.vue -->
<script setup lang="ts">
// Critical above-fold data: blocks rendering (SSR-safe)
const { data: hero } = await useFetch('/api/hero');

// Below-fold data: loads lazily, doesn't block navigation
const { data: recommendations, pending } = useLazyFetch('/api/recommendations');
</script>

<template>
  <main>
    <HeroSection :data="hero" />
    <section v-if="pending">Loading recommendations...</section>
    <RecommendationGrid v-else :items="recommendations" />
  </main>
</template>
```

**Rules**:
- Use `await useFetch()` / `await useAsyncData()` for SEO-critical above-the-fold content — blocks SSR until data is available
- Use `useLazyFetch()` / `useLazyAsyncData()` (without `await`) for below-fold, non-SEO-critical content — doesn't block navigation/rendering
- Never use bare `$fetch` or `fetch()` in component setup for SSR content — it won't be awaited during SSR

**Anti-patterns**:
- Using `useLazyFetch` for SEO-critical content (title, description, main heading) — content won't be in SSR HTML
- Using `await useFetch` for all data including below-fold — slows page transitions
- Using `$fetch` directly in `<script setup>` instead of `useFetch` — causes duplicate requests (server + client)

**Detection for anti-pattern**:
```
grep "\$fetch" pages/**/*.vue components/**/*.vue
# Flag $fetch usage in <script setup> that isn't inside an event handler
```

### Auto-Imports and Tree-Shaking [v3+]

**Detection**: `grep "imports:" nuxt.config.{ts,js}`

**Correct**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  // Auto-imports are enabled by default and tree-shaken
  // Only disable if you have naming conflicts
  imports: {
    autoImport: true, // default
  },
});
```

```vue
<!-- pages/index.vue -->
<script setup lang="ts">
// Auto-imported: useHead, useFetch, useRoute, etc.
// No explicit import needed — Nuxt resolves at build time
useHead({ title: 'Home' });
const { data } = await useFetch('/api/data');
</script>
```

**Rules**:
- Nuxt 3 auto-imports are tree-shaken at build time — unused composables are NOT included in the bundle
- Custom composables in `composables/` are also auto-imported
- Flag only if `imports.autoImport: false` is set AND composables are manually imported from `#imports` with wildcard patterns

**Anti-patterns**:
- Disabling auto-imports globally and importing everything manually — loses DX without bundle benefit
- Using `import * from '#imports'` — defeats tree-shaking
- Heavy third-party composables registered in `imports.presets` that load on every page

**Detection for anti-pattern**:
```
grep "autoImport.*false" nuxt.config.{ts,js}
grep "import \* from.*#imports" pages/**/*.vue components/**/*.vue
```

### Server Routes for robots.txt, sitemap, llms.txt [v3+]

**Detection**:
```
glob: server/routes/robots.txt.{ts,js}
glob: server/routes/sitemap.xml.{ts,js}
glob: server/routes/llms.txt.{ts,js}
glob: public/robots.txt
glob: public/sitemap.xml
```

**Correct — server/routes/robots.txt.ts**:
```ts
// server/routes/robots.txt.ts
export default defineEventHandler((event) => {
  const sitemapUrl = 'https://example.com/sitemap.xml';
  return `User-agent: *
Allow: /
Disallow: /api/
Disallow: /admin/

Sitemap: ${sitemapUrl}`;
});
```

**Correct — server/routes/sitemap.xml.ts**:
```ts
// server/routes/sitemap.xml.ts
export default defineEventHandler(async (event) => {
  const posts = await $fetch('/api/posts');
  const baseUrl = 'https://example.com';

  const urls = [
    { loc: baseUrl, lastmod: new Date().toISOString(), priority: '1.0' },
    ...posts.map((post: any) => ({
      loc: `${baseUrl}/blog/${post.slug}`,
      lastmod: post.updatedAt,
      priority: '0.8',
    })),
  ];

  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((u) => `  <url>
    <loc>${u.loc}</loc>
    <lastmod>${u.lastmod}</lastmod>
    <priority>${u.priority}</priority>
  </url>`).join('\n')}
</urlset>`;

  setResponseHeader(event, 'content-type', 'application/xml');
  return sitemap;
});
```

**Correct — server/routes/llms.txt.ts**:
```ts
// server/routes/llms.txt.ts
export default defineEventHandler((event) => {
  setResponseHeader(event, 'content-type', 'text/plain');
  return `# My Site
> A brief description of the site for LLMs.

## Documentation
- [API Docs](https://example.com/docs/api): REST API reference
- [Guide](https://example.com/docs/guide): Getting started guide
`;
});
```

**Rules**:
- Prefer dynamic server routes over static `public/` files for robots.txt and sitemap — allows dynamic content
- Consider using `@nuxtjs/sitemap` module for complex sitemaps
- Prerender sitemap and robots routes via `nitro.prerender.routes` for static hosting

**Anti-patterns**:
- No robots.txt or sitemap at all
- Static `public/sitemap.xml` that doesn't include dynamic pages
- Sitemap missing `lastmod` or containing stale dates
- robots.txt blocking important paths

### useSchemaOrg (nuxt-schema-org) [v3+]

**Detection**: `grep "useSchemaOrg\|nuxt-schema-org\|@nuxtjs/schema-org" pages/**/*.vue nuxt.config.{ts,js} package.json`

**Correct**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['nuxt-schema-org'],
  schemaOrg: {
    host: 'https://example.com',
  },
});
```

```vue
<!-- pages/blog/[slug].vue -->
<script setup lang="ts">
const { data: post } = await useFetch(`/api/posts/${useRoute().params.slug}`);

useSchemaOrg([
  defineArticle({
    '@type': 'BlogPosting',
    headline: post.value?.title,
    description: post.value?.excerpt,
    image: post.value?.image,
    datePublished: post.value?.createdAt,
    dateModified: post.value?.updatedAt,
    author: {
      name: post.value?.author,
    },
  }),
]);
</script>
```

```vue
<!-- pages/index.vue -->
<script setup lang="ts">
useSchemaOrg([
  defineWebSite({
    name: 'My Site',
    url: 'https://example.com',
  }),
  defineWebPage({
    name: 'Home',
    description: 'Welcome to My Site',
  }),
]);
</script>
```

**Anti-patterns**:
- Manual `<script type="application/ld+json">` in templates when `nuxt-schema-org` is installed — loses validation and dedup
- Missing structured data on article/product/FAQ pages
- Structured data with hardcoded values instead of reactive data from API

**Detection for anti-pattern**:
```
grep "application/ld\+json" pages/**/*.vue components/**/*.vue layouts/**/*.vue
```

### Lazy Component Loading [v3+]

**Detection**: `grep "<Lazy" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

**Correct**:
```vue
<!-- pages/index.vue -->
<template>
  <div>
    <!-- Above-the-fold: import normally -->
    <HeroBanner :data="heroData" />
    <FeaturedProducts :products="featured" />

    <!-- Below-the-fold: lazy loaded with Lazy prefix -->
    <LazyNewsletterSignup />
    <LazyRecentReviews />
    <LazyFooterLinks />
  </div>
</template>

<script setup lang="ts">
const { data: heroData } = await useFetch('/api/hero');
const { data: featured } = await useFetch('/api/featured');
</script>
```

**Rules**:
- Nuxt 3 auto-registers all components in `components/` — prefix any component with `Lazy` to defer loading
- Use `<Lazy*>` for below-fold components: testimonials, newsletter forms, comment sections, footer widgets
- Never use `<Lazy*>` on above-fold components (Hero, Header, Navigation) — delays LCP
- `<Lazy*>` components load when they enter the viewport (uses Intersection Observer)

**Anti-patterns**:
- Using `<Lazy*>` prefix on above-the-fold components (HeroBanner, Header, Nav)
- Not using `<Lazy*>` on heavy below-fold components — increases initial bundle size
- Dynamically importing with `defineAsyncComponent` when `<Lazy*>` prefix suffices

**Detection for anti-pattern**:
```
grep "<LazyHero\|<LazyHeader\|<LazyNav\|<LazyBanner" pages/**/*.vue layouts/**/*.vue
# Flag: above-fold components should not be lazy
```

---

## Nuxt 2 Patterns [v2.x]

Skip this entire section if the project does not use Nuxt 2.

### head() Method [v2.x]

**Detection**: `grep "head()\|head:" pages/**/*.vue components/**/*.vue`

**Correct — Page component head**:
```vue
<!-- pages/about.vue (Nuxt 2, Options API) -->
<script>
export default {
  head() {
    return {
      title: 'About Us',
      meta: [
        { hid: 'description', name: 'description', content: 'Learn more about our company.' },
        { hid: 'og:title', property: 'og:title', content: 'About Us' },
        { hid: 'og:description', property: 'og:description', content: 'Learn more about our company.' },
      ],
      link: [
        { rel: 'canonical', href: 'https://example.com/about' },
      ],
    };
  },
};
</script>
```

**Correct — Dynamic head from asyncData**:
```vue
<!-- pages/blog/_slug.vue (Nuxt 2) -->
<script>
export default {
  async asyncData({ params, $axios }) {
    const post = await $axios.$get(`/api/posts/${params.slug}`);
    return { post };
  },
  head() {
    return {
      title: this.post?.title ?? 'Blog',
      meta: [
        { hid: 'description', name: 'description', content: this.post?.excerpt ?? '' },
        { hid: 'og:title', property: 'og:title', content: this.post?.title ?? '' },
        { hid: 'og:image', property: 'og:image', content: this.post?.image ?? '' },
      ],
    };
  },
};
</script>
```

**Rules**:
- Always use `hid` key on meta tags to prevent duplicates between layout and page
- `head()` must be a function (not an object) to access `this` for dynamic data
- Layout `head()` provides defaults; page `head()` overrides via matching `hid`

**Anti-patterns**:
- Missing `hid` on meta tags — causes duplicate meta tags in rendered HTML
- Using `head` as an object instead of a function — can't access component data
- Missing `head()` entirely on pages — no title or description

**Detection for anti-pattern**:
```
grep "hid:" pages/**/*.vue
# If pages have head() but no hid on meta, flag potential duplicates
```

### asyncData / fetch (Nuxt 2) [v2.x]

**Detection**: `grep "asyncData\|fetch()" pages/**/*.vue`

**Correct — asyncData for SSR data**:
```vue
<!-- pages/products/index.vue (Nuxt 2) -->
<script>
export default {
  async asyncData({ $axios }) {
    const products = await $axios.$get('/api/products');
    return { products };
  },
};
</script>
```

**Correct — fetch hook (Nuxt 2.12+)**:
```vue
<!-- pages/products/index.vue (Nuxt 2.12+) -->
<script>
export default {
  data() {
    return { products: [] };
  },
  async fetch() {
    this.products = await this.$axios.$get('/api/products');
  },
  fetchOnServer: true, // default, ensures SSR
};
</script>
```

**Rules**:
- `asyncData` runs before component render on server — returned data merges into component data
- `fetch` hook (Nuxt 2.12+) can run in any component, not just pages
- Both are SSR-safe — data is serialized and sent to client
- Use `fetchOnServer: true` (default) for SEO-critical content

**Anti-patterns**:
- Using `mounted()` or `created()` with `this.$axios` for SEO content — only runs on client
- Setting `fetchOnServer: false` on pages with SEO-critical content
- Using `window.fetch` in `asyncData` — throws during SSR

**Detection for anti-pattern**:
```
grep "mounted.*fetch\|mounted.*axios\|created.*fetch\|created.*axios" pages/**/*.vue
grep "fetchOnServer.*false" pages/**/*.vue
```

### nuxt.config.js head (Nuxt 2) [v2.x]

**Detection**: `grep "head:" nuxt.config.js`

**Correct**:
```js
// nuxt.config.js (Nuxt 2)
export default {
  head: {
    htmlAttrs: { lang: 'en' },
    title: 'My Site',
    titleTemplate: '%s — My Site',
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { hid: 'description', name: 'description', content: 'Default site description.' },
      { hid: 'og:site_name', property: 'og:site_name', content: 'My Site' },
    ],
    link: [
      { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
    ],
  },
};
```

**Rules**:
- `titleTemplate` with `%s` placeholder provides consistent title formatting
- Always set `lang` in `htmlAttrs`
- Use `hid` on all meta tags to enable page-level overrides

**Anti-patterns**:
- Missing `titleTemplate` — pages either have no site name or must repeat it
- Missing `lang` in `htmlAttrs`
- Missing `charset` or `viewport` meta

### nuxt-link (Nuxt 2) [v2.x]

**Detection**: `grep "<nuxt-link\|<NuxtLink\|<a href" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

**Correct**:
```vue
<!-- Nuxt 2 template -->
<template>
  <nav>
    <nuxt-link to="/">Home</nuxt-link>
    <nuxt-link to="/about">About</nuxt-link>
    <nuxt-link :to="{ name: 'blog-slug', params: { slug: post.slug } }">
      {{ post.title }}
    </nuxt-link>
  </nav>
</template>
```

**Anti-patterns**:
- Using `<a href="/about">` for internal links instead of `<nuxt-link>`
- Using `this.$router.push()` for navigation that should be a crawlable link
- `<nuxt-link>` to external URLs without `external` attribute (Nuxt 2.15+)

**Detection for anti-pattern**: `grep "<a href=\"/" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

---

## Common Anti-Patterns (Both Versions)

### Client-Side Only Data Fetching for SEO Content

**Detection**:
```
# Nuxt 3
grep "onMounted.*fetch\|onMounted.*\$fetch\|ref(null).*onMounted" pages/**/*.vue components/**/*.vue

# Nuxt 2
grep "mounted.*fetch\|mounted.*axios\|created.*fetch\|created.*axios" pages/**/*.vue components/**/*.vue
```

**Problem**: Content fetched only in client-side lifecycle hooks (`onMounted`, `mounted`, `created`) is invisible to search engine crawlers during SSR. This results in empty HTML for crawlers and poor LCP.

**Correct (Nuxt 3)**:
```vue
<script setup lang="ts">
// SSR-safe: data is fetched on server and hydrated on client
const { data: products } = await useFetch('/api/products');
</script>
```

**Correct (Nuxt 2)**:
```vue
<script>
export default {
  async asyncData({ $axios }) {
    const products = await $axios.$get('/api/products');
    return { products };
  },
};
</script>
```

**Anti-pattern (Nuxt 3)**:
```vue
<script setup lang="ts">
const products = ref(null);

onMounted(async () => {
  // Content not in SSR HTML — crawlers see empty page
  products.value = await $fetch('/api/products');
});
</script>
```

**Anti-pattern (Nuxt 2)**:
```vue
<script>
export default {
  data() {
    return { products: [] };
  },
  mounted() {
    // Content not in SSR HTML
    this.$axios.$get('/api/products').then((data) => {
      this.products = data;
    });
  },
};
</script>
```

### Missing Semantic HTML

**Detection**: Check for heading hierarchy, landmark elements, structured content.

**Rules**:
- One `<h1>` per page
- No skipped heading levels (h1 to h3 without h2)
- Use `<main>`, `<nav>`, `<article>`, `<section>`, `<aside>`, `<footer>`
- Use `<button>` for actions, `<a>` / `<NuxtLink>` for navigation
- Nuxt 3 layouts should wrap content in semantic elements

**Anti-patterns**:
- Using `<div>` for everything without semantic structure
- Multiple `<h1>` tags on a single page
- `<a @click.prevent>` for actions that should be `<button>`

**Detection**:
```
grep "<h1" pages/**/*.vue layouts/**/*.vue
# Flag if more than one <h1> per page
```

### Broken Internal Links

**Detection**: `grep "href=\"#\"\|href=\"\"\|href=\"javascript:" pages/**/*.vue components/**/*.vue layouts/**/*.vue`

**Rules**:
- No empty `href` attributes
- No `javascript:` pseudo-URLs
- No `#` as sole href on navigational elements

### Missing Error Pages

**Detection**:
```
# Nuxt 3
glob: error.vue
grep: "useError\|NuxtErrorBoundary" app.vue layouts/**/*.vue

# Nuxt 2
glob: layouts/error.vue
```

**Correct (Nuxt 3)**:
```vue
<!-- error.vue (project root) -->
<script setup lang="ts">
const error = useError();

useSeoMeta({
  title: error.value?.statusCode === 404 ? 'Page Not Found' : 'Error',
  robots: 'noindex',
});
</script>

<template>
  <div>
    <h1>{{ error?.statusCode === 404 ? 'Page Not Found' : 'Something Went Wrong' }}</h1>
    <NuxtLink to="/">Go Home</NuxtLink>
  </div>
</template>
```

**Correct (Nuxt 2)**:
```vue
<!-- layouts/error.vue -->
<script>
export default {
  props: ['error'],
  head() {
    return {
      title: this.error.statusCode === 404 ? 'Page Not Found' : 'Error',
      meta: [{ hid: 'robots', name: 'robots', content: 'noindex' }],
    };
  },
};
</script>

<template>
  <div>
    <h1>{{ error.statusCode === 404 ? 'Page Not Found' : 'Something Went Wrong' }}</h1>
    <nuxt-link to="/">Go Home</nuxt-link>
  </div>
</template>
```

### Console Errors During SSR

When analyzing code, flag patterns that would throw during SSR:
- Direct `window` or `document` access outside client-only hooks
- Browser-only APIs used during SSR

**Detection**:
```
# Nuxt 3 — check <script setup> for direct browser API usage
grep "window\.\|document\.\|localStorage\|sessionStorage" pages/**/*.vue layouts/**/*.vue
# Exclude lines inside onMounted or <ClientOnly>

# Nuxt 2
grep "window\.\|document\.\|localStorage\|sessionStorage" pages/**/*.vue layouts/**/*.vue
# Exclude lines inside mounted() or process.client checks
```

**Correct (Nuxt 3)**:
```vue
<script setup lang="ts">
// Use process.client or onMounted for browser APIs
onMounted(() => {
  const width = window.innerWidth;
});
</script>

<template>
  <!-- Or use <ClientOnly> wrapper -->
  <ClientOnly>
    <BrowserOnlyWidget />
  </ClientOnly>
</template>
```

**Correct (Nuxt 2)**:
```vue
<script>
export default {
  mounted() {
    // Safe: only runs on client
    const width = window.innerWidth;
  },
  methods: {
    doSomething() {
      if (process.client) {
        localStorage.setItem('key', 'value');
      }
    },
  },
};
</script>
```

---

## Performance Antipatterns

These are Nuxt-specific performance antipatterns that hurt runtime performance, inflate bundles, or cause unnecessary re-renders. General CWV patterns are covered by `web-seo-performance`; these are framework-specific issues only.

### Heavy Plugins Loaded on Every Page [any]

**Detection**:
```
# Nuxt 3
glob: plugins/**/*.{ts,js}
grep: "defineNuxtPlugin" plugins/**/*.{ts,js}
grep: "moment\|import.*lodash[^/]\|@sentry\|chart.js\|three" plugins/**/*.{ts,js}

# Nuxt 2
grep: "plugins:" nuxt.config.{js,ts}
grep: "moment\|import.*lodash[^/]\|@sentry\|chart.js\|three" plugins/**/*.{js,ts}
```

**Rules**:
- Plugins run on every page load — heavy libraries in plugins inflate the global bundle
- Flag any plugin importing libraries > 50KB (moment, lodash, chart.js, three.js, etc.)
- Use dynamic imports or move to page-specific composables

**Correct (Nuxt 3)** — conditional plugin:
```ts
// plugins/analytics.client.ts
export default defineNuxtPlugin(() => {
  // .client.ts suffix: only runs on client
  // Dynamically import heavy library
  import('analytics-library').then((analytics) => {
    analytics.init({ key: 'abc' });
  });
});
```

**Anti-pattern (Nuxt 3)**:
```ts
// plugins/heavy.ts
import moment from 'moment'; // 300KB+ loaded on every page, server and client
import _ from 'lodash'; // 70KB+ loaded on every page

export default defineNuxtPlugin(() => {
  return { provide: { moment, lodash: _ } };
});
```

**Anti-pattern (Nuxt 2)**:
```js
// plugins/heavy.js
import moment from 'moment';
import _ from 'lodash';

export default (context, inject) => {
  inject('moment', moment);
  inject('lodash', _);
};
```

```js
// nuxt.config.js
export default {
  plugins: [
    '~/plugins/heavy.js', // Loaded on every page, both server and client
  ],
};
```

### Excessive Auto-Imports or Global Plugins [v3+]

**Detection**:
```
# Count plugins
glob: plugins/**/*.{ts,js}

# Check for plugins without .client or .server suffix
# These run on both server and client
grep -L "\.client\.\|\.server\." plugins/**/*.{ts,js}

# Check nuxt.config for manually registered plugins
grep "plugins:" nuxt.config.{ts,js}
```

**Rules**:
- Plugins without `.client.ts` or `.server.ts` suffix run on BOTH server and client — doubles their impact
- \>8 universal plugins = MEDIUM — review whether each truly needs to run everywhere
- Plugins that only need client-side (analytics, intercom, etc.) should use `.client.ts` suffix
- Plugins that only need server-side (logging, auth setup) should use `.server.ts` suffix

**Correct**:
```
plugins/
  analytics.client.ts     # Client only
  auth.server.ts          # Server only
  api.ts                  # Both (lightweight, needed everywhere)
```

**Anti-pattern**:
```
plugins/
  analytics.ts            # Runs on server too — wasteful
  sentry.ts               # Runs on server too — use .client.ts
  intercom.ts             # Runs on server too — use .client.ts
  logger.ts               # Runs on client too — use .server.ts
  moment.ts               # Heavy library loaded everywhere
  lodash.ts               # Heavy library loaded everywhere
```

### Missing Nitro Prerendering for Static-Eligible Routes [v3+]

**Detection**:
```
grep "routeRules\|prerender" nuxt.config.{ts,js}
glob: pages/about.vue
glob: pages/pricing.vue
glob: pages/contact.vue
glob: pages/faq.vue
glob: pages/terms.vue
glob: pages/privacy.vue
```

**Rules**:
- Static pages (about, pricing, contact, terms, privacy, FAQ) without `prerender: true` in `routeRules` = MEDIUM — these pages never change and should be prerendered for optimal TTFB
- Content pages without ISR or prerender rules = LOW — consider adding `isr` for periodic revalidation
- Missing `nitro.prerender.crawlLinks` when using hybrid rendering = LOW

**Correct**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  routeRules: {
    '/about': { prerender: true },
    '/pricing': { prerender: true },
    '/terms': { prerender: true },
    '/blog/**': { isr: 3600 },
  },
});
```

**Anti-pattern**:
```ts
// nuxt.config.ts
export default defineNuxtConfig({
  // No routeRules at all — every page rendered on demand
});
```

### Missing Lazy Prefix for Below-Fold Components [v3+]

**Detection**:
```
# Check for components that are likely below-fold but not lazy
grep "<Newsletter\|<Testimonial\|<RelatedPost\|<Comment\|<Footer\|<RecentArticle" pages/**/*.vue layouts/**/*.vue
# Cross-reference with lazy versions
grep "<LazyNewsletter\|<LazyTestimonial\|<LazyRelatedPost\|<LazyComment\|<LazyRecentArticle" pages/**/*.vue layouts/**/*.vue
```

**Rules**:
- Below-fold components (testimonials, comments, newsletter signups, related posts) without `Lazy` prefix = MEDIUM — included in initial bundle unnecessarily
- Above-fold components (Hero, Header, Nav) should NOT have `Lazy` prefix — delays LCP

**Correct**:
```vue
<template>
  <div>
    <HeroSection />           <!-- Above fold: loaded immediately -->
    <ProductGrid />           <!-- Above fold: loaded immediately -->
    <LazyTestimonials />      <!-- Below fold: lazy loaded -->
    <LazyNewsletterForm />    <!-- Below fold: lazy loaded -->
    <LazyRelatedProducts />   <!-- Below fold: lazy loaded -->
  </div>
</template>
```

**Anti-pattern**:
```vue
<template>
  <div>
    <LazyHeroSection />       <!-- Above fold: should NOT be lazy -->
    <Testimonials />          <!-- Below fold: should be lazy -->
    <NewsletterForm />        <!-- Below fold: should be lazy -->
    <RelatedProducts />       <!-- Below fold: should be lazy -->
  </div>
</template>
```

### Nuxt 2: Modules and Build Modules Confusion [v2.x]

**Detection**:
```
grep "modules:\|buildModules:" nuxt.config.js
```

**Rules**:
- In Nuxt 2, `buildModules` are only loaded during build (dev/build) — lighter for production
- `modules` are loaded at runtime — heavier, needed for runtime features
- Build-only tools (@nuxtjs/tailwindcss, @nuxtjs/eslint-module, @nuxtjs/composition-api) should be in `buildModules`
- Runtime modules (@nuxtjs/axios, @nuxtjs/auth, @nuxtjs/i18n) should be in `modules`

**Anti-pattern**:
```js
// nuxt.config.js
export default {
  modules: [
    '@nuxtjs/tailwindcss',     // Should be in buildModules
    '@nuxtjs/eslint-module',   // Should be in buildModules
    '@nuxtjs/composition-api', // Should be in buildModules
    '@nuxtjs/axios',           // Correct: runtime module
  ],
};
```

**Correct**:
```js
// nuxt.config.js
export default {
  buildModules: [
    '@nuxtjs/tailwindcss',
    '@nuxtjs/eslint-module',
    '@nuxtjs/composition-api',
  ],
  modules: [
    '@nuxtjs/axios',
    '@nuxtjs/auth',
  ],
};
```

### Large Inline Data in Pages [any]

**Detection**:
```
# Look for large object/array literals in page files
grep "const .* = \[\|const .* = \{" pages/**/*.vue
# Manual check: flag objects/arrays > 50 lines or containing hardcoded data
```

**Rules**:
- Large data objects (>50 items or >50 lines) inlined in page components = MEDIUM — inflates the JavaScript bundle sent to the client. Move data to server routes or fetch at build time.

**Correct (Nuxt 3)**:
```vue
<script setup lang="ts">
// Data fetched from server route — not in client bundle
const { data: countries } = await useFetch('/api/countries');
</script>
```

**Anti-pattern**:
```vue
<script setup lang="ts">
// 200+ items inline in the page component
const countries = [
  { code: 'US', name: 'United States' },
  { code: 'GB', name: 'United Kingdom' },
  // ... 200 more entries
];
</script>
```

### Importing Entire Icon Libraries [any]

**Detection**:
```
# Root imports from icon libraries
grep "from 'vue-icons'\|from '@fortawesome/fontawesome'\|import \* as.*Icon" pages/**/*.vue components/**/*.vue
# Check for correct tree-shakeable imports
grep "from '@fortawesome/free-solid-svg-icons'\|from 'lucide-vue-next'" pages/**/*.vue components/**/*.vue
```

**Rules**:
- Root-level icon library imports instead of individual icon imports = MEDIUM — pulls the entire library into the bundle

**Correct**:
```vue
<script setup lang="ts">
import { FaGithub } from 'vue3-icons/fa'; // Subpath import
import { ArrowRight } from 'lucide-vue-next'; // Named export (tree-shakeable)
</script>
```

**Anti-pattern**:
```vue
<script setup lang="ts">
import * as Icons from 'vue3-icons'; // Entire library
</script>
```
