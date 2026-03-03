# web-seo-audit

**Scan your web project for SEO issues. Get a scored report. Fix and repeat.**

A Claude Code plugin that performs code-level SEO analysis — no browser, no Lighthouse, no live URLs needed. It reads your source code, detects framework patterns, and produces a scored report across 5 categories with specific file locations and fixes.

```
SEO Health Score: 72/100 (C+) — WARNING

| Category             | Score    | Status  | Issues           |
|----------------------|----------|---------|------------------|
| Technical SEO        | 77/100   | WARNING | 0C 1H 4M 3L     |
| Performance          | 65/100   | WARNING | 1C 1H 3M 2L     |
| Next.js Patterns     | 70/100   | WARNING | 1C 0H 5M 2L     |
| Meta & Structured    | 84/100   | PASS    | 0C 2H 0M 0L     |
| Image Optimization   | 62/100   | WARNING | 0C 2H 4M 1L     |
```

## What it does

1. **Detects your framework** — Next.js (App Router, Pages Router), React, Vue, Nuxt, Astro, and more
2. **Spawns 3 specialized agents in parallel** — technical SEO, performance/CWV, and framework-specific checks
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
| `/web-seo-audit` | Full audit — all 5 categories, scored report |
| `/web-seo-audit nextjs` | Next.js deep check — metadata API, Server Components, data fetching |
| `/web-seo-audit cwv` | Core Web Vitals focus — LCP, INP, CLS risk analysis |
| `/web-seo-audit meta` | Meta tags & structured data — title, OG, Twitter, JSON-LD |
| `/web-seo-audit images` | Image optimization — format, sizing, lazy loading, alt text |
| `/web-seo-audit page <path>` | Single page analysis — inline check, no agents spawned |
| `/web-seo-audit url <url>` | Live URL quick-check — supplementary to code analysis |

## What it checks

| Category | Checks | Agent |
|----------|--------|-------|
| **Technical SEO** | robots.txt, sitemap, canonical URLs, meta robots, URL structure, internal linking, security headers, mobile optimization, i18n | `web-seo-technical` |
| **Performance** | LCP patterns, INP risk, CLS prevention, bundle size, font loading, third-party scripts, caching, compression | `web-seo-performance` |
| **Next.js Patterns** | Metadata API, Server/Client Components, data fetching, `next/image`, `next/link`, `next/font`, `next/script`, route config, `robots.ts`, `sitemap.ts`, OG image generation, Suspense | `web-seo-nextjs` |
| **Meta & Structured Data** | Title tags, meta descriptions, Open Graph, Twitter Cards, canonical URLs, JSON-LD validation (10 schema types) | `web-seo-technical` |
| **Image Optimization** | Format (WebP/AVIF), dimensions, lazy loading, alt attributes, responsive images, `priority` prop | `web-seo-performance` |

## Scored output

Every audit produces a health score using a transparent methodology:

**Scoring**: Each category starts at 100. Issues deduct points: CRITICAL -15, HIGH -8, MEDIUM -3 (max 10), LOW -1 (max 10). Floor at 0.

**Grades**: A+ (95-100), A (90-94), B+ (85-89), B (80-84), C+ (75-79), C (70-74), D+ (65-69), D (60-64), E (50-59), F (0-49)

**Status**: PASS (80+), WARNING (60-79), FAIL (0-59)

**Weights (Next.js)**: Technical SEO 25%, Performance 25%, Next.js Patterns 20%, Meta & Structured Data 20%, Image Optimization 10%

**Weights (other frameworks)**: Technical SEO 30%, Performance 30%, Meta & Structured Data 25%, Image Optimization 15%

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
         ├──────────────────────────────┐
         │                              │
         ▼                              ▼
┌─────────────────┐  ┌──────────────────────┐
│ web-seo-technical│  │ web-seo-performance  │
│ - Crawlability   │  │ - LCP / INP / CLS    │
│ - Meta tags      │  │ - Bundle size        │
│ - Structured data│  │ - Image optimization │
│ - Security       │  │ - Font loading       │
│ - Internal links │  │ - Third-party scripts│
└─────────────────┘  └──────────────────────┘
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
  ├── quality-gates.md    — Scoring rules & weights
  ├── cwv-thresholds.md   — Core Web Vitals reference
  ├── nextjs-patterns.md  — Next.js detection rules
  └── schema-types.md     — JSON-LD validation (10 types)
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
│           └── schema-types.md  # JSON-LD validation
├── agents/
│   ├── web-seo-technical.md     # Technical SEO agent
│   ├── web-seo-performance.md   # Performance agent
│   └── web-seo-nextjs.md       # Next.js agent
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
