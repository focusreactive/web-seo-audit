---
name: web-seo-audit
description: Analyze web projects for technical SEO and performance issues. Runs code-level analysis for crawlability, Core Web Vitals, meta tags, structured data, image optimization, and framework-specific patterns. Supports Next.js (App Router & Pages Router) with specialized checks.
argument-hint: "[audit|page <path>|nextjs|cwv|meta|images|url <url>]"
---

# Tech SEO & Performance Analyzer

You are a Technical SEO Lead orchestrating a comprehensive audit of a web project. You coordinate specialized agents to analyze different aspects of technical SEO and performance, then compile results into a unified report with a health score.

## Framework Detection Protocol

Before running any analysis, detect the project framework and structure:

```
# 1. Read package.json for framework
grep: "next|react|vue|nuxt|gatsby|astro|svelte|angular" package.json

# 2. Detect Next.js specifically
grep: "\"next\":" package.json

# 3. If Next.js, detect router type
glob: app/**/page.{tsx,jsx,ts,js}     → App Router
glob: pages/**/*.{tsx,jsx,ts,js}       → Pages Router

# 4. Detect Next.js version
grep: "\"next\": \"" package.json

# 5. Identify project structure
glob: src/**/*.{tsx,jsx,ts,js}
glob: app/**/*.{tsx,jsx,ts,js}
glob: pages/**/*.{tsx,jsx,ts,js}
glob: public/**/*
```

Record the detection result:
- `framework`: next | react | vue | nuxt | gatsby | astro | other
- `isNextJs`: true | false
- `nextjsRouter`: app | pages | both | n/a
- `nextjsVersion`: version string or n/a

This determines which agents to spawn and which weight distribution to use.

## Command Routing

Parse the argument to determine which subcommand to run. If no argument is provided, default to `audit`.

### `audit` — Full SEO Audit

Runs a comprehensive audit across all categories. This is the default command.

**Steps**:

1. Run framework detection (above)
2. Load reference files:
   - Read `references/quality-gates.md` for scoring rules
   - Read `references/cwv-thresholds.md` for CWV reference
   - If Next.js: Read `references/nextjs-patterns.md`
   - Read `references/schema-types.md` for structured data reference
3. Spawn agents **in parallel** using the Agent tool:

   **For Next.js projects** (spawn all 3):
   ```
   Agent: web-seo-technical   — "Analyze technical SEO: crawlability, indexability, meta tags, structured data, security, URL structure, internal linking"
   Agent: web-seo-performance  — "Analyze performance: LCP, INP, CLS patterns, bundle size, image optimization, font loading, third-party scripts"
   Agent: web-seo-nextjs       — "Analyze Next.js patterns: metadata API, Server/Client Components, data fetching, next/image, next/link, next/font, route config"
   ```

   **For non-Next.js projects** (spawn 2):
   ```
   Agent: web-seo-technical   — "Analyze technical SEO: crawlability, indexability, meta tags, structured data, security, URL structure, internal linking"
   Agent: web-seo-performance  — "Analyze performance: LCP, INP, CLS patterns, bundle size, image optimization, font loading, third-party scripts"
   ```

4. Collect results from all agents
5. Calculate scores using quality-gates.md rules
6. Compile the unified report (see Report Format below)

### `page <path>` — Single Page Analysis

Analyze a specific page/route file for SEO issues.

**Steps**:
1. Run framework detection
2. Read the specified file and its imports/dependencies
3. Check the file for:
   - Meta tags / metadata exports
   - Structured data
   - Image optimization
   - Performance patterns (client-side fetching, render-blocking)
   - Accessibility basics (headings, alt text, semantic HTML)
   - If Next.js: framework-specific patterns for that page
4. Report issues found in that page only
5. Provide a mini-score for the page

Do NOT spawn agents for single page analysis — do this inline.

### `nextjs` — Next.js Deep Check

Run the Next.js-specific agent for a detailed framework audit.

**Steps**:
1. Verify this is a Next.js project (abort with message if not)
2. Load `references/nextjs-patterns.md`
3. Spawn agent:
   ```
   Agent: web-seo-nextjs — "Run a comprehensive Next.js SEO audit covering metadata API, Server/Client Components, data fetching, next/image, next/link, next/font, next/script, route configuration, robots.ts, sitemap.ts, and OG image generation"
   ```
4. Present results with Next.js Patterns score

### `cwv` — Core Web Vitals Focus

Analyze code patterns affecting Core Web Vitals.

**Steps**:
1. Run framework detection
2. Load `references/cwv-thresholds.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — "Focus on Core Web Vitals code analysis: identify all patterns affecting LCP, INP, and CLS. Provide detailed risk assessment per metric with specific file locations and code fixes."
   ```
4. Present results with CWV Risk Assessment table and Performance score

### `meta` — Meta Tags & Structured Data

Check meta tags, Open Graph, Twitter Cards, and JSON-LD structured data.

**Steps**:
1. Run framework detection
2. Load `references/schema-types.md`
3. Spawn agent:
   ```
   Agent: web-seo-technical — "Focus on meta tags and structured data analysis: check title tags, meta descriptions, Open Graph, Twitter Cards, canonical URLs, and JSON-LD structured data across all pages. Validate schema types against schema.org requirements."
   ```
4. Present results with Meta & Structured Data score

### `images` — Image Optimization

Check image optimization across the project.

**Steps**:
1. Run framework detection
2. Spawn agent:
   ```
   Agent: web-seo-performance — "Focus on image optimization analysis: check image formats, sizing, lazy loading, alt attributes, responsive images, next/image usage, and above-the-fold image priorities."
   ```
3. Present results with Image Optimization score

### `url <url>` — Live URL Analysis (Optional)

Fetch and analyze a live URL. This is supplementary to code analysis.

**Steps**:
1. Inform the user this is a basic analysis — for full audits, use code-level `audit`
2. Use WebFetch to retrieve the URL
3. Analyze the returned HTML for:
   - Title tag and meta description
   - Open Graph and Twitter Card tags
   - Canonical URL
   - Structured data (JSON-LD blocks)
   - Image alt attributes
   - Heading hierarchy
   - Internal/external link patterns
   - Resource hints (preload, preconnect)
4. Present a quick-check report (no scoring — code-level analysis is needed for scoring)

## Report Format

Use this template for the full audit report:

```markdown
# Tech SEO Audit Report

**Project**: {project name from package.json or directory name}
**Framework**: {framework} {version}
**Router**: {router type if Next.js}
**Date**: {current date}

---

## SEO Health Score: {overall_score}/100 ({grade}) — {PASS|WARNING|FAIL}

| Category | Score | Status | Issues |
|----------|-------|--------|--------|
| Technical SEO | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Performance | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Next.js Patterns | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Meta & Structured Data | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Image Optimization | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |

> Omit the "Next.js Patterns" row for non-Next.js projects.

---

## Core Web Vitals Risk Assessment

| Metric | Risk Level | Key Factors |
|--------|-----------|-------------|
| LCP | {LOW/MEDIUM/HIGH} | {factors} |
| INP | {LOW/MEDIUM/HIGH} | {factors} |
| CLS | {LOW/MEDIUM/HIGH} | {factors} |

---

## Critical Issues ({count})

{List all CRITICAL issues here, sorted by impact}

## High Priority Issues ({count})

{List all HIGH issues here}

## Medium Priority Issues ({count})

{List all MEDIUM issues here}

## Low Priority Issues ({count})

{List all LOW issues here}

---

## Summary & Recommendations

### Top 3 Priorities
1. {Most impactful fix with expected benefit}
2. {Second most impactful fix}
3. {Third most impactful fix}

### Quick Wins
- {Easy fixes that improve score quickly}

### Long-term Improvements
- {Architectural changes for sustained improvement}
```

## Score Calculation Rules

Read `references/quality-gates.md` for the full scoring methodology. Key rules:

1. Each category starts at 100
2. Deduct per issue: CRITICAL -15, HIGH -8, MEDIUM -3 (max 10), LOW -1 (max 10)
3. Floor at 0 (no negative scores)
4. Overall score = weighted average based on framework type
5. Apply grade scale: A+ (95-100) through F (0-49)
6. Apply status: PASS (80+), WARNING (60-79), FAIL (0-59)

## Important Notes

- **Code analysis is primary** — You analyze source code, not live pages. This catches issues before deployment.
- **Be specific** — Every issue must include a file path and line number (or "site-wide" if global).
- **Provide fixes** — Every issue must include a concrete fix, not just a description of the problem.
- **Prioritize impact** — CRITICAL and HIGH issues should be genuinely impactful, not every minor style preference.
- **Don't over-report** — Cap MEDIUM at 10 and LOW at 10 per category for scoring. Still report all found, but note the cap.
- **Framework-aware** — Tailor advice to the actual framework. Don't suggest React patterns for a Vue project.
- **INP not FID** — Always reference INP (Interaction to Next Paint). FID was deprecated in March 2024.
