# web-seo-audit

**Your site's SEO breaks in code, not in production. Find it there.**

Most SEO tools audit a live URL after you've shipped. This plugin reads your source code *before* you deploy — catching missing meta tags, broken structured data, image issues, and AI search gaps while you're still in your editor.

A Claude Code plugin. No browser, no dev server needed. Optionally add a URL to any command for live website analysis — CrUX field data, Lighthouse scores, and rendered HTML checks — correlated with code findings.

```
SEO Health Score: 88/100 (B+) — PASS

| Category             | Score    | Status  | Issues       |
|----------------------|----------|---------|--------------|
| Technical SEO        | 91/100   | PASS    | 0C 1H 0M 1L |
| Performance          | 90/100   | PASS    | 0C 0H 3M 1L |
| Next.js Patterns     | 96/100   | PASS    | 0C 0H 1M 1L |
| Meta & Structured    | 85/100   | PASS    | 0C 1H 2M 1L |
| Image Optimization   | 80/100   | PASS    | 0C 2H 1M 1L |
| AI Search Readiness  | 77/100   | WARNING | 0C 1H 4M 3L |
```

Every issue comes with a file path, an explanation of why it matters, and a code fix you can apply.

## Why not Lighthouse?

Lighthouse audits a rendered page. This plugin audits your source code. Different inputs, different catches.

| | Lighthouse | web-seo-audit |
|---|---|---|
| **Input** | Live URL in a browser | Source code in your editor |
| **When** | After deployment | Before deployment |
| **Finds** | Runtime perf, paint metrics, basic SEO | Code patterns, framework misuse, missing files, structured data gaps |
| **AI search** | No | Yes — llms.txt, AI crawler rules, entity data, content structure |
| **Fix workflow** | Copy results, go find the code | Points to the exact file:line, offers auto-fix |
| **Framework awareness** | No | Next.js metadata API, Server Components, `next/image`, route config |

They're complementary. Lighthouse tells you what's slow. This tells you *why* it's slow and where to fix it.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/focusreactive/web-seo-audit/main/install.sh | bash
```

Then open Claude Code in any web project:

```
/web-seo-audit
```

<details>
<summary>Install from clone</summary>

```bash
git clone https://github.com/focusreactive/web-seo-audit.git
cd web-seo-audit && ./install.sh
```

</details>

## What you get

Every issue includes severity, file location, business impact, a concrete fix, and whether it can be auto-fixed:

```
[HIGH] Meta & Structured Data: No JSON-LD structured data on homepage

  Location:    app/[lang]/page.tsx
  Problem:     Homepage has no JSON-LD structured data. Missing Organization,
               WebSite, and BreadcrumbList schemas. Search engines and AI
               systems have no structured way to understand the business entity.
  Impact:      No rich results in Google (sitelinks search box, logo, company
               info). AI search engines can't extract entity data for answers.
  Fixability:  auto-fix

  Fix:
  ┌─────────────────────────────────────────────────────────────
  │ <script type="application/ld+json">
  │ {
  │   "@context": "https://schema.org",
  │   "@type": "Organization",
  │   "name": "Your Company",
  │   "url": "https://example.com",
  │   "logo": "https://example.com/logo.svg",
  │   "sameAs": [
  │     "https://www.linkedin.com/company/your-company",
  │     "https://www.youtube.com/@your-company"
  │   ]
  │ }
  │ </script>
  └─────────────────────────────────────────────────────────────
```

```
[HIGH] Image Optimization: 9+ images missing alt attributes

  Location:    components/CaseStudyCard.tsx, components/Hero.tsx, +6 more
  Problem:     Case study images, hero banner, and background images are all
               missing alt attributes. Screen readers skip them. Search engines
               can't index the visual content.
  Impact:      Image search traffic lost. Accessibility failure (WCAG 1.1.1).
               AI crawlers can't describe visual content.
  Fixability:  confirm-fix

  Fix:
  ┌─────────────────────────────────────────────────────────────
  │ // Before
  │ <Image src={caseStudy.image} fill />
  │
  │ // After
  │ <Image
  │   src={caseStudy.image}
  │   fill
  │   alt="Smart parking management system in city center"
  │ />
  └─────────────────────────────────────────────────────────────
```

## AI search readiness

This is the part no other tool covers.

The `aeo` command checks how visible your site is to AI-powered search engines — ChatGPT, Perplexity, Claude, Gemini. These systems don't just crawl your pages; they need structured signals to extract, attribute, and cite your content.

```
/web-seo-audit aeo
```

```
AI Search Readiness: 77/100 — WARNING
Issues: 0C 1H 4M 3L

[HIGH] No llms.txt file
  Affects:   Training bots + Retrieval bots
  Problem:   No llms.txt at /llms.txt. AI systems have no structured way
             to discover site content, key pages, or documentation.
  Fix:       Create public/llms.txt with site description and key pages.

[MEDIUM] No explicit AI bot rules in robots.txt
  Affects:   Both — training and retrieval bots
  Problem:   robots.txt has only "User-agent: *". No explicit rules for
             ChatGPT-User, PerplexityBot, ClaudeBot, or Applebot.
  Fix:       Add explicit Allow rules for retrieval bots. Consider blocking
             GPTBot (training) while allowing ChatGPT-User (retrieval).

[MEDIUM] No <main> semantic element
  Affects:   Retrieval bots — can't identify primary content area
  Problem:   Page content wrapped in <div> without a <main> landmark.
             AI crawlers use semantic landmarks to extract primary content.
  Fix:       Wrap page content in <main> element in root layout.

[MEDIUM] No entity-optimized structured data
  Affects:   Both — AI can't verify entity identity
  Problem:   No Organization schema with sameAs, @id, or mainEntityOfPage.
             AI search engines can't confidently attribute content.
  Fix:       Add Organization JSON-LD with sameAs links.

[MEDIUM] No FAQ/HowTo schema on relevant content
  Affects:   Retrieval bots — structured Q&A improves AI extraction
  Fix:       Add FAQPage JSON-LD to pages with common questions.

[LOW] No question-format headings
  Problem:   Headings use statements ("Making cities more livable") instead
             of questions ("How does smart parking reduce congestion?").
             AI search matches user queries to headings.

[LOW] Training bots not explicitly managed
  Problem:   No Disallow rules for GPTBot, Google-Extended, CCBot.
             Site content may be used for model training without opt-out.

[LOW] No speakable markup
  Problem:   No speakable structured data for text-to-speech or
             voice assistant responses.
```

What it checks: llms.txt presence, AI crawler management (8 bots), entity-optimized structured data, semantic content structure, training vs. retrieval bot rules, speakable markup.

## Fix cycle

`/web-seo-audit fix` doesn't just report — it fixes. Audit, classify, fix, re-audit, repeat.

```
Fix Plan

| Type                       | Count | Estimated Impact |
|----------------------------|-------|------------------|
| Auto-fix (apply directly)  | 6     | ~14 points       |
| Confirm-fix (ask first)    | 4     | ~8 points        |
| Manual (report only)       | 2     | ~4 points        |

Current score: 88/100 → Estimated after fixes: ~96/100
```

**Auto-fix** (applied directly): create `llms.txt`, add JSON-LD, add `preconnect`, add AI bot rules to `robots.txt`, add `<main>` landmark, add og:image dimensions.

**Confirm-fix** (shown for approval): add alt text to images, add width/height to images, route images through `next/image`, add `twitter:site`.

**Manual** (reported only): restructure components, create author pages, add `generateStaticParams`.

After fixes are applied, it re-audits and shows the delta:

```
Fix Cycle 1 Results

| Category             | Before   | After    | Change |
|----------------------|----------|----------|--------|
| Technical SEO        | 91/100   | 100/100  | +9     |
| Performance          | 90/100   | 96/100   | +6     |
| Next.js Patterns     | 96/100   | 100/100  | +4     |
| Meta & Structured    | 85/100   | 100/100  | +15    |
| Image Optimization   | 80/100   | 96/100   | +16    |
| AI Search Readiness  | 77/100   | 92/100   | +15    |
| **Overall**          | **88/100** | **97/100** | **+9** |

Fixes applied: 10 | Failed: 0 | Skipped: 2
```

## Commands

Any command accepts an optional `<url>` at the end — when provided, live website analysis is run alongside code analysis and results are correlated (Confirmed / Hidden / Latent Risk).

| Command                          | What it does                                                    |
| -------------------------------- | --------------------------------------------------------------- |
| `/web-seo-audit`                 | Full audit — all 6 categories, scored report                    |
| `/web-seo-audit fix`             | Audit, auto-fix issues, re-audit — iterative cycle              |
| `/web-seo-audit fix --target 90` | Fix cycle with custom target score (default: 80)                |
| `/web-seo-audit nextjs`          | Next.js deep check — metadata API, Server Components            |
| `/web-seo-audit cwv`             | Core Web Vitals focus — LCP, INP, CLS risk analysis             |
| `/web-seo-audit meta`            | Meta tags & structured data — title, OG, Twitter, JSON-LD       |
| `/web-seo-audit images`          | Image optimization — format, sizing, lazy loading, alt text     |
| `/web-seo-audit aeo`             | AI search readiness — llms.txt, AI crawlers, entity data        |
| `/web-seo-audit perf`            | Performance analysis — CWV patterns, bundle size, loading       |
| `/web-seo-audit page <path>`     | Single page analysis — inline check, no agents spawned          |

Example with URL: `/web-seo-audit cwv https://example.com` — code-level CWV analysis + CrUX field data correlation.

## What it checks

6 categories, 3-4 specialized agents running in parallel (framework agent only spawned for supported meta-frameworks). Checks are filtered by detected framework and version — agents only run relevant checks. Every command accepts an optional URL for live website analysis correlated with code findings:

| Category                   | Checks                                                                                                                                                                               | With URL adds                          | Agent                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------- | --------------------- |
| **Technical SEO**          | robots.txt, sitemap, canonical URLs, meta robots, URL structure, internal linking, security headers, mobile optimization, i18n                                                       | Live HTML verification                 | `web-seo-technical`   |
| **Performance**            | LCP patterns, INP risk, CLS prevention, bundle size, font loading, third-party scripts, caching, compression                                                                        | CrUX field data + Lighthouse scores    | `web-seo-performance` |
| **{Framework} Patterns**   | Framework-specific checks (e.g., Next.js: Metadata API, Server/Client Components, `next/*` APIs; Nuxt: `useHead()`, `NuxtLink`; etc.)                                               | Response headers, rendering checks     | `web-seo-framework`   |
| **Meta & Structured Data** | Title tags, meta descriptions, Open Graph, Twitter Cards, canonical URLs, JSON-LD validation (10 schema types)                                                                       | Rendered meta tag verification         | `web-seo-technical`   |
| **Image Optimization**     | Format (WebP/AVIF), dimensions, lazy loading, alt attributes, responsive images, `priority` prop                                                                                     | Rendered image attribute checks        | `web-seo-performance` |
| **AI Search Readiness**    | llms.txt, AI crawler management (8 bots), entity-optimized structured data, content structure for AI extraction, AI crawlability signals                                             | Live robots.txt, llms.txt, HTML checks | `web-seo-aeo`         |

## Framework support

| Framework                   | Support | Details                                                                   |
| --------------------------- | ------- | ------------------------------------------------------------------------- |
| **Next.js** (App Router)    | Full    | Dedicated agent, version-gated checks (13.2+ metadata, 15+ fetch defaults), Server Components |
| **Next.js** (Pages Router)  | Full    | `getStaticProps`/`getServerSideProps`, `next/head`, `_document`, `_app`   |
| **Nuxt** 2.x / 3+          | Full    | Dedicated agent, `useHead()`, `NuxtLink`, `NuxtImg`, Nitro prerendering  |
| **Gatsby** 3+ / 4+         | Full    | Dedicated agent, `gatsby-plugin-image`, Head API, GraphQL SEO             |
| **Astro** 3+ / 4+          | Full    | Dedicated agent, island architecture, `<Image>`, content collections      |
| **React**                   | Core    | Technical SEO + Performance + Meta + Images (no framework agent)          |
| **Vue / Angular / Svelte**  | Core    | Same core checks, framework-aware advice                                  |
| **Static HTML**             | Core    | All checks except framework-specific patterns                             |

## Scoring

Each category starts at 100. Issues deduct points: CRITICAL -15, HIGH -8, MEDIUM -3, LOW -1. Overall score is weighted by category.

| Grade | Score | Status |
|-------|-------|--------|
| A+ | 95-100 | PASS |
| A | 90-94 | PASS |
| B+ | 85-89 | PASS |
| B | 80-84 | PASS |
| C+ | 75-79 | WARNING |
| C | 70-74 | WARNING |
| D | 60-69 | WARNING |
| E | 50-59 | FAIL |
| F | 0-49 | FAIL |

See [`examples/sample-output.md`](examples/sample-output.md) for a full report.

<details>
<summary>Architecture</summary>

```
/web-seo-audit
       │
       ▼
┌─────────────────────-────┐
│  SKILL.md (orchestrator) │
│  - Detects framework     │
│  - Loads reference files │
│  - Routes commands       │
│  - Spawns agents         │
│  - Compiles final report │
└────────┬─────────────-───┘
         │ spawns in parallel
         ├──────────────────────────────┬──────────────────────┐
         │                              │                      │
         ▼                              ▼                      ▼
┌───────────────-──┐  ┌──────────────────────┐  ┌──────────────-───┐
│ web-seo-technical│  │ web-seo-performance  │  │ web-seo-aeo      │
│ - Crawlability   │  │ - LCP / INP / CLS    │  │ - llms.txt       │
│ - Meta tags      │  │ - Bundle size        │  │ - AI crawlers    │
│ - Structured data│  │ - Image optimization │  │ - Entity data    │
│ - Security       │  │ - Font loading       │  │ - Content struct │
│ - Internal links │  │ - Third-party scripts│  │ - AI crawlability│
└────────────────-─┘  └──────────────────────┘  └───────────────-──┘
         │
         ▼ (Next.js / Nuxt / Gatsby / Astro only)
┌──────────────────────┐
│ web-seo-framework    │
│ - Framework APIs     │
│ - Version-gated      │
│ - Router-specific    │
│ - Config analysis    │
│ - Antipatterns       │
└──────────────────────┘
```

</details>

<details>
<summary>Project structure</summary>

```
web-seo-audit/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace catalog
├── skills/
│   └── web-seo-audit/
│       ├── SKILL.md             # Orchestrator skill
│       └── references/
│           ├── quality-gates.md # Scoring methodology
│           ├── cwv-thresholds.md# CWV thresholds & patterns
│           ├── nextjs-patterns.md# Next.js detection rules
│           ├── schema-types.md  # JSON-LD validation
│           ├── aeo-patterns.md  # AI search readiness patterns
│           ├── fix-classification.md # Fix cycle classification rules
│           └── framework-checks.md # Framework-conditional check registry
├── agents/
│   ├── web-seo-technical.md     # Technical SEO agent
│   ├── web-seo-performance.md   # Performance agent
│   ├── web-seo-framework.md     # Framework-specific agent (Next.js/Nuxt/Gatsby/Astro)
│   └── web-seo-aeo.md          # AI search readiness agent
├── examples/
│   └── sample-output.md        # Example audit report
├── install.sh                   # Manual installer
├── uninstall.sh                 # Manual uninstaller
├── LICENSE                      # MIT
└── README.md
```

</details>

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/focusreactive/web-seo-audit/main/uninstall.sh | bash
```

## License

MIT

## Contributing

1. Fork this repo
2. Make changes to skills, agents, or reference files
3. Test by running `./install.sh` and auditing a project
4. Open a PR with a description of what changed and why
