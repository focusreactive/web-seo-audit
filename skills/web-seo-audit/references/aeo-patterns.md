# AEO (Answer Engine Optimization) Patterns Reference

## Overview

Answer Engine Optimization (AEO) ensures a website is discoverable, understandable, and citable by AI search engines — ChatGPT, Perplexity, Claude, Google AI Overviews, and similar systems. Unlike traditional SEO which targets search engine result pages, AEO targets AI-generated answers that synthesize information from multiple sources.

This reference covers static-code-level patterns that improve AI search readiness: discovery files, crawler management, entity-optimized structured data, content structure, and crawlability signals.

---

## 1. AI Discovery Files

### llms.txt

The `llms.txt` specification (proposed at llmstxt.org) provides a standardized way for websites to communicate with AI systems. It lives at the site root (`/llms.txt`) alongside `robots.txt`.

**Detection patterns**:
```
glob: public/llms.txt
glob: public/llms-full.txt
glob: app/llms.txt/route.{ts,js}
glob: pages/api/llms.{ts,js}
```

**Format rules**:
- First line: `# {Site/Organization Name}` (H1 heading)
- Second section: `> {Brief description}` (blockquote, one-liner describing the site)
- Followed by markdown sections with links to key content
- Links use markdown format: `- [Title](URL): Description`
- All URLs must be absolute
- Should reference important pages, documentation, APIs, and key content areas
- Optional: `llms-full.txt` for expanded content (full documentation dumps)

**Example llms.txt**:
```markdown
# Acme Corp

> Acme Corp builds developer tools for web performance monitoring.

## Docs

- [Getting Started](https://acme.com/docs/start): Quick-start guide for new users
- [API Reference](https://acme.com/docs/api): Complete API documentation
- [Configuration](https://acme.com/docs/config): Configuration options and examples

## Blog

- [Web Vitals Guide](https://acme.com/blog/web-vitals): Comprehensive CWV optimization guide
- [Performance Tips](https://acme.com/blog/perf-tips): Top 10 performance improvements

## Company

- [About](https://acme.com/about): Company mission and team
- [Pricing](https://acme.com/pricing): Plans and pricing details
```

**Validation rules**:
1. File must exist at `/llms.txt` (public/llms.txt or dynamic route)
2. Must start with H1 heading (`# `)
3. Must contain at least one markdown link
4. All URLs must be absolute (start with `https://`)
5. No broken internal link patterns (links to pages that don't exist in the project)
6. Optional `llms-full.txt` should be referenced if it exists

### .well-known/ai-plugin.json

Some AI systems look for plugin manifests. Detection:
```
glob: public/.well-known/ai-plugin.json
```

---

## 2. AI Crawler Bots

AI systems use web crawlers to index content. These fall into two categories:

### Training Bots (used to train AI models)

These bots crawl content to build training datasets. Blocking them prevents your content from being used in model training but does NOT prevent AI search from citing you.

| Bot | User-Agent | Operator |
|-----|-----------|----------|
| GPTBot | `GPTBot` | OpenAI |
| Google-Extended | `Google-Extended` | Google |
| CCBot | `CCBot` | Common Crawl |
| Bytespider | `Bytespider` | ByteDance |

### Retrieval Bots (used for real-time AI search)

These bots fetch content at query time to generate AI answers. Blocking them prevents your content from appearing in AI search results.

| Bot | User-Agent | Operator |
|-----|-----------|----------|
| ChatGPT-User | `ChatGPT-User` | OpenAI |
| PerplexityBot | `PerplexityBot` | Perplexity |
| ClaudeBot | `ClaudeBot` | Anthropic |
| Applebot-Extended | `Applebot-Extended` | Apple |

### robots.txt Rules for AI Bots

**Detection patterns**:
```
grep "GPTBot|ChatGPT-User|Google-Extended|PerplexityBot|ClaudeBot|CCBot|Bytespider|Applebot-Extended" public/robots.txt
grep "GPTBot|ChatGPT-User|Google-Extended|PerplexityBot|ClaudeBot|CCBot|Bytespider|Applebot-Extended" app/robots.{ts,js}
```

**Recommended configuration** (allow retrieval, optionally block training):
```
# AI Retrieval Bots — ALLOW for AI search visibility
User-agent: ChatGPT-User
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: Applebot-Extended
Allow: /

# AI Training Bots — Block if you don't want content used for training
User-agent: GPTBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: Bytespider
Disallow: /
```

**Key rules**:
- CRITICAL: Do not blanket-block all AI bots — distinguish training from retrieval
- CRITICAL: Blocking retrieval bots (ChatGPT-User, PerplexityBot, ClaudeBot) removes you from AI search results
- A blanket `User-agent: *` with `Disallow: /` blocks everything, including AI retrieval
- Training bot blocking is a business decision, not an SEO issue — note but don't penalize

---

## 3. Entity-Optimized Structured Data

AI search engines heavily rely on structured data to understand entities, relationships, and freshness. These properties go beyond basic schema.org requirements and specifically improve AI discoverability.

### Priority Properties for AI

| Property | Schema Types | Purpose | AI Impact |
|----------|-------------|---------|-----------|
| `sameAs` | Organization, Person | Links to authoritative profiles (Wikipedia, LinkedIn, social) | Helps AI verify entity identity |
| `about` | WebPage, Article | Describes what the page is about (Thing reference) | Helps AI categorize content |
| `dateModified` | Article, WebPage | Last modification date | AI prefers fresh content; stale dates reduce citation |
| `mainEntityOfPage` | Article, Product | Declares the primary entity of the page | Helps AI understand page purpose |
| `speakable` | Article, WebPage | Marks content suitable for voice/audio answers | Used by Google Assistant and AI voice interfaces |
| `reviewedBy` | Article, MedicalWebPage | Expert review attribution | Builds E-E-A-T signals for AI |
| `@id` | Any | Stable identifier for entity | Enables cross-page entity resolution |
| `author.url` | Article, BlogPosting | Link to author's dedicated page | Strengthens authorship signals |
| `author.sameAs` | Article, BlogPosting | Author's authoritative profiles | Verifies author identity |
| `isPartOf` | WebPage, Article | Parent collection/site reference | Helps AI understand content hierarchy |

### Detection Patterns

```
# Check for entity-optimized properties
grep "sameAs" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "\"about\"" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "dateModified" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "mainEntityOfPage" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "speakable" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "reviewedBy" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
grep "\"@id\"" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}

# Check for FAQPage and HowTo (AI-favored schemas)
grep "FAQPage|HowTo" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

### FAQPage Schema (AI-Favored)

AI engines frequently extract FAQ content for direct answers. Detection:
```
grep "FAQPage" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

Pages with Q&A sections should have FAQPage schema. Check for:
- Question-answer patterns in JSX without corresponding FAQPage schema
- FAQPage schema with fewer than 2 questions (too thin)
- Questions that don't match visible page content

### HowTo Schema (AI-Favored)

Step-by-step content is heavily cited by AI. Detection:
```
grep "HowTo" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

Tutorial/guide pages should have HowTo schema. Check for:
- Ordered list content (`<ol>`) without HowTo schema
- HowTo schema without `step` array
- Missing `name` or `text` in HowToStep items

### @id Consistency

Every primary entity should have a stable `@id` that matches its canonical URL:
```json
{
  "@type": "Article",
  "@id": "https://example.com/blog/my-post#article",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://example.com/blog/my-post"
  }
}
```

**Rules**:
- `@id` should use the canonical URL with an optional fragment identifier
- `@id` must be consistent across page loads (no random values)
- Cross-referenced entities should use matching `@id` values

---

## 4. Content Structure Patterns

AI engines extract answers from well-structured content. These patterns improve extraction quality.

### Semantic Landmarks

AI crawlers use HTML5 landmarks to identify content regions:

```html
<main>          <!-- Primary content area -->
<article>       <!-- Self-contained content piece -->
<section>       <!-- Thematic grouping with heading -->
<aside>         <!-- Supplementary content -->
<nav>           <!-- Navigation -->
<header>        <!-- Introductory content -->
<footer>        <!-- Footer content -->
```

**Detection patterns**:
```
grep "<main|<article|<section|<aside" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

**Rules**:
- Page should have exactly one `<main>` element (MEDIUM if missing)
- Content pages should use `<article>` for primary content (LOW if missing)
- Sections should have associated headings (LOW if missing)
- Missing all landmarks = content is in generic `<div>` soup (MEDIUM issue)

### Question-Format Headings

AI engines match user queries to heading text. Questions in headings improve matching:

```html
<!-- AI-friendly: matches "What are Core Web Vitals?" query directly -->
<h2>What Are Core Web Vitals?</h2>
<p>Core Web Vitals are a set of three metrics...</p>

<!-- Less AI-friendly: doesn't match question queries -->
<h2>Core Web Vitals Overview</h2>
<p>Core Web Vitals are a set of three metrics...</p>
```

**Detection patterns**:
```
# Find headings that are questions (good)
grep "<h[2-6].*\?<" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}

# Find heading patterns
grep "<h[2-6]" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

**Rules**:
- Content pages should have at least some question-format headings (who, what, when, where, why, how)
- This is a LOW/MEDIUM recommendation, not a requirement
- FAQ pages should have mostly question headings

### Answer-First Paragraphs

The first paragraph after a heading should directly answer the question (inverted pyramid style):

```html
<!-- Good: answer-first -->
<h2>What Is LCP?</h2>
<p>LCP (Largest Contentful Paint) measures the time until the largest visible element renders. Google considers LCP good when it's under 2.5 seconds.</p>

<!-- Poor: preamble-first -->
<h2>What Is LCP?</h2>
<p>When thinking about web performance, there are many metrics to consider. One of the most important ones, which we'll discuss in this section, is...</p>
```

This is a content quality signal — difficult to detect purely from code, but check for:
- Paragraphs immediately following headings (good structure)
- Very short first paragraphs after headings (< 20 chars, may be incomplete)

### Tables and Ordered Lists

AI engines prefer structured data formats for comparison and step-by-step content:

**Detection patterns**:
```
# Tables (good for comparisons, specifications)
grep "<table|<Table" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}

# Ordered lists (good for steps, rankings)
grep "<ol" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx} pages/**/*.{tsx,jsx}
```

---

## 5. AI Crawlability Signals

### SSR Cross-Reference

AI crawlers, like traditional search bots, cannot execute JavaScript reliably. Content rendered only client-side may be invisible to AI retrieval bots.

**This check cross-references the Performance agent's SSR findings** — it does not re-score SSR/SSG. Instead, it notes the AI-specific impact:

- Pages using `'use client'` + `useEffect` for primary content: AI bots see empty pages
- SPA-only rendering: None of the content is available to AI crawlers
- SSR/SSG pages: Content is available to AI crawlers (good)

**Detection**:
```
grep "'use client'" app/**/page.{tsx,jsx}
grep "useEffect.*fetch|useSWR|useQuery" app/**/page.{tsx,jsx}
```

**Rule**: Do NOT deduct points for SSR issues — that's the Performance agent's responsibility. Only note the AI impact for context.

### Content Behind JS Interactions

Content hidden behind tabs, accordions, or "show more" buttons may not be visible to AI crawlers:

**Detection patterns**:
```
# Tab/accordion patterns
grep "TabPanel|Accordion|Collapse|Disclosure|showMore|readMore|expandable" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}

# CSS hidden content
grep "display:\s*none|visibility:\s*hidden|hidden|aria-hidden" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- Content critical for AI answers should not require interaction to reveal
- FAQs behind accordions: the HTML content should still be in the DOM (just visually hidden), not loaded on click
- Tab content: all tab panels should be in the DOM, not lazy-loaded on tab switch
- MEDIUM issue if important content requires JS interaction to appear in DOM

### Author Pages

AI engines use author information for E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness) signals:

**Detection patterns**:
```
# Author page patterns
glob: app/authors/**/*.{tsx,jsx}
glob: app/team/**/*.{tsx,jsx}
glob: pages/authors/**/*.{tsx,jsx}
glob: pages/team/**/*.{tsx,jsx}
glob: app/about/**/*.{tsx,jsx}

# Author references in content
grep "author" app/**/*.{tsx,jsx} components/**/*.{tsx,jsx}
```

**Rules**:
- Sites with blog/article content should have dedicated author pages
- Author pages should have Person schema with `sameAs` links
- Articles should link to author pages (`author.url`)
- LOW recommendation if missing (valuable but not critical)
