# Quality Gates & Scoring System

## Overview

This reference defines the scoring methodology for tech SEO audits. Each audit produces a 0-100 health score per category, combined into an overall weighted score.

## Weight Distribution

### Next.js Projects

| Category | Weight | Agent |
|----------|--------|-------|
| Technical SEO | 25% | web-seo-technical |
| Performance | 25% | web-seo-performance |
| Next.js Patterns | 20% | web-seo-nextjs |
| Meta & Structured Data | 20% | web-seo-technical |
| Image Optimization | 10% | web-seo-performance |

### Non-Next.js Projects

| Category | Weight | Agent |
|----------|--------|-------|
| Technical SEO | 30% | web-seo-technical |
| Performance | 30% | web-seo-performance |
| Meta & Structured Data | 25% | web-seo-technical |
| Image Optimization | 15% | web-seo-performance |

## Deduction Rules

Each category starts at 100. Issues deduct points based on priority:

| Priority | Deduction | Max Deductions | Description |
|----------|-----------|----------------|-------------|
| CRITICAL | -15 | Unlimited | Blocks indexing, causes major CWV failure, security vulnerability |
| HIGH | -8 | Unlimited | Significantly harms rankings or user experience |
| MEDIUM | -3 | Max 10 issues counted | Moderate impact, should fix but not urgent |
| LOW | -1 | Max 10 issues counted | Minor improvements, best practices |

### Deduction Examples

**CRITICAL (-15 each)**
- `noindex` on pages that should be indexed
- Missing or broken canonical URLs on key pages
- Render-blocking resources preventing LCP under 4s
- No HTTPS or mixed content on production
- Missing viewport meta tag
- JavaScript-only rendering with no SSR/SSG

**HIGH (-8 each)**
- Missing `<title>` or `<meta description>` on important pages
- Duplicate title tags across multiple pages
- Images without `width`/`height` causing CLS > 0.25
- No structured data on content pages
- Bundle size > 500KB for initial load
- Missing `alt` attributes on meaningful images
- No sitemap.xml or robots.txt

**MEDIUM (-3 each, max 10)**
- Title tag too long (> 60 chars) or too short (< 30 chars)
- Meta description too long (> 160 chars) or too short (< 70 chars)
- Non-descriptive anchor text on internal links
- Images not using modern formats (WebP/AVIF)
- Missing Open Graph or Twitter Card meta tags
- Fonts not preloaded or using `font-display: swap`
- Non-semantic heading hierarchy (skipping levels)

**LOW (-1 each, max 10)**
- Trailing slashes inconsistency
- Missing `lang` attribute on `<html>`
- Console warnings related to SEO
- Suboptimal image compression
- Missing `rel="noopener"` on external links
- Breadcrumb markup could be added

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

## Issue Output Format

Every issue MUST follow this structure:

```
### [PRIORITY] Category: Brief Description

- **Location**: `file/path.tsx:42` or "site-wide"
- **Problem**: What is wrong and why it matters
- **Impact**: How this affects SEO, performance, or user experience
- **Fix**: Specific code change or action to resolve

<details>
<summary>Code example</summary>

\`\`\`tsx
// Before (problematic)
...

// After (fixed)
...
\`\`\`

</details>
```

## Score Calculation

```
category_score = max(0, 100 - sum(deductions))
overall_score = sum(category_score * category_weight)
```

When calculating, apply deduction caps for MEDIUM and LOW issues per category, not globally.

## Report Summary Format

```
## SEO Health Score: {overall_score}/100 ({grade}) — {status}

| Category | Score | Status | Issues |
|----------|-------|--------|--------|
| Technical SEO | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Performance | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Next.js Patterns | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Meta & Structured Data | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
| Image Optimization | {score}/100 | {status} | {critical}C {high}H {medium}M {low}L |
```
