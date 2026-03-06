# Quality Gates & Scoring System

## Overview

This reference defines the scoring methodology for tech SEO audits. Each audit produces a 0-100 health score per category, combined into an overall weighted score.

## Weight Distribution

### Projects With Framework Agent (Next.js, Nuxt, Gatsby, Astro)

| Category | Weight | Agent |
|----------|--------|-------|
| Technical SEO | 22% | web-seo-technical |
| Performance | 22% | web-seo-performance |
| {Framework} Patterns | 18% | web-seo-framework |
| Meta & Structured Data | 18% | web-seo-technical |
| Image Optimization | 10% | web-seo-performance |
| AI Search Readiness | 10% | web-seo-aeo |

### Projects Without Framework Agent (React, Vue, Angular, Svelte, static HTML)

| Category | Weight | Agent |
|----------|--------|-------|
| Technical SEO | 27% | web-seo-technical |
| Performance | 27% | web-seo-performance |
| Meta & Structured Data | 23% | web-seo-technical |
| Image Optimization | 13% | web-seo-performance |
| AI Search Readiness | 10% | web-seo-aeo |

## Deduction Rules

Each category starts at 100. Issues deduct points based on priority:

| Priority | Deduction | Max Deductions | Description |
|----------|-----------|----------------|-------------|
| CRITICAL | -15 | Unlimited | Blocks indexing, causes major CWV failure, security vulnerability |
| HIGH | -8 | Unlimited | Significantly harms rankings or user experience |
| MEDIUM | -3 | Max 10 issues counted | Moderate impact, should fix but not urgent |
| LOW | -1 | Max 10 issues counted | Minor improvements, best practices |

### Deduction Scope

**Per-template, not per-instance**: Deduct once per unique page template/type, not once per page instance. For example:
- "Blog posts missing Article schema" = 1 HIGH deduction (not N deductions for N blog posts)
- "Product pages missing Product schema" = 1 HIGH deduction
- "Homepage missing Organization schema" = 1 HIGH deduction

This prevents scores from being dominated by content volume rather than architectural gaps.

### MEDIUM/LOW Issue Prioritization

When a category has more than 10 MEDIUM (or LOW) issues, apply deductions for the 10 with the highest impact. Prioritize by:
1. Issues affecting more pages/templates first
2. Issues with higher confidence first
3. Issues with `auto-fix` or `confirm-fix` fixability first (actionable issues matter more)

Report ALL found issues for transparency, but note which 10 count toward the score.

### Compound Penalty

If a page template has zero SEO setup (no title, no description, no OG, no structured data, no canonical), report as a single CRITICAL (-15) "No SEO configuration on {page type}" rather than 5+ individual HIGH/MEDIUM issues. This avoids over-counting and better reflects the severity of a completely unconfigured page. The individual missing items should still be listed as sub-points within the finding for fix guidance.

### Deduction Examples

**CRITICAL (-15 each)**
- `noindex` on pages that should be indexed
- Missing or broken canonical URLs on key pages
- Render-blocking resources preventing LCP under 4s
- No HTTPS or mixed content on production
- Missing viewport meta tag
- JavaScript-only rendering with no SSR/SSG (does NOT apply to SSGs like Eleventy, Hugo, Gatsby, Astro — they are pre-rendered by definition)
- Redirect loops (A→B→A or longer cycles) — blocks crawling entirely

**HIGH (-8 each)**
- Missing `<title>` or `<meta description>` on important pages
- Duplicate title tags across multiple pages
- Images without `width`/`height` causing CLS > 0.25
- No structured data on content pages
- Bundle size > 500KB for initial load
- Missing `alt` attributes on meaningful images
- No sitemap.xml or robots.txt
- Missing H1 element on a page
- Redirect chains > 2 hops (A→B→C→D)
- Route depth > 4 path segments from root
- Zero server-rendered content on a page (client component wrapper only)
- Hash-based SPA routing (`/#/`) — search engines may not crawl fragment URLs
- Missing About page (no trust signal for E-E-A-T)
- Missing author information on YMYL content pages
- Excessive `'use client'` boundaries (>60% client components) — Next.js v13+ App Router only
- Layout-level `fetch()` without caching in App Router — Next.js v13+ App Router only
- Dynamic imports for above-the-fold components (Hero, Header, Nav) — Next.js any version
- \>5 nested Context Providers in root layout / `_app` — Next.js any version
- Heavy library imports in `_app.tsx` (moment, lodash, MUI, antd) — Next.js Pages Router only

**MEDIUM (-3 each, max 10)**
- Title tag too long (> 60 chars) or too short (< 30 chars)
- Meta description too long (> 160 chars) or too short (< 70 chars)
- Non-descriptive anchor text on internal links
- Images not using modern formats (WebP/AVIF)
- Missing Open Graph or Twitter Card meta tags
- Fonts not preloaded or using `font-display: swap`
- Non-semantic heading hierarchy (skipping levels)
- Multiple H1 elements on a single page
- Duplicate meta descriptions across pages
- 2-hop redirect chains (A→B→C) — consolidation recommended
- Redirect using 302 (temporary) when 301 (permanent) is appropriate
- Route depth > 3 path segments from root
- Minimal server-rendered content (all visible content loaded client-side)
- Missing pagination markup (`rel="next/prev"`) on paginated content
- Missing Contact page or Privacy Policy
- Missing author information on non-YMYL content pages
- Excessively long URL paths (>100 characters)
- Excessive `'use client'` boundaries (40-60% client components) — Next.js v13+ App Router only
- Barrel file re-exports in index files imported by Server Components — Next.js v13+ App Router only
- Client Component wrapping Server Components with only `{children}` — Next.js v13+ App Router only
- \>10 dynamic imports project-wide — Next.js any version
- 3-5 nested Context Providers in root layout / `_app` — Next.js any version
- Large inline JSON data in page components — Next.js any version
- Importing entire icon libraries instead of subpath imports — Next.js any version
- `getServerSideProps` where `getStaticProps` + `revalidate` would suffice — Next.js Pages Router only

**LOW (-1 each, max 10)**
- Trailing slashes inconsistency
- Missing `lang` attribute on `<html>`
- Console warnings related to SEO
- Suboptimal image compression
- Missing `rel="noopener"` on external links
- Breadcrumb markup could be added
- Missing `React.memo` on expensive context consumers — Next.js any version
- Unnecessary dynamic imports for tiny components — Next.js any version

### AEO-Specific Deduction Examples

**AEO Severity Philosophy**: AEO checks represent emerging best practices, not established requirements. Most items should be LOW or MEDIUM (opportunities) rather than HIGH (deficiencies). Reserve CRITICAL for actions that actively harm AI visibility (blocking retrieval bots). The absence of `llms.txt`, `speakable` markup, and question headings is the current norm — not a deficiency.

**CRITICAL (-15 each)**
- AI retrieval bots (ChatGPT-User, PerplexityBot, ClaudeBot) explicitly blocked via robots.txt `Disallow: /`
- Blanket `Disallow: /` under `User-agent: *` with no specific `Allow` rules for AI retrieval bots

**MEDIUM (-3 each, max 10)**
- No `llms.txt` file (AI systems can't discover structured site information — emerging best practice)
- Organization schema missing `sameAs` (AI can't verify entity identity)
- Articles missing `dateModified` (AI deprioritizes undated content)
- No `<main>` element (AI can't identify primary content area)
- FAQ content behind JavaScript interactions (not in initial DOM)
- No explicit AI bot rules in robots.txt (relying on defaults)

**LOW (-1 each, max 10)**
- No `@id` on primary structured data entities
- Missing `mainEntityOfPage` on content pages
- Content pages without `<article>` wrapper
- Q&A content without FAQPage schema
- Tutorial/process pages without HowTo schema
- Missing `speakable` markup
- Missing `author.url` or `author.sameAs` on articles
- No question-format headings on content pages
- No dedicated author pages for blog content
- No `llms-full.txt` when `llms.txt` exists
- Training bots not explicitly managed in robots.txt

## Status Thresholds

| Status | Score Range | Meaning |
|--------|------------|---------|
| PASS | 80-100 | Good SEO health, minor improvements possible |
| WARNING | 60-79 | Notable issues that should be addressed |
| FAIL | 0-59 | Critical problems requiring immediate attention |

## Grade Scale

| Grade | Score Range |
|-------|------------|
| A+ | 95-100 |
| A | 90-94 |
| B+ | 85-89 |
| B | 80-84 |
| C+ | 75-79 |
| C | 70-74 |
| D+ | 65-69 |
| D | 60-64 |
| E | 50-59 |
| F | 0-49 |

## Priority Classification Rules

### Severity Validation (apply before assigning any priority)

Before classifying an issue as CRITICAL or HIGH, answer these three questions. If any answer is "no", downgrade the severity.

1. **Is the problem actually present?** Check whether the concern is already handled through an alternative mechanism (e.g., hreflang in `<head>` instead of sitemap, SSR via a different pattern, meta tags via a plugin, error pages at the hosting platform level, security headers in `vercel.json`/`netlify.toml`). A missing implementation in one place is not a problem if it is correctly implemented elsewhere. For static sites / SSGs, many concerns (error pages, security headers, redirects) are handled by the hosting platform, not in source code.
2. **Is the impact real at this severity level?** CRITICAL means indexing is blocked or CWV fails "poor." HIGH means rankings are directly harmed. Can you point to the specific mechanism that causes this level of impact? If you are estimating or guessing, downgrade to MEDIUM.
3. **Does the fix make things better, not worse?** Verify the recommended fix does not contradict another best practice or introduce a new issue. If it does, either find a correct fix or do not report the finding.

### Hard Severity Caps (override agent judgment)

The following checks have maximum severity caps because they do not directly affect search engine rankings. Agents MUST NOT exceed these caps regardless of their own assessment:

| Check | Max Severity | Reason |
|-------|-------------|--------|
| Missing security headers (CSP, X-Frame-Options, HSTS, X-Content-Type-Options) | **LOW** | Not a ranking factor; purely a security best practice |
| Missing `app/error.tsx` or error boundary | **MEDIUM** | Only impacts SEO if errors actually occur in production; a resilience measure |
| Mixed content (`http://` URLs on HTTPS pages) | **MEDIUM** | Browser warnings affect user trust but don't block indexing |
| Missing `Permissions-Policy` header | **LOW** | No SEO impact |

### Environment Variable References

When code uses `process.env.*`, `import.meta.env.*`, or similar environment variable patterns, do NOT assume the variable is missing or undefined. Environment variables are routinely set via:
- Deployment platforms (Vercel, Netlify, Cloudflare Pages, AWS Amplify)
- CI/CD pipelines
- Docker / container orchestration
- `.env` files excluded from version control (`.gitignore`)

**Rules**:
- Never classify a missing env var as CRITICAL based on code analysis alone — you cannot determine if the variable is set in the deployment environment
- If code has no fallback for a critical env var: classify as MEDIUM, recommend adding a fallback, note "verify this is set in your deployment environment"
- Only flag as HIGH if the code would produce broken output even WITH the env var set (e.g., string concatenation that produces an invalid URL structure)

### CMS Content vs Code Issues

When the project uses a headless CMS (Sanity, Contentful, DatoCMS, Storyblok, Prismic, etc.), many SEO issues originate from CMS content rather than code. Apply these rules:

1. **Identify the root cause**: Is the issue in the template/code (missing fallback, broken logic) or in CMS-entered content (duplicate title, empty description, wrong text)?
2. **CMS content issues** (duplicate titles entered by editors, empty pages, mismatched metadata):
   - Cap severity at **MEDIUM** — these are editorial problems, not technical SEO failures
   - Classify fixability as **manual** — cannot be fixed in code
   - Label with "CMS content issue" in the problem description
3. **Template/code issues** that EXPOSE CMS content problems (no fallback for empty fields, no uniqueness enforcement):
   - Classify at normal severity — these ARE code bugs
   - Example: "Title wrapped in conditional with no fallback" is a code issue (HIGH); "Homepage and About share identical title" is a CMS content issue (MEDIUM)
4. **Do not double-count**: If a CMS content issue and its underlying template issue are both reported, score only the template issue. The CMS content issue is context, not a separate deduction.

### Classify as CRITICAL when:
- The issue prevents search engines from crawling or indexing content
- The issue causes Core Web Vitals to fail "poor" thresholds
- The issue creates security vulnerabilities (no HTTPS, mixed content)
- The issue breaks rendering for users or bots (blank pages, JS-only content)
- The issue affects >50% of pages

### Classify as HIGH when:
- The issue directly impacts search rankings (missing titles, duplicate content)
- The issue degrades CWV from "good" to "needs improvement"
- The issue affects user experience significantly (broken images, layout shifts)
- The issue affects key landing pages or templates

### Classify as MEDIUM when:
- The issue represents a missed optimization opportunity
- The issue affects CWV marginally
- The issue is a best-practice violation without immediate ranking impact
- The issue is limited to a subset of pages

### Classify as LOW when:
- The issue is cosmetic or minor best-practice adherence
- The fix provides marginal improvement
- The issue only affects edge cases
- Industry standards are evolving on the topic

### Impact Description Rules
- **Never cite specific timing values** (e.g., "adds 300ms", "delays TTI by 600ms") from code analysis alone. Code-level analysis cannot determine actual load times — those depend on network, device, server, and CDN conditions.
- Use **risk language** instead: "increases LCP risk", "may delay interactivity", "adds to critical bundle size".
- Specific timing numbers are only permitted when derived from **field data** (CrUX) or **lab data** (Lighthouse/PSI).
- Do not invent bundle size numbers (e.g., "~50kB gzipped") unless verified from published package metadata.

### Cross-Check Rules
- **Before recommending `dynamic()` or lazy loading** for a component, verify it is NOT an above-the-fold component (Hero, Header, Nav, Banner, Masthead, TopBar). Above-fold components must be statically imported — dynamically importing them delays LCP and is itself a HIGH-priority antipattern.
- **Before recommending removing a static import**, check whether the component renders above-the-fold content. If it does, the static import is correct regardless of the library's bundle size.
- When a finding's recommended fix would trigger a separate known antipattern, **do not report the finding**. Resolve the contradiction first.

### Signal Relevance Rules
Every sub-point within an issue MUST have a **direct, proven causal relationship** to the metric or category it is reported under. Do not pad findings with loosely related observations.

**Before including a sub-point, verify**:
1. **Causal link exists** — The pattern directly causes the stated metric impact through a known, documented mechanism (e.g., missing `width`/`height` → browser cannot reserve space → layout shift → CLS).
2. **Not just correlated** — "This is an image best practice" is not sufficient reason to list it under CLS. It must actually cause layout shifts.
3. **Not a different category** — If a pattern affects performance but not CLS, report it under Performance, not CLS. If it affects UX but not SEO, do not report it as an SEO issue.

**Common false associations to avoid**:
- `placeholder="blur"` does NOT prevent CLS — it is a loading UX enhancement, not a layout stability mechanism. Only `width`/`height`, `fill` with sized container, or CSS `aspect-ratio` prevent CLS.
- `alt` attributes do NOT affect performance — they affect accessibility and image SEO.
- `loading="lazy"` on below-fold images does NOT affect LCP — LCP measures the largest above-fold element.
- Font `preload` does NOT affect CLS unless the font causes a visible size change on swap.
- **CSS transitions triggered by user interaction** (`:hover`, `:focus`, `click`, `scroll`) do NOT cause CLS — the CLS metric excludes layout shifts that occur within 500ms of a user input event. Only flag transitions/animations that run automatically during page load (entrance animations, auto-play, mount effects). If you cannot confirm a transition runs without user interaction, do NOT report it as a CLS issue.

**If in doubt, leave it out.** A clean finding with one accurate sub-point is better than a noisy finding with three where one is wrong.

## Issue Output Format

Every issue MUST follow this structure:

```
### [PRIORITY] Category: Brief Description

- **ID**: `{check-name}:{file-path}:{line-number}` (e.g., `img-alt:components/Hero.tsx:15`) or `{check-name}:site-wide`
- **Location**: `file/path.tsx:42` or "site-wide"
- **Problem**: What is wrong and why it matters
- **Impact**: How this affects SEO, performance, or user experience
- **Fix**: Specific code change or action to resolve
- **Fixability**: auto-fix | confirm-fix | manual
- **Effort**: trivial | small | medium | large
- **Confidence**: HIGH | MEDIUM | LOW

<details>
<summary>Code evidence</summary>

\`\`\`tsx
// Before (actual code from project) — file/path.tsx:42-48
{paste the actual code found in the project file}

// After (fixed)
{the same actual code with the fix applied}
\`\`\`

</details>
```

### Canonical Issue ID

Every issue must have a unique canonical ID for cross-agent deduplication. Format: `{check-name}:{file-path}:{line-number}`. The orchestrator matches IDs across agents — if two agents report the same ID, ownership rules determine which category scores it.

Check name should be a short kebab-case identifier for the check (e.g., `img-alt`, `missing-meta-desc`, `no-ssr`, `blocked-ai-bot`, `missing-llms-txt`).

### Confidence Levels

Each finding must declare its confidence level:

| Level | Criteria | Severity Cap |
|-------|----------|-------------|
| HIGH | Issue confirmed by reading the actual file content and tracing imports/dependencies | No cap |
| MEDIUM | Pattern detected by grep, confirmed by reading the match context (surrounding lines), but imports/dependencies not fully traced | Cap at HIGH (no CRITICAL) |
| LOW | Pattern detected by grep only, full file context not verified | Cap at MEDIUM (no CRITICAL or HIGH) |

**Rules**:
- If >30% of findings in a category are LOW confidence, add a note: "Some findings in this category have lower detection confidence — manual review recommended"
- LOW confidence findings must never be classified as CRITICAL or HIGH — downgrade automatically
- MEDIUM confidence findings must never be classified as CRITICAL — downgrade to HIGH

### Code Evidence Requirements

The "Before" code in every issue MUST be the actual code found in the project file, not a generic example. Copy the exact lines from the file at the reported path and line range.

The "After" code must be the specific fix applied to the actual project code.

**Never** use placeholder code like `export default function Page() { ... }` — always show the real code. If the issue is site-wide (no single file), show one representative example from the actual codebase.

### Effort Estimates

| Effort | Definition | Examples |
|--------|-----------|----------|
| trivial | < 5 min, single attribute or line change | Add `lang`, add `loading="lazy"`, add `priority` prop |
| small | 5-30 min, single file change | Add JSON-LD block, create `llms.txt`, add meta description |
| medium | 30 min - 2 hours, multiple files | Replace `<img>` with `next/image` across components, add `generateStaticParams` |
| large | > 2 hours, architectural change | Convert SPA to SSR, restructure component tree, add i18n |

### Full Format Requirement

Every issue, regardless of priority level, MUST include the complete format (ID, Location, Problem, Impact, Fix, Fixability, Effort, Confidence, and Code evidence). Do not abbreviate MEDIUM or LOW issues to one-liners.

When there are many issues of the same type (e.g., "8 images missing alt text"), group them into a single finding with all affected locations listed, but still provide one representative code example from the actual codebase.

## Score Sanity Checks

After calculating all category and overall scores, apply these overrides:

1. **CRITICAL cap**: If a category has any CRITICAL issue, cap that category's status at WARNING (score ≤ 79) — a category with unresolved CRITICAL issues must never show PASS
2. **Multi-CRITICAL cap**: If the overall report has ≥2 CRITICAL issues across any categories, cap the overall status at WARNING
3. **Empty confirmed**: If a category has 0 issues AND the agent confirmed it checked all applicable patterns, score is 100 — do not penalize for "nothing found" when checks actually ran
4. **Confidence adjustment**: If >50% of a category's deductions come from LOW confidence findings, add a warning note and consider the score provisional

## Score Calculation

```
category_score = max(0, 100 - sum(deductions))
overall_score = round(sum(category_score * category_weight))
```

When calculating, apply deduction caps for MEDIUM and LOW issues per category, not globally.

### Score Stability Guidelines

To minimize score variance between runs on the same codebase:
1. **Deterministic checks first**: Binary checks (file exists / does not exist, attribute present / absent) should be the primary score drivers. These are fully reproducible.
2. **Judgment-based checks clearly marked**: Checks that require LLM judgment (e.g., "content is thin", "heading hierarchy is poor") should be flagged with Confidence: MEDIUM and should not contribute more than 20% of total deductions in any category.
3. **Report variance warning**: If a re-audit produces a score differing by more than 5 points from a previous run (with no code changes), note: "Score variance detected — this may reflect detection sensitivity differences, not actual quality changes."

### Rounding

- Category scores are always integers (round half-up: 79.5 → 80)
- Overall score is rounded to the nearest integer after applying weights
- Grade and status thresholds apply to the rounded overall score

### Cross-Category Deduplication

When the same issue appears in multiple categories (e.g., an image without alt text could be both Image Optimization and Meta & Structured Data):

1. **Count the deduction in only one category** — the category that owns the issue per the agent boundary rules
2. **Ownership priority**: Image issues → Image Optimization. Meta tag issues → Meta & Structured Data. Framework-specific issues → {Framework} Patterns. AEO issues → AI Search Readiness. If ambiguous, assign to the category where the issue has the higher priority level.
3. **AEO ownership rules**: AI bot rules in robots.txt → AI Search Readiness (not Technical SEO). Entity properties (`sameAs`, `about`, `dateModified` freshness, `mainEntityOfPage`, `speakable`, `reviewedBy`, `@id`) → AI Search Readiness (not Meta & Structured Data). FAQPage/HowTo schema presence → AI Search Readiness. Question-format headings → AI Search Readiness. Semantic landmarks for AI extraction → AI Search Readiness. SSR/SSG scoring → Performance (AEO can cross-reference but not deduct).
4. **Still mention the issue** in the other category's report for context, but mark it as "(scored under {owning category})" and do not deduct points for it there.

### Incomplete Categories

When a category has no data (agent failure or not applicable):
- Exclude the category from the overall score calculation
- Redistribute its weight proportionally across remaining categories
- Example: If {Framework} Patterns (18%) is unavailable, redistribute proportionally across the remaining 5 categories (total remaining = 82%): Technical SEO ~26.8%, Performance ~26.8%, Meta & Structured Data ~22.0%, Image Optimization ~12.2%, AI Search Readiness ~12.2%

## Report Summary Format

```
## SEO Health Score: {overall_score}/100 ({grade}) — {status}

| Category | Score | Status | Issues |
|----------|-------|--------|--------|
| Technical SEO | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Performance | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| {Framework} Patterns | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Meta & Structured Data | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Image Optimization | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| AI Search Readiness | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
```
