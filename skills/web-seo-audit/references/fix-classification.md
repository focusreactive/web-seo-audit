# Fix Classification Reference

This reference defines how audit issues are classified by fixability for the `fix` subcommand. The orchestrator uses this to decide which issues can be auto-fixed, which need user confirmation, and which require manual intervention.

## Fixability Levels

| Level | Description | Action |
|-------|-------------|--------|
| `auto-fix` | Safe mechanical change. No risk of breaking functionality. | Apply directly using Edit/Write tools |
| `confirm-fix` | Clear fix but moderate risk — could change behavior or layout. | Show the change, ask user, apply if confirmed |
| `manual` | Requires architectural decisions, significant restructuring, or human judgment. | Report in final summary, do not attempt |

## Classification Matrix

### auto-fix — Safe Mechanical Changes

These fixes add known, fixed-value attributes or standard directives. They NEVER generate content, guess values, or affect layout:

| Issue Pattern | Fix Action | Tool |
|---------------|-----------|------|
| Missing `preconnect` hint for external origins | Add `<link rel="preconnect">` to root layout/head | Edit |
| Missing `font-display: swap` | Add `font-display: swap` to `@font-face` rules or `next/font` config | Edit |
| Missing `lang` attribute on `<html>` | Add `lang="en"` (or detected language) to `<html>` tag | Edit |
| Missing `rel="noopener"` on external links | Add `rel="noopener"` to `target="_blank"` links | Edit |
| Missing `viewport` meta tag | Add viewport meta tag to root layout or `<head>` | Edit |
| Missing `sitemap.xml` reference in `robots.txt` | Append `Sitemap:` directive to robots.txt | Edit |
| Missing `loading="lazy"` on below-fold images | Add `loading="lazy"` to below-the-fold `<img>` tags | Edit |
| Missing `mainEntityOfPage` in structured data | Add `mainEntityOfPage` using existing canonical URL from page | Edit |

### confirm-fix — Clear Fix, Moderate Risk

These fixes have a clear solution but could affect behavior, layout, or involve generated content that needs user review:

| Issue Pattern | Fix Action | Risk | Tool |
|---------------|-----------|------|------|
| Missing `alt` attribute on images | Add `alt=""` for decorative, `alt="{descriptive}"` for content images | Generated descriptions may be inaccurate | Edit |
| Missing `width`/`height` on `<img>` tags | Add explicit `width` and `height` attributes | Wrong dimensions break layout | Edit |
| Missing JSON-LD structured data (Organization, WebSite) | Add JSON-LD script block with schema from site metadata | Generated business info may be inaccurate | Write/Edit |
| Missing `metadata` export on pages | Add basic metadata export with title/description derived from content | Generated titles/descriptions are approximations | Edit |
| Missing `llms.txt` file | Create `public/llms.txt` with site info from `package.json` | Generated content may misrepresent the site | Write |
| Missing AI bot rules in `robots.txt` | Append AI bot user-agent rules to existing robots.txt | Policy decision — user may want AI bots blocked | Edit |
| Missing `<main>` landmark | Wrap primary content area in `<main>` | May affect CSS selectors/styling | Edit |
| Missing `dateModified` in structured data | Add `dateModified` field to existing JSON-LD | Cannot determine actual modification date from code | Edit |
| Missing `@id` in structured data | Add `@id` based on canonical URL pattern | URL pattern may be incorrect | Edit |
| Missing `sameAs` on Organization schema | Add `sameAs` array with social profile URLs if discoverable | May reference wrong social profiles | Edit |
| Raw `<img>` tags → `next/image` | Replace `<img>` with `<Image>` component, add import | May change image sizing/layout | Edit |
| Unnecessary `'use client'` on pages | Remove `'use client'` directive | Could break if component uses hooks | Edit |
| Missing security headers | Add `headers()` function to `next.config.js` | Could conflict with deployment platform | Edit |
| Missing semantic landmarks (`<article>`, `<section>`) | Wrap content in semantic elements | May affect CSS selectors/styling | Edit |
| Missing `Suspense` boundaries | Wrap async components in `<Suspense>` with fallback | Affects loading UX | Edit |
| Raw `<a>` tags → `next/link` for internal routes | Replace `<a href="/...">` with `<Link>` | Could affect navigation behavior | Edit |
| Redirect chain consolidation (A→B→C to A→C) | Update redirect config to point directly to final destination | Could break intentional intermediate redirects | Edit |
| Redirect loop fix | Remove or correct circular redirect entries | May require choosing which redirect to keep | Edit |
| Wrong redirect status code (302→301) | Change `permanent: false` to `permanent: true` or 302 to 301 | Changes caching behavior, affects bookmarks | Edit |
| Missing `rel="next/prev"` on paginated pages | Add pagination link tags to head | May not suit all pagination strategies | Edit |
| Raw `<script>` → `next/script` | Replace `<script>` with `<Script>` component | Could affect script loading order | Edit |
| Google Fonts `<link>` → `next/font` | Replace CDN link with `next/font/google` import | Changes font loading behavior | Edit |
| Missing `priority` prop on hero images | Add `priority` to above-the-fold `<Image>` | Changes image loading priority | Edit |
| Missing `sizes` prop on `fill` images | Add `sizes` prop to `<Image fill>` | Affects responsive image behavior | Edit |
| `dynamic = 'force-dynamic'` on static-eligible pages | Remove or change to ISR with `revalidate` | Changes rendering strategy | Edit |
| Missing `robots.ts` (has `public/robots.txt`) | Create `app/robots.ts` typed equivalent | Replaces static file with dynamic | Write |
| Missing `sitemap.ts` (has static sitemap) | Create `app/sitemap.ts` typed equivalent | Replaces static file with dynamic | Write |
| Barrel file → direct imports | Replace `import { X } from '@/components'` with `import { X } from '@/components/X'` | Changes import paths, may affect other imports | Edit |
| Icon library root import → subpath import | Replace `from 'react-icons'` with `from 'react-icons/fa'` (specific set) | Changes import path | Edit |
| Layout fetch without caching | Add `next: { revalidate: N }` to `fetch()` calls in layouts | Changes caching behavior | Edit |
| Dynamic import → static import for above-fold | Replace `dynamic(() => import(...))` with static `import` for Hero/Header/Nav | Changes bundle splitting | Edit |
| `getServerSideProps` → `getStaticProps` + `revalidate` | Convert SSR to ISR with revalidation period | Changes rendering strategy, needs `getStaticPaths` | Edit |

### manual — Requires Architectural Decisions

These issues require human judgment and cannot be safely automated:

| Issue Pattern | Why Manual |
|---------------|-----------|
| Client-side only rendering (no SSR/SSG) | Requires architectural decision: SSR vs SSG vs ISR, affects entire app structure |
| Convert SPA to SSR | Fundamental architecture change, affects data fetching and state management |
| Restructure component tree (push `'use client'` down) | Requires understanding component dependencies and data flow |
| Fix heading hierarchy (skipping levels) | Requires content/design decisions about semantic structure |
| Missing H1 on pages | Requires deciding what the primary heading should be — content decision |
| Multiple H1 elements on a page | Requires deciding which H1 to keep or how to restructure headings |
| Route depth > 3-4 path segments | Requires URL restructuring and redirect planning — architectural decision |
| Zero/minimal server-rendered content | Requires moving data fetching to server or adding static content — architectural decision |
| Missing About page | Requires content, design, and routing decisions |
| Missing Contact page or Privacy Policy | Requires content and legal review |
| Missing author information on content pages | Requires deciding attribution model and author data source |
| Hash-based SPA routing (`/#/`) | Requires migration to history-based routing — architectural decision |
| Create dedicated author pages | Requires design, routing, and content decisions |
| Add `generateStaticParams` to dynamic routes | Requires knowledge of all possible param values and data sources |
| Implement proper code splitting | Requires understanding bundle composition and user flows |
| Replace heavy packages (moment → date-fns) | Requires API migration across codebase |
| Add list virtualization | Requires evaluating data sizes and choosing library |
| Fix duplicate title tags across pages | Requires unique content decisions per page |
| Add `hreflang` / i18n configuration | Requires locale strategy decisions |
| Create `llms-full.txt` | Requires curated comprehensive content about the site |
| Add `FAQPage` / `HowTo` schema | Requires identifying and structuring Q&A / tutorial content |
| Add OG image generation (`opengraph-image.tsx`) | Requires design decisions for image layout and content |
| Fix non-descriptive anchor text | Requires copywriting decisions |
| Reduce excessive `'use client'` boundaries | Requires understanding which components need interactivity and restructuring data flow |
| Restructure Client Component wrappers | Requires understanding component dependencies, may need new component hierarchy |
| Reduce nested Context Providers | Requires evaluating which providers are needed globally vs locally, possible state consolidation |
| Remove large inline JSON from pages | Requires deciding data source (API, build-time fetch, separate file) and restructuring |
| Remove heavy imports from `_app.tsx` | Requires evaluating alternatives and migration to lighter packages or dynamic imports |
| Optimize excessive dynamic imports | Requires evaluating bundle impact and user flows to decide which splits are valuable |
| Add `React.memo` to expensive context consumers | Requires profiling to identify truly expensive components and correct memo boundaries |

## Classification Algorithm

When classifying an issue from an agent's output, follow this order:

1. **Match the issue's Fix description** against the patterns in the matrix above
2. **If the fix generates content** (text, descriptions, structured data, titles) → `confirm-fix` at minimum
3. **If the fix involves creating a new file** from scratch with project-specific content → `manual`
4. **If the fix involves creating a new file** with a standard template (robots.ts, sitemap.ts) → `confirm-fix`
5. **If the fix adds a single known-value attribute** (rel, loading, lang, viewport) → `auto-fix`
6. **If the fix adds an attribute whose value must be inferred** (alt, width, height, dates) → `confirm-fix`
7. **If the fix replaces one component/API with another** → `confirm-fix`
8. **If the fix involves a policy decision** (bot access, rendering strategy) → `confirm-fix`
9. **If the fix requires restructuring or design decisions** → `manual`
10. **If uncertain**, default to `confirm-fix` (safer than auto-fix, more actionable than manual)

## Fix Application Rules

When applying fixes to files:

1. **Group fixes by file** — collect all fixes targeting the same file before applying
2. **Apply bottom-to-top** — within a file, apply fixes in reverse line order (highest line number first) to avoid line offset drift
3. **Verify before applying** — read the file and confirm the "Before" code from the issue matches the actual file content. If it doesn't match, mark the fix as "failed — code mismatch" and skip
4. **New files** — for fixes that create new files (llms.txt, robots.ts, sitemap.ts), use the Write tool. Verify the file doesn't already exist before writing
5. **One fix at a time** — apply each fix individually and verify the edit succeeded before moving to the next
6. **Preserve formatting** — match the existing file's indentation style (tabs vs spaces, indent width)
