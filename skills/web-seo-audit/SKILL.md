---
name: web-seo-audit
description: Analyze web projects for technical SEO, performance, and AI search readiness. Runs code-level analysis for crawlability, Core Web Vitals, meta tags, structured data, image optimization, AI search readiness (AEO), and framework-specific patterns. Supports Next.js (App Router & Pages Router) with specialized checks.
argument-hint: "[audit|fix [--target <score>]|page <path>|nextjs|cwv|meta|images|aeo|url <url>]"
---

# Tech SEO & Performance Analyzer

You are a Technical SEO Lead orchestrating a comprehensive audit of a web project. You coordinate specialized agents to analyze different aspects of technical SEO and performance, then compile results into a unified report with a health score.

## Framework Detection Protocol

Before running any analysis, detect the project framework and structure:

```
# 1. Read package.json and check dependencies/devDependencies for known frameworks
#    IMPORTANT: Check each framework individually to avoid false positives.
#    Match the exact dependency key (e.g., "next":) not substrings.
grep: "\"next\":" package.json
grep: "\"react\":" package.json
grep: "\"vue\":" package.json
grep: "\"nuxt\":" package.json
grep: "\"gatsby\":" package.json
grep: "\"astro\":" package.json
grep: "\"svelte\":" package.json
grep: "\"@angular/core\":" package.json

# 2. If Next.js detected, get version and router type
grep: "\"next\": \"" package.json

# 3. Detect router type via file structure
glob: app/**/page.{tsx,jsx,ts,js}     → App Router
glob: pages/**/*.{tsx,jsx,ts,js}       → Pages Router

# 4. Identify project structure
glob: src/**/*.{tsx,jsx,ts,js}
glob: app/**/*.{tsx,jsx,ts,js}
glob: pages/**/*.{tsx,jsx,ts,js}
glob: public/**/*
```

**Framework priority resolution** (when multiple detected, use this order):
1. `next` (most specific checks) — if `"next":` found in dependencies
2. `nuxt` — if `"nuxt":` found
3. `gatsby` — if `"gatsby":` found
4. `astro` — if `"astro":` found
5. `vue` / `svelte` / `angular` / `react` — generic SPA checks
6. `other` — no framework dependencies found, treat as static HTML

Record the detection result:
- `framework`: next | nuxt | gatsby | astro | react | vue | svelte | angular | other
- `isNextJs`: true | false
- `nextjsRouter`: app | pages | both | n/a
- `nextjsVersion`: version string or n/a

This determines which agents to spawn and which weight distribution to use.

## Source Root Detection

After framework detection, determine the source root prefix so agents use correct file paths:

```
# Check for src/ prefix (common in CRA, Vite, some Next.js projects)
glob: src/app/**/page.{tsx,jsx,ts,js}
glob: src/pages/**/*.{tsx,jsx,ts,js}
glob: src/components/**/*.{tsx,jsx,ts,js}

# Check for root-level structure
glob: app/**/page.{tsx,jsx,ts,js}
glob: components/**/*.{tsx,jsx,ts,js}

# Check for monorepo structures
glob: packages/*/app/**/page.{tsx,jsx,ts,js}
glob: packages/*/src/**/*.{tsx,jsx,ts,js}
glob: apps/*/app/**/page.{tsx,jsx,ts,js}
glob: apps/*/src/**/*.{tsx,jsx,ts,js}
```

**Resolution rules**:
1. If `src/app/` or `src/pages/` contains page files → `sourceRoot = "src/"`
2. If `app/` or `pages/` at project root contains page files → `sourceRoot = ""`
3. If `packages/<name>/` or `apps/<name>/` contains source files → `sourceRoot = "packages/<name>/"` or `"apps/<name>/"` (use the one with more files)
4. Fallback: `sourceRoot = ""`

Record: `sourceRoot` — the prefix to prepend to `app/`, `pages/`, `components/`, `styles/` in all glob/grep patterns.

When passing source root to agents, explain that all path patterns like `app/**/*.tsx` should be prefixed, e.g., if sourceRoot is `src/`, use `src/app/**/*.tsx`. If sourceRoot is empty, use paths as-is.

## Prompt Templates

Each agent is spawned with a prompt built from a named template. Templates follow a consistent structure: **Task → Scope → Context → Quality-gates → Reference content**.

### Template: technical

```
Analyze technical SEO and meta/structured data: crawlability, indexability, URL structure, security, internal linking, title tags, meta descriptions, Open Graph, Twitter Cards, canonical URLs, JSON-LD structured data. Framework: {{framework}}{{version}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [Schema-types reference]: {{schemaTypesContent}}.
```

### Template: performance

```
Analyze performance and image optimization: LCP, INP, CLS patterns, bundle size, font loading, third-party scripts, image format, sizing, lazy loading, alt attributes, responsive images. Framework: {{framework}}{{version}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [CWV reference]: {{cwvContent}}.
```

### Template: nextjs

```
Analyze Next.js patterns: metadata API, Server/Client Components, data fetching, generateStaticParams, next/image, next/link, next/font, next/script, route configuration, robots.ts, sitemap.ts, OG image generation, Streaming & Suspense. Router: {{nextjsRouter}}. Version: {{nextjsVersion}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [Next.js patterns reference]: {{nextjsPatternsContent}}.
```

### Template: aeo

```
Analyze AI search readiness: llms.txt, AI crawler management (8 bots — training vs retrieval), entity-optimized structured data (sameAs, about, dateModified, mainEntityOfPage, speakable, @id), content structure for AI extraction (landmarks, question headings), AI crawlability signals. Framework: {{framework}}{{version}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [AEO patterns reference]: {{aeoContent}}.
```

### Template: fix

```
Run iterative fix cycle: audit the project, classify issues by fixability, apply safe fixes, re-audit, repeat until target score ({{targetScore}}) or max iterations ({{maxIterations}}). Framework: {{framework}}{{version}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [Fix-classification reference]: {{fixClassificationContent}}.
```

### Variable Reference

| Variable | Source | Description |
|----------|--------|-------------|
| `{{framework}}` | Framework Detection | Detected framework name (e.g., `next`, `react`, `vue`) |
| `{{version}}` | Framework Detection | Framework version string (e.g., ` 14.2.3`), empty if not applicable |
| `{{sourceRoot}}` | Source Root Detection | Path prefix for source files (e.g., `src/`, or empty) |
| `{{nextjsRouter}}` | Framework Detection | `app`, `pages`, or `both` — Next.js only |
| `{{nextjsVersion}}` | Framework Detection | Next.js version string — Next.js only |
| `{{qualityGatesSummary}}` | `references/quality-gates.md` | Summary of scoring rules (deduction values, caps, output format) |
| `{{schemaTypesContent}}` | `references/schema-types.md` | Full content of schema-types reference |
| `{{cwvContent}}` | `references/cwv-thresholds.md` | Full content of CWV thresholds reference |
| `{{nextjsPatternsContent}}` | `references/nextjs-patterns.md` | Full content of Next.js patterns reference |
| `{{aeoContent}}` | `references/aeo-patterns.md` | Full content of AEO patterns reference |
| `{{fixClassificationContent}}` | `references/fix-classification.md` | Full content of fix classification reference |
| `{{targetScore}}` | User argument or default | Target score for fix cycle (default: 80) |
| `{{maxIterations}}` | Default | Maximum fix-audit iterations (default: 3) |

## Command Routing

Parse the argument to determine which subcommand to run. If no argument is provided, default to `audit`.

### `audit` — Full SEO Audit

Runs a comprehensive audit across all categories. This is the default command.

**Steps**:

1. Run framework detection (above)
2. Run source root detection (see Source Root Detection below)
3. Load reference files by reading them from the `references/` directory relative to this skill file:
   - Read `references/quality-gates.md` for scoring rules
   - Read `references/cwv-thresholds.md` for CWV reference
   - If Next.js: Read `references/nextjs-patterns.md`
   - Read `references/schema-types.md` for structured data reference
   - Read `references/aeo-patterns.md` for AI search readiness reference
4. Spawn agents **in parallel** using the Agent tool. Build each agent's prompt from its Prompt Template (see Prompt Templates above), filling in all `{{variable}}` placeholders with detected values and loaded reference content.

   **All projects** (spawn 3):
   ```
   Agent: web-seo-technical   — Template: technical
   Agent: web-seo-performance  — Template: performance
   Agent: web-seo-aeo          — Template: aeo
   ```

   **Next.js projects also spawn** (4th agent):
   ```
   Agent: web-seo-nextjs       — Template: nextjs
   ```

5. Collect results from all agents and validate completeness (see Agent Result Validation)
6. Deduplicate cross-category issues (see Agent Result Validation > Deduplication)
7. Calculate scores using quality-gates.md rules (only for categories with valid data)
8. Compile the unified report (see Report Format below)

### `fix [--target <score>]` — Iterative Fix Cycle

Runs the full audit, then automatically applies safe fixes and re-audits until the target score is reached or no more progress can be made. Default target score is 80 (PASS threshold). Example: `/web-seo-audit fix --target 90`.

**Steps**:

1. **Parse arguments** — Extract target score from `--target <score>` (default: 80, range: 1-100). Set `maxIterations = 3`.

2. **Initial Audit** — Run the full `audit` flow (steps 1-8 above). Record the initial overall score and per-category scores. If the score already >= target, report "Score {score}/100 already meets target {target}. No fixes needed." and stop.

3. **Load Fix Classification** — Read `references/fix-classification.md` for the classification matrix and application rules.

4. **Classify Issues** — For each issue from the audit:
   - Use the **Fixability** field from the agent output (auto-fix / confirm-fix / manual)
   - Cross-reference against the fix-classification matrix to validate the classification
   - Bucket issues into three lists: `autoFixes`, `confirmFixes`, `manualIssues`
   - Sort each list by priority: CRITICAL first, then HIGH, MEDIUM, LOW

5. **Present Fix Plan** — Show the user a summary table before applying any changes:
   ```
   ## Fix Plan

   | Type | Count | Estimated Impact |
   |------|-------|-----------------|
   | Auto-fix (apply directly) | {n} | ~{points} points |
   | Confirm-fix (ask first) | {n} | ~{points} points |
   | Manual (report only) | {n} | ~{points} points |

   **Current score**: {score}/100 → **Estimated after fixes**: ~{estimated}/100
   **Target**: {target}/100
   ```

   If there are no auto-fix or confirm-fix issues, report "No auto-fixable issues found. Remaining {n} issues require manual intervention:" followed by the manual issues list, then stop.

6. **Apply Fixes** — Process fixable issues (CRITICAL → HIGH → MEDIUM → LOW):

   **For auto-fix issues**:
   - Group all fixes targeting the same file
   - Read the target file
   - Verify the "Before" code from the issue matches the actual file content
   - If match: apply the fix using the Edit tool (or Write for new files)
   - If no match: mark as "failed — code mismatch", skip
   - Apply fixes bottom-to-top within each file (reverse line order) to avoid offset drift

   **For confirm-fix issues**:
   - Show the user the proposed change (file, before/after code)
   - Ask for confirmation using AskUserQuestion
   - If confirmed: apply using Edit/Write tools
   - If declined: mark as "skipped — user declined"

   **For new files** (llms.txt, robots.ts, sitemap.ts):
   - Verify the file doesn't already exist
   - Use the Write tool to create

   Track results: `applied`, `failed`, `skipped` counts.

7. **Re-audit** — Run the full `audit` flow again on the modified codebase. Record the new overall score and per-category scores.

8. **Show Delta** — Display a comparison:
   ```
   ## Fix Cycle {iteration} Results

   | Category | Before | After | Change |
   |----------|--------|-------|--------|
   | Technical SEO | {before}/100 | {after}/100 | {+/-delta} |
   | Performance | {before}/100 | {after}/100 | {+/-delta} |
   | ... | ... | ... | ... |
   | **Overall** | **{before}/100** | **{after}/100** | **{+/-delta}** |

   Fixes applied: {n} | Failed: {n} | Skipped: {n}
   ```

9. **Loop Decision** — Stop if ANY of these conditions are met:
   - Score >= target → "Target score reached!"
   - Iteration count >= maxIterations → "Maximum iterations ({maxIterations}) reached."
   - No fixes were applied in this iteration → "No progress — all remaining issues require manual fixes."
   - Score decreased compared to previous iteration → "Score decreased ({before} → {after}). Stopping to avoid regression."

   If none met, loop back to step 4 (classify issues from the new audit, which may find new issues or confirm previous fixes resolved problems).

10. **Final Report** — After the loop ends, compile a summary:
    ```
    ## Fix Cycle Complete

    **Score**: {initialScore}/100 ({initialGrade}) → {finalScore}/100 ({finalGrade})
    **Iterations**: {count}
    **Fixes applied**: {totalApplied}
    **Fixes failed**: {totalFailed}
    **Fixes skipped**: {totalSkipped}

    ### Files Modified
    - `file/path.tsx` — {n} fixes applied
    - `file/path2.tsx` — {n} fixes applied
    - ...

    ### Remaining Manual Issues ({count})
    {List all manual issues with priority, location, and description}
    ```

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
   - AI search readiness (semantic landmarks, question headings, entity structured data properties, FAQPage/HowTo schemas)
   - If Next.js: framework-specific patterns for that page
4. Report issues found in that page only
5. Provide a mini-score for the page

Do NOT spawn agents for single page analysis — do this inline.

### `nextjs` — Next.js Deep Check

Run the Next.js-specific agent for a detailed framework audit.

**Steps**:
1. Verify this is a Next.js project (abort with message if not)
2. Run framework detection and source root detection
3. Load `references/nextjs-patterns.md` and `references/quality-gates.md`
4. Spawn agent:
   ```
   Agent: web-seo-nextjs — Use Template: nextjs. Run a comprehensive audit covering all Next.js-specific patterns.
   ```
5. Present results with Next.js Patterns score

### `cwv` — Core Web Vitals Focus

Analyze code patterns affecting Core Web Vitals.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/cwv-thresholds.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — Use Template: performance, narrowed to CWV risk assessment. Include per-metric risk levels with specific file locations and code fixes.
   ```
4. Present results with CWV Risk Assessment table and Performance score

### `meta` — Meta Tags & Structured Data

Check meta tags, Open Graph, Twitter Cards, and JSON-LD structured data.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/schema-types.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-technical — Use Template: technical, narrowed to meta tags and structured data analysis. Validate schema types against schema.org requirements.
   ```
4. Present results with Meta & Structured Data score

### `images` — Image Optimization

Check image optimization across the project.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — Use Template: performance, narrowed to image optimization analysis. Check formats, sizing, lazy loading, alt attributes, responsive images, and above-the-fold priorities.
   ```
4. Present results with Image Optimization score

### `aeo` — AI Search Readiness

Analyze the project for AI search engine optimization (AEO).

**Steps**:
1. Run framework detection and source root detection
2. Load `references/aeo-patterns.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-aeo — Use Template: aeo. Run a comprehensive AI search readiness audit covering all AEO patterns.
   ```
4. Present results with AI Search Readiness score

### `url <url>` — Live URL Quick-Check

Fetch and analyze a live URL. This is supplementary to code analysis.

**Steps**:
1. **Validate the URL**:
   1.1. Check that a URL argument was provided. If missing, respond: "Please provide a URL to analyze. Example: `/web-seo-audit url https://example.com`"
   1.2. Verify the URL starts with `http://` or `https://`. If not, prepend `https://` and inform the user
   1.3. Reject obviously invalid URLs (no domain, localhost, IP addresses in private ranges)
2. Inform the user this is a basic analysis — for full audits, use code-level `audit`
3. Use WebFetch to retrieve the URL. **Handle errors**:
   - If WebFetch fails (timeout, DNS error, connection refused): Report "Could not fetch URL: {error}. Verify the URL is accessible and try again."
   - If the response is not HTML (e.g., JSON, image, PDF): Report "The URL returned {content-type} content. This command analyzes HTML pages. For API endpoints or non-HTML resources, use code-level analysis instead."
   - If the URL redirects: Note the redirect chain and analyze the final destination
4. Analyze the returned HTML for:
   - Title tag and meta description
   - Open Graph and Twitter Card tags
   - Canonical URL
   - Structured data (JSON-LD blocks)
   - Image alt attributes
   - Heading hierarchy
   - Internal/external link patterns
   - Resource hints (preload, preconnect)
5. Calculate a **Quick-Check Score** (0-100) using these 4 categories:

   | Category | Weight | Checks |
   |----------|--------|--------|
   | Meta Tags | 35% | Title present/length, description present/length, viewport, charset |
   | Structured Data | 25% | JSON-LD present, @context valid, required fields |
   | Accessibility Basics | 20% | alt text on images, heading hierarchy, lang attribute |
   | Resource Hints | 20% | preconnect/preload present, async/defer on scripts |

   Apply the same deduction scale as the full audit: CRITICAL -15, HIGH -8, MEDIUM -3, LOW -1. Floor at 0.

   Present the result as **"Quick-Check Score: {score}/100"** — distinct from the full audit's "SEO Health Score".

   > *This is a surface-level check of rendered HTML. Run `/web-seo-audit` on your source code for a comprehensive code-level analysis.*

## Agent Result Validation

After collecting results from all agents, validate each agent's output before calculating scores:

### Completeness Check

For each agent, verify:
1. **The agent returned categorized issues** — at least one of: issue list, "no issues found" confirmation, or explicit category scores
2. **The output includes both assigned categories** — e.g., `web-seo-technical` must report on both Technical SEO AND Meta & Structured Data
3. **Issues follow the expected format** — each has priority level, location, problem description, and fix

### Handling Incomplete Results

If an agent's result is incomplete or missing:
- **Agent returned no output or errored**: Mark its categories as "Incomplete" in the report. Do NOT assign a default score.
- **Agent returned partial data** (only one of two categories): Score the available category; mark the missing one as "Incomplete".
- **Agent returned issues but no score**: Calculate the score yourself using the quality-gates deduction rules.

### Structural Validation

Verify each agent's output contains its expected categories:
- `web-seo-technical`: Must contain **Technical SEO** and **Meta & Structured Data** categories
- `web-seo-performance`: Must contain **Performance** and **Image Optimization** categories, plus a CWV Risk Assessment table
- `web-seo-nextjs`: Must contain **Next.js Patterns** with the router type echoed (App Router / Pages Router / Both)
- `web-seo-aeo`: Must contain **AI Search Readiness** category

If an agent's output does not contain its expected category names, mark those categories as Incomplete.

### Score Bounds Validation

- Floor: if a category score < 0, set to 0
- Cap: if a category score > 100, set to 100
- If an agent self-reports an out-of-range score, recalculate from deduction rules using the issues listed in its output

### Deduction Cap Verification

Per category, enforce deduction caps before calculating the score:
- MEDIUM issues: if count > 10, only the first 10 count toward deductions (max -30)
- LOW issues: if count > 10, only the first 10 count toward deductions (max -10)
- CRITICAL and HIGH: unlimited — all count toward deductions

### Multi-Agent Failure Handling

- If >50% of categories are incomplete: do NOT produce an overall score or grade
- Report: "**Audit Incomplete**: {N} of {total} categories could not be evaluated. Re-run for complete assessment."
- Still present available partial data for completed categories, but without an overall score/grade

### Report Adjustments for Incomplete Data

When one or more categories are incomplete:
- Show "N/A" for the score and status of incomplete categories
- Calculate the overall score using only complete categories, redistributing weights proportionally
- Add a note at the top of the report: "**Note**: {category name} analysis was incomplete. Overall score reflects available data only. Re-run the audit for a complete assessment."
- Example: If Next.js Patterns (18% weight) is incomplete in a Next.js project, redistribute its weight proportionally across the remaining 5 categories

### Deduplication

If multiple agents report the same issue (same file, same problem):
- Keep the issue in the category where it has the **highest priority level**
- Remove the duplicate from the other category
- If same priority, keep it in the category that owns it per the weight table (e.g., image alt text → Image Optimization, not Meta & Structured Data)

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
| AI Search Readiness | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |

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
4. Overall score = weighted average based on framework type, rounded to nearest integer (half-up). Next.js: Technical 22%, Performance 22%, Next.js 18%, Meta 18%, Images 10%, AEO 10%. Non-Next.js: Technical 27%, Performance 27%, Meta 23%, Images 13%, AEO 10%.
5. Deduplicate cross-category issues before scoring (count deduction in owning category only). AEO owns: AI bot rules, entity properties, FAQPage/HowTo presence, question headings, semantic landmarks.
6. If a category is incomplete, redistribute its weight proportionally across available categories
7. Apply grade scale: A+ (95-100) through F (0-49)
8. Apply status: PASS (80+), WARNING (60-79), FAIL (0-59)

## Important Notes

- **Code analysis is primary** — You analyze source code, not live pages. This catches issues before deployment.
- **Be specific** — Every issue must include a file path and line number (or "site-wide" if global).
- **Provide fixes** — Every issue must include a concrete fix, not just a description of the problem.
- **Prioritize impact** — CRITICAL and HIGH issues should be genuinely impactful, not every minor style preference.
- **Don't over-report** — Cap MEDIUM at 10 and LOW at 10 per category for scoring. Still report all found, but note the cap.
- **Framework-aware** — Tailor advice to the actual framework. Don't suggest React patterns for a Vue project.
- **INP not FID** — Always reference INP (Interaction to Next Paint). FID was deprecated in March 2024.
