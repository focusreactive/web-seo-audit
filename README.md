# web-seo-audit

**Scan your web project for SEO issues. Get a scored report. Fix and repeat.**

A Claude Code plugin that performs code-level SEO analysis — no browser, no Lighthouse, no live URLs needed. It reads your source code, detects framework patterns, and produces a scored report across 6 categories with specific file locations and fixes.

```
SEO Health Score: 71/100 (C) — WARNING

| Category             | Score    | Status  | Issues           |
|----------------------|----------|---------|------------------|
| Technical SEO        | 77/100   | WARNING | 0C 1H 4M 3L     |
| Performance          | 65/100   | WARNING | 1C 1H 3M 2L     |
| Next.js Patterns     | 70/100   | WARNING | 1C 0H 5M 2L     |
| Meta & Structured    | 84/100   | PASS    | 0C 2H 0M 0L     |
| Image Optimization   | 62/100   | WARNING | 0C 2H 4M 1L     |
| AI Search Readiness  | 55/100   | FAIL    | 1C 1H 3M 2L     |
```

## What it does

1. **Detects your framework** — Next.js (App Router, Pages Router), React, Vue, Nuxt, Astro, and more
2. **Spawns up to 4 specialized agents in parallel** — technical SEO, performance/CWV, AI search readiness, and framework-specific checks
3. **Produces a scored report** — 0-100 health score per category, letter grade (A+ to F), PASS/WARNING/FAIL status, with every issue tied to a file path and a concrete fix

## Install

### Plugin install (recommended)

```bash
# Add the marketplace
/plugin marketplace add focusreactive/web-seo-audit

# Install the plugin
/plugin install web-seo-audit@focusreactive-seo-tools
```

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/focusreactive/web-seo-audit/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/focusreactive/web-seo-audit.git
cd web-seo-audit && ./install.sh
```

## Usage

Open Claude Code in any web project and run:

| Command | What it does |
|---------|-------------|
| `/web-seo-audit` | Full audit — all 6 categories, scored report |
| `/web-seo-audit fix` | Audit, auto-fix issues, re-audit — iterative cycle until target score |
| `/web-seo-audit fix --target 90` | Fix cycle with custom target score (default: 80) |
| `/web-seo-audit nextjs` | Next.js deep check — metadata API, Server Components, data fetching |
| `/web-seo-audit cwv` | Core Web Vitals focus — LCP, INP, CLS risk analysis |
| `/web-seo-audit meta` | Meta tags & structured data — title, OG, Twitter, JSON-LD |
| `/web-seo-audit images` | Image optimization — format, sizing, lazy loading, alt text |
| `/web-seo-audit aeo` | AI search readiness — llms.txt, AI crawlers, entity data, content structure |
| `/web-seo-audit page <path>` | Single page analysis — inline check, no agents spawned |
| `/web-seo-audit url <url>` | Live URL quick-check — surface-level scored report from rendered HTML |

## What it checks

| Category | Checks | Agent |
|----------|--------|-------|
| **Technical SEO** | robots.txt, sitemap, canonical URLs, meta robots, URL structure, internal linking, security headers, mobile optimization, i18n | `web-seo-technical` |
| **Performance** | LCP patterns, INP risk, CLS prevention, bundle size, font loading, third-party scripts, caching, compression | `web-seo-performance` |
| **Next.js Patterns** | Metadata API, Server/Client Components, data fetching, `next/image`, `next/link`, `next/font`, `next/script`, route config, `robots.ts`, `sitemap.ts`, OG image generation, Suspense | `web-seo-nextjs` |
| **Meta & Structured Data** | Title tags, meta descriptions, Open Graph, Twitter Cards, canonical URLs, JSON-LD validation (10 schema types) | `web-seo-technical` |
| **Image Optimization** | Format (WebP/AVIF), dimensions, lazy loading, alt attributes, responsive images, `priority` prop | `web-seo-performance` |
| **AI Search Readiness** | llms.txt, AI crawler management (8 bots), entity-optimized structured data, content structure for AI extraction, AI crawlability signals | `web-seo-aeo` |

## Fix cycle

The `fix` subcommand automates the audit-fix-verify loop:

1. **Audit** — Runs the full audit to identify all issues
2. **Classify** — Buckets issues into auto-fix (safe mechanical changes), confirm-fix (ask first), and manual (report only)
3. **Fix plan** — Shows what will be changed and estimated score improvement
4. **Apply** — Auto-fixes are applied directly; confirm-fixes are shown for approval
5. **Re-audit** — Runs the full audit again to verify fixes and catch regressions
6. **Repeat** — Loops until the target score is met, max iterations (3) reached, or no progress is made

**Auto-fixable** examples: create `llms.txt`, add `alt`/`width`/`height` attributes, add JSON-LD, add `preconnect`, add AI bot rules to `robots.txt`, add `font-display: swap`, add metadata exports.

**Confirm-fix** examples: replace `<img>` with `next/image`, remove unnecessary `'use client'`, add security headers, add `<Suspense>` boundaries.

**Manual** (reported but not attempted): convert SPA to SSR, restructure components, create author pages, add `generateStaticParams`.

## Scored output

Every audit produces a health score using a transparent methodology:

**Scoring**: Each category starts at 100. Issues deduct points: CRITICAL -15, HIGH -8, MEDIUM -3 (max 10), LOW -1 (max 10). Floor at 0.

**Grades**: A+ (95-100), A (90-94), B+ (85-89), B (80-84), C+ (75-79), C (70-74), D+ (65-69), D (60-64), E (50-59), F (0-49)

**Status**: PASS (80+), WARNING (60-79), FAIL (0-59)

**Weights (Next.js)**: Technical SEO 22%, Performance 22%, Next.js Patterns 18%, Meta & Structured Data 18%, Image Optimization 10%, AI Search Readiness 10%

**Weights (other frameworks)**: Technical SEO 27%, Performance 27%, Meta & Structured Data 23%, Image Optimization 13%, AI Search Readiness 10%

Every issue includes: priority level, file path with line number, problem description, impact explanation, and a concrete code fix.

See [`examples/sample-output.md`](examples/sample-output.md) for a full example report.

## Architecture

```
/web-seo-audit
       │
       ▼
┌─────────────────────────┐
│  SKILL.md (orchestrator) │
│  - Detects framework     │
│  - Loads reference files │
│  - Routes commands       │
│  - Spawns agents         │
│  - Compiles final report │
└────────┬────────────────┘
         │ spawns in parallel
         ├──────────────────────────────┬──────────────────────┐
         │                              │                      │
         ▼                              ▼                      ▼
┌─────────────────┐  ┌──────────────────────┐  ┌─────────────────┐
│ web-seo-technical│  │ web-seo-performance  │  │ web-seo-aeo     │
│ - Crawlability   │  │ - LCP / INP / CLS    │  │ - llms.txt      │
│ - Meta tags      │  │ - Bundle size        │  │ - AI crawlers   │
│ - Structured data│  │ - Image optimization │  │ - Entity data   │
│ - Security       │  │ - Font loading       │  │ - Content struct │
│ - Internal links │  │ - Third-party scripts│  │ - AI crawlability│
└─────────────────┘  └──────────────────────┘  └─────────────────┘
         │
         ▼ (Next.js projects only)
┌─────────────────┐
│ web-seo-nextjs   │
│ - Metadata API   │
│ - Server/Client  │
│ - Data fetching  │
│ - next/* APIs    │
│ - Route config   │
└─────────────────┘

Reference files (loaded by orchestrator):
  ├── quality-gates.md       — Scoring rules & weights
  ├── cwv-thresholds.md      — Core Web Vitals reference
  ├── nextjs-patterns.md     — Next.js detection rules
  ├── schema-types.md        — JSON-LD validation (10 types)
  ├── aeo-patterns.md        — AI search readiness patterns
  └── fix-classification.md  — Fix cycle classification rules
```

## Framework support

| Framework | Support | Details |
|-----------|---------|---------|
| **Next.js** (App Router) | Full | Dedicated agent, 12 check categories, metadata API, Server Components |
| **Next.js** (Pages Router) | Full | `getStaticProps`/`getServerSideProps`, `next/head`, `_document`, `_app` |
| **React** | Core | Technical SEO + Performance + Meta + Images (no framework-specific agent) |
| **Vue / Nuxt** | Core | Same core checks, framework-aware advice |
| **Astro / Gatsby / Svelte** | Core | Same core checks, framework-aware advice |
| **Static HTML** | Core | All checks except framework-specific patterns |

## How it works

This tool performs **static code analysis** — it reads your source files, configuration, and dependencies to identify SEO issues. It does not:

- Run a browser or headless Chrome
- Fetch live URLs (except the optional `url` command)
- Require a running dev server
- Need network access to your site

This means it catches issues **before deployment** — in your IDE, during code review, or in CI.

## Uninstall

### Plugin uninstall

```
/plugin uninstall web-seo-audit@focusreactive-seo-tools
```

### Manual uninstall

```bash
# From clone
./uninstall.sh

# Or one-liner
curl -fsSL https://raw.githubusercontent.com/focusreactive/web-seo-audit/main/uninstall.sh | bash
```

## Project structure

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
│           └── fix-classification.md # Fix cycle classification rules
├── agents/
│   ├── web-seo-technical.md     # Technical SEO agent
│   ├── web-seo-performance.md   # Performance agent
│   ├── web-seo-nextjs.md       # Next.js agent
│   └── web-seo-aeo.md          # AI search readiness agent
├── examples/
│   └── sample-output.md        # Example audit report
├── install.sh                   # Manual installer
├── uninstall.sh                 # Manual uninstaller
├── LICENSE                      # MIT
└── README.md
```

## License

MIT

## Contributing

1. Fork this repo
2. Make changes to skills, agents, or reference files
3. Test by running `./install.sh` and auditing a project
4. Open a PR with a description of what changed and why
