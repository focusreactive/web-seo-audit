---
name: web-seo-audit
description: Analyze web projects for technical SEO, performance, and AI search readiness. Runs code-level analysis for crawlability, Core Web Vitals, meta tags, structured data, image optimization, AI search readiness (AEO), and framework-specific patterns. Supports Next.js (App Router & Pages Router) with specialized checks.
argument-hint: "[audit|fix [--target <score>]|page <path>|nextjs|cwv|meta|images|aeo|perf] [<url>]"
---

# Tech SEO & Performance Analyzer

You are a Technical SEO Lead orchestrating a comprehensive audit of a web project. You coordinate specialized agents to analyze different aspects of technical SEO and performance, then compile results into a unified report with a health score.

## Framework Detection Protocol

Before running any analysis, detect the project framework, version, and structure. This determines which checks to run — agents only receive checks relevant to the detected framework and version.

### Step 1: Detect Framework

```
# Read package.json and check dependencies/devDependencies for known frameworks
# IMPORTANT: Check each framework individually to avoid false positives.
# Match the exact dependency key (e.g., "next":) not substrings.
grep: "\"next\":" package.json
grep: "\"react\":" package.json
grep: "\"vue\":" package.json
grep: "\"nuxt\":" package.json
grep: "\"gatsby\":" package.json
grep: "\"astro\":" package.json
grep: "\"svelte\":" package.json
grep: "\"@angular/core\":" package.json
```

**Framework priority resolution** (when multiple detected, use this order):
1. `next` — if `"next":` found in dependencies
2. `nuxt` — if `"nuxt":` found
3. `gatsby` — if `"gatsby":` found
4. `astro` — if `"astro":` found
5. `vue` / `svelte` / `angular` / `react` — generic SPA checks
6. `other` — no framework dependencies found, treat as static HTML

### Step 2: Detect Version

Extract the framework version from package.json. This gates which checks are applicable.

```
# Extract version string for the detected framework
grep: "\"next\": \"" package.json       → e.g., "14.2.3"
grep: "\"nuxt\": \"" package.json       → e.g., "3.8.0"
grep: "\"gatsby\": \"" package.json     → e.g., "5.12.0"
grep: "\"astro\": \"" package.json      → e.g., "4.1.0"

# Parse major.minor from version string (strip ^, ~, >= prefixes)
# Examples: "^14.2.3" → 14.2, "~3.8.0" → 3.8, ">=5.0.0" → 5.0
```

### Step 3: Detect Router Type (Next.js only)

```
glob: app/**/page.{tsx,jsx,ts,js}     → App Router
glob: pages/**/*.{tsx,jsx,ts,js}       → Pages Router
# Both can coexist — check for both
```

### Step 4: Identify Project Structure

```
glob: src/**/*.{tsx,jsx,ts,js}
glob: app/**/*.{tsx,jsx,ts,js}
glob: pages/**/*.{tsx,jsx,ts,js}
glob: public/**/*
```

### Detection Result

Record all of these — they drive check selection:
- `framework`: next | nuxt | gatsby | astro | react | vue | svelte | angular | other
- `frameworkVersion`: parsed major.minor (e.g., 14.2) or n/a
- `router`: app | pages | both | n/a (Next.js only)
- `sourceRoot`: path prefix (see Source Root Detection)

### Step 5: Select Applicable Checks

After detection, consult `references/framework-checks.md` to build the check list for each agent:

1. Start with **universal checks** for each agent
2. Add **framework-specific checks** for the detected framework
3. **Filter by version** — only include checks where `frameworkVersion >= minimum version`
4. **Filter by router** — for Next.js, only include App Router checks if App Router detected (and vice versa); include both if both routers detected
5. Pass the filtered check list to each agent's prompt

This ensures agents never run irrelevant checks (e.g., no `next/image` checks for Vue projects, no App Router checks for Next.js 12 projects).

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
Analyze technical SEO and meta/structured data. Framework: {{framework}} {{frameworkVersion}}. Router: {{router}}. Source root: {{sourceRoot}}.

Run ONLY these checks (filtered for this framework and version):
{{technicalChecks}}

[Quality-gates]: {{qualityGatesSummary}}. [Schema-types reference]: {{schemaTypesContent}}.
```

### Template: performance

```
Analyze performance and image optimization. Framework: {{framework}} {{frameworkVersion}}. Router: {{router}}. Source root: {{sourceRoot}}.

Run ONLY these checks (filtered for this framework and version):
{{performanceChecks}}

[Quality-gates]: {{qualityGatesSummary}}. [CWV reference]: {{cwvContent}}.
```

### Template: framework

Replaces the old `nextjs` template. Used for any framework that has a dedicated agent (Next.js, Nuxt, Gatsby, Astro). NOT spawned for plain SPAs or static HTML.

```
Analyze {{framework}}-specific patterns. Version: {{frameworkVersion}}. Router: {{router}}. Source root: {{sourceRoot}}.

Run ONLY these checks (filtered for version {{frameworkVersion}}):
{{frameworkChecks}}

[Quality-gates]: {{qualityGatesSummary}}. [Framework patterns reference]: {{frameworkPatternsContent}}.
```

**Framework patterns reference** is loaded based on detected framework:
- Next.js → `references/nextjs-patterns.md`
- Nuxt → (future: `references/nuxt-patterns.md`)
- Gatsby → (future: `references/gatsby-patterns.md`)
- Astro → (future: `references/astro-patterns.md`)

If no dedicated patterns reference exists for the framework, include the relevant checks from `references/framework-checks.md` inline in the prompt.

### Template: aeo

```
Analyze AI search readiness. Framework: {{framework}} {{frameworkVersion}}. Source root: {{sourceRoot}}.

Run ONLY these checks (all AEO checks are universal, but use framework-specific file paths):
{{aeoChecks}}

Framework-specific file paths for detection:
{{aeoFilePaths}}

[Quality-gates]: {{qualityGatesSummary}}. [AEO patterns reference]: {{aeoContent}}.
```

### Template: fix

```
Run iterative fix cycle: audit the project, classify issues by fixability, apply safe fixes, re-audit, repeat until target score ({{targetScore}}) or max iterations ({{maxIterations}}). Framework: {{framework}} {{frameworkVersion}}. Router: {{router}}. Source root: {{sourceRoot}}. [Quality-gates]: {{qualityGatesSummary}}. [Fix-classification reference]: {{fixClassificationContent}}.
```

### Variable Reference

| Variable | Source | Description |
|----------|--------|-------------|
| `{{framework}}` | Framework Detection | Detected framework name (e.g., `next`, `react`, `vue`, `nuxt`, `astro`, `gatsby`, `other`) |
| `{{frameworkVersion}}` | Framework Detection | Parsed major.minor version (e.g., `14.2`), `n/a` if not applicable |
| `{{router}}` | Framework Detection | `app`, `pages`, `both`, or `n/a` — Next.js only |
| `{{sourceRoot}}` | Source Root Detection | Path prefix for source files (e.g., `src/`, or empty) |
| `{{technicalChecks}}` | `references/framework-checks.md` | Universal + framework-specific technical checks, filtered by version and router |
| `{{performanceChecks}}` | `references/framework-checks.md` | Universal + framework-specific performance checks, filtered by version and router |
| `{{frameworkChecks}}` | `references/framework-checks.md` | Deep framework-specific checks, filtered by version and router |
| `{{aeoChecks}}` | `references/framework-checks.md` | Universal AEO checks (all apply regardless of framework) |
| `{{aeoFilePaths}}` | `references/framework-checks.md` | Framework-specific file paths for AEO detection patterns |
| `{{qualityGatesSummary}}` | `references/quality-gates.md` | Summary of scoring rules (deduction values, caps, output format) |
| `{{schemaTypesContent}}` | `references/schema-types.md` | Full content of schema-types reference |
| `{{cwvContent}}` | `references/cwv-thresholds.md` | Full content of CWV thresholds reference |
| `{{frameworkPatternsContent}}` | Framework-specific reference file | Next.js → `nextjs-patterns.md`, etc. Loaded only for frameworks with dedicated reference files |
| `{{aeoContent}}` | `references/aeo-patterns.md` | Full content of AEO patterns reference |
| `{{fixClassificationContent}}` | `references/fix-classification.md` | Full content of fix classification reference |
| `{{targetScore}}` | User argument or default | Target score for fix cycle (default: 80) |
| `{{maxIterations}}` | Default | Maximum fix-audit iterations (default: 3) |

## URL Argument Protocol

Most commands accept an optional `<url>` argument. When provided, live website analysis is performed alongside code-level analysis and the results are correlated.

### URL Validation (shared across all commands)

1. Verify the URL starts with `http://` or `https://`. If not, prepend `https://` and inform the user.
2. Reject obviously invalid URLs (no domain, localhost, IP addresses in private ranges).

### Fetching Mechanisms

Two mechanisms are used depending on what data is needed:

| Mechanism | Tool | Use case |
|-----------|------|----------|
| **HTML analysis** | WebFetch | Retrieve rendered HTML for meta tags, structured data, images, semantic structure, AEO signals |
| **Performance data** | Bash curl to PageSpeed Insights API | CrUX field data + Lighthouse lab scores. No API key needed. |

**PSI API call pattern**:
```bash
curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url={encoded_url}&strategy={mobile|desktop}&category=performance"
```

### Error Handling (shared)

**WebFetch errors**:
- Timeout / DNS error / connection refused: Report "Could not fetch URL: {error}. Verify the URL is accessible and try again." — continue with code-level results only.
- Non-HTML response: Report "The URL returned {content-type} content. Live analysis requires an HTML page." — continue with code-level results only.
- Redirect: Note the redirect chain and analyze the final destination.

**PSI API errors**:
- Network failure (curl exit code ≠ 0): Report "Could not reach PageSpeed Insights API." — continue with code-level results only.
- HTTP 429: Report "API rate limit reached. Wait a minute and try again." — continue with code-level results only.
- HTTP 400 / invalid URL: Report "PageSpeed Insights could not analyze this URL." — continue with code-level results only.
- Missing `.lighthouseResult`: Report "Unexpected API response." — continue with code-level results only.

**Key principle**: Live data failure never blocks the report. Always present code-level results and note that live data was unavailable.

### CrUX Data Extraction (shared for commands using PSI)

From the PSI mobile response:
1. Check `.loadingExperience.metrics` first (URL-level data)
2. If absent, fall back to `.originLoadingExperience.metrics` (origin-level) — note: "Using origin-level data — URL does not have enough traffic for URL-level CrUX data"
3. If neither exists: "No CrUX field data available — this site may not have enough Chrome user traffic for field metrics"
4. For each metric: extract `.percentile` (p75), `.category` (FAST/AVERAGE/SLOW), `.distributions`

Format values for readability: LCP/FCP in seconds (÷1000), INP/TTFB in ms, CLS as decimal. Round to 1 decimal place.

### Correlation Framework

When both code-level and live data are available, classify each finding:

| Category | Meaning | Action |
|----------|---------|--------|
| **Confirmed** | Code pattern flagged as risky AND live data shows the problem | Fix immediately — real users are affected |
| **Hidden** | Live data shows a problem but no code pattern found | Likely infrastructure, CDN, or third-party — investigate beyond code |
| **Latent risk** | Code pattern flagged as risky but live data is healthy | Fix proactively — prevents future regression |

## Command Routing

Parse the argument to determine which subcommand to run. If no argument is provided, default to `audit`.

### `audit [<url>]` — Full SEO Audit

Runs a comprehensive audit across all categories. This is the default command. When a URL is provided, also performs live website analysis and correlates with code findings.

**Steps**:

1. Run framework detection (Steps 1-4 above: framework, version, router, project structure)
2. Run source root detection (see Source Root Detection below)
3. Select applicable checks by consulting `references/framework-checks.md`:
   - For each agent, collect universal checks + framework-specific checks
   - Filter by `frameworkVersion` (only include checks where project version >= minimum)
   - Filter by `router` (for Next.js: App vs Pages vs both)
   - This produces `{{technicalChecks}}`, `{{performanceChecks}}`, `{{frameworkChecks}}`, `{{aeoChecks}}`, `{{aeoFilePaths}}`
4. Load reference files by reading them from the `references/` directory relative to this skill file:
   - Read `references/quality-gates.md` for scoring rules
   - Read `references/cwv-thresholds.md` for CWV reference
   - Read `references/schema-types.md` for structured data reference
   - Read `references/aeo-patterns.md` for AI search readiness reference
   - If framework has a dedicated patterns reference (e.g., Next.js → `references/nextjs-patterns.md`): read it
5. Spawn agents **in parallel** using the Agent tool. Build each agent's prompt from its Prompt Template (see Prompt Templates above), filling in all `{{variable}}` placeholders with detected values, filtered check lists, and loaded reference content.

   **All projects** (spawn 3 universal agents):
   ```
   Agent: web-seo-technical   — Template: technical (with {{technicalChecks}} for this framework)
   Agent: web-seo-performance  — Template: performance (with {{performanceChecks}} for this framework)
   Agent: web-seo-aeo          — Template: aeo (with {{aeoChecks}} + {{aeoFilePaths}} for this framework)
   ```

   **Projects with dedicated framework support** (spawn 4th agent):
   Only when framework is `next`, `nuxt`, `gatsby`, or `astro` (see Spawn Conditions in `references/framework-checks.md`):
   ```
   Agent: web-seo-framework    — Template: framework (with {{frameworkChecks}} filtered by version)
   ```
   NOT spawned for plain React, Vue, Angular, Svelte, or static HTML projects.

   **If URL provided** — run these in parallel with the agents:
   - **WebFetch** the URL for HTML analysis (meta tags, structured data, images, headings, AEO signals)
   - **PSI mobile** curl for CrUX field data + Lighthouse scores
   - **PSI desktop** curl for desktop Lighthouse scores

5. Collect results from all agents and validate completeness (see Agent Result Validation)
6. Deduplicate cross-category issues (see Agent Result Validation > Deduplication)
7. Calculate scores using quality-gates.md rules (only for categories with valid data)
8. **If URL provided** — correlate code findings with live data using the Correlation Framework (Confirmed / Hidden / Latent Risk). Add a "Live Website Correlation" section to the report after the score table showing:
   - CrUX Field Data table (p75 values, ratings, distributions)
   - Lighthouse Lab Scores table (mobile + desktop)
   - Correlation summary: confirmed issues, hidden issues, latent risks
9. Compile the unified report (see Report Format below)

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

7. **Build Verification** — After applying fixes, verify the project still builds:
   - Detect the build command from `package.json` scripts (prefer `build`, fall back to `next build`, `tsc --noEmit`)
   - Run the build command
   - If build **succeeds**: proceed to re-audit
   - If build **fails**: identify which fix(es) caused the failure from the error output, revert those fixes using the Edit tool, mark them as "failed — build broken", and proceed with the remaining fixes
   - Show build verification result: `Build verification: PASS` or `Build verification: FAIL — reverted {n} fix(es)`

8. **Re-audit** — Run the full `audit` flow again on the modified codebase. Record the new overall score and per-category scores.

9. **Show Delta** — Display a comparison:
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

10. **Loop Decision** — Stop if ANY of these conditions are met:
    - Score >= target → "Target score reached!"
    - Iteration count >= maxIterations → "Maximum iterations ({maxIterations}) reached."
    - No fixes were applied in this iteration → "No progress — all remaining issues require manual fixes."
    - Score decreased compared to previous iteration → "Score decreased ({before} → {after}). Stopping to avoid regression."

    If none met, loop back to step 4 (classify issues from the new audit, which may find new issues or confirm previous fixes resolved problems).

11. **Final Report** — After the loop ends, compile a summary:
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

### `nextjs [<url>]` — Next.js Deep Check

Run the Next.js-specific agent for a detailed framework audit. When a URL is provided, also checks the live site for Next.js-specific patterns.

**Steps**:
1. Verify this is a Next.js project (abort with message if not)
2. Run framework detection (including version and router type) and source root detection
3. Select applicable checks from `references/framework-checks.md`, filtered by detected Next.js version and router type
4. Load `references/nextjs-patterns.md` and `references/quality-gates.md`
5. Spawn agent:
   ```
   Agent: web-seo-framework — Use Template: framework. Include only version-appropriate Next.js checks.
   ```
6. **If URL provided** — WebFetch the URL (in parallel with agent) and check:
   - Response headers: `x-powered-by`, cache-control, CDN headers
   - Rendered HTML: metadata tags rendered correctly, Server Component output vs Client Component hydration markers
   - Static vs dynamic rendering indicators
   - Correlate with code findings using the Correlation Framework
7. Present results with Next.js Patterns score. If URL was provided, include a "Live Site Checks" section with header analysis and code ↔ live correlation.

### `cwv [<url>]` — Core Web Vitals Focus

Analyze code patterns affecting Core Web Vitals. When a URL is provided, also fetches CrUX field data for the three core metrics (LCP, INP, CLS).

**Steps**:
1. Run framework detection and source root detection
2. Load `references/cwv-thresholds.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — Use Template: performance, narrowed to CWV risk assessment. Include per-metric risk levels with specific file locations and code fixes.
   ```
4. **If URL provided** — fetch PSI mobile data (in parallel with agent) using curl. Extract CrUX field data for core metrics only (LCP, INP, CLS). Correlate each metric's code-level risk with its field rating using the Correlation Framework.
5. Present results with CWV Risk Assessment table and Performance score. If URL was provided, add CrUX field data alongside each code-level risk assessment and show correlation (Confirmed / Hidden / Latent Risk per metric).

### `meta [<url>]` — Meta Tags & Structured Data

Check meta tags, Open Graph, Twitter Cards, and JSON-LD structured data. When a URL is provided, also checks the rendered HTML to verify tags are present in the live page.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/schema-types.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-technical — Use Template: technical, narrowed to meta tags and structured data analysis. Validate schema types against schema.org requirements.
   ```
4. **If URL provided** — WebFetch the URL (in parallel with agent) and check rendered HTML for:
   - Title tag and meta description actually rendered
   - Open Graph and Twitter Card tags present in `<head>`
   - Canonical URL matches expected value
   - JSON-LD blocks valid and complete in rendered output
   - Correlate: code defines metadata but is it rendering correctly?
5. Present results with Meta & Structured Data score. If URL was provided, add a "Live vs Code Comparison" table showing which meta tags are defined in code vs actually rendered, highlighting any mismatches.

### `images [<url>]` — Image Optimization

Check image optimization across the project. When a URL is provided, also checks rendered image attributes on the live page.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — Use Template: performance, narrowed to image optimization analysis. Check formats, sizing, lazy loading, alt attributes, responsive images, and above-the-fold priorities.
   ```
4. **If URL provided** — WebFetch the URL (in parallel with agent) and check rendered HTML for:
   - Images with/without `alt` attributes
   - Images with/without `width`/`height` or `aspect-ratio`
   - Image formats served (WebP/AVIF vs legacy PNG/JPG)
   - Lazy loading attributes (`loading="lazy"` vs `loading="eager"`)
   - `fetchpriority` on above-the-fold images
   - Responsive image attributes (`srcset`, `sizes`)
   - Correlate: code uses `next/image` but are optimized attributes present in rendered HTML?
5. Present results with Image Optimization score. If URL was provided, add a "Live Image Audit" section showing rendered image stats and any discrepancies between code and rendered output.

### `aeo [<url>]` — AI Search Readiness

Analyze the project for AI search engine optimization (AEO). When a URL is provided, also checks the live site for AI search signals.

**Steps**:
1. Run framework detection and source root detection
2. Load `references/aeo-patterns.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-aeo — Use Template: aeo. Run a comprehensive AI search readiness audit covering all AEO patterns.
   ```
4. **If URL provided** — run these in parallel with the agent:
   - **WebFetch the URL** and check rendered HTML for: `<main>` landmark, semantic heading structure, question-format headings, entity-optimized JSON-LD (sameAs, @id, mainEntityOfPage), FAQPage/HowTo schemas, speakable markup
   - **WebFetch `{origin}/robots.txt`** and check for AI bot rules (GPTBot, ChatGPT-User, PerplexityBot, ClaudeBot, Applebot, Google-Extended, CCBot, Bytespider)
   - **WebFetch `{origin}/llms.txt`** and check if it exists and contains structured content
   - Correlate: code creates these signals but are they rendering/deployed correctly?
5. Present results with AI Search Readiness score. If URL was provided, add a "Live AEO Signals" section showing which signals are present on the live site, and highlight any gaps between code and deployed state.

### `perf [<url>]` — Performance Analysis

Analyze performance from code and — when a URL is provided — correlate with real-world field data from PageSpeed Insights.

**Two modes**:
- `perf` (no URL) — **Repo only**: code-level CWV analysis of the project source
- `perf <url>` — **Repo + Live**: code-level analysis PLUS CrUX field data and Lighthouse lab scores from PageSpeed Insights

#### Mode 1: Repo Only (`perf` with no URL)

**Steps**:

1. Run framework detection and source root detection
2. Load `references/cwv-thresholds.md` and `references/quality-gates.md`
3. Spawn agent:
   ```
   Agent: web-seo-performance — Use Template: performance, narrowed to CWV risk assessment. Include per-metric risk levels with specific file locations and code fixes.
   ```
4. Present results with:
   - CWV Risk Assessment table (LCP / INP / CLS risk levels with key factors)
   - Performance score
   - All issues sorted by priority with file paths and fixes
   - CTA: "Run `/web-seo-audit perf <url>` to compare these code patterns against real-world field data."

#### Mode 2: Repo + Live (`perf <url>`)

Run code-level analysis AND fetch live performance data, then correlate the findings.

**Steps**:

1. **Validate the URL**:
   1.1. Verify the URL starts with `http://` or `https://`. If not, prepend `https://` and inform the user
   1.2. Reject obviously invalid URLs (no domain, localhost, IP addresses in private ranges)

2. **Run code-level analysis and PSI fetches in parallel**:

   **Code-level** (same as Mode 1):
   - Run framework detection and source root detection
   - Load `references/cwv-thresholds.md` and `references/quality-gates.md`
   - Spawn agent:
     ```
     Agent: web-seo-performance — Use Template: performance, narrowed to CWV risk assessment. Include per-metric risk levels with specific file locations and code fixes.
     ```

   **PSI mobile fetch** via Bash curl (run in parallel with the agent):
   ```bash
   curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url={encoded_url}&strategy=mobile&category=performance"
   ```

   **PSI desktop fetch** via Bash curl (run in parallel with the agent):
   ```bash
   curl -s "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url={encoded_url}&strategy=desktop&category=performance"
   ```

   **Handle PSI errors**:
   - Network failure (curl exit code ≠ 0): Report "Could not reach PageSpeed Insights API. Check your network connection." — continue with code-level results only
   - HTTP 429: Report "API rate limit reached. Wait a minute and try again." — continue with code-level results only
   - HTTP 400 / invalid URL in response: Report "PageSpeed Insights could not analyze this URL. Verify it is publicly accessible." — continue with code-level results only
   - Response missing `.lighthouseResult`: Report "Unexpected API response." — continue with code-level results only

   If PSI fails, present Mode 1 results and note: "Live data unavailable — showing code-level analysis only."

3. **Extract CrUX field data** from the mobile PSI response:
   - Check `.loadingExperience.metrics` first (URL-level data)
   - If absent or empty, fall back to `.originLoadingExperience.metrics` (origin-level) and note: "Using origin-level data — URL does not have enough traffic for URL-level CrUX data"
   - If neither exists: report "No CrUX field data available — this site may not have enough Chrome user traffic for field metrics"
   - For each available metric (LARGEST_CONTENTFUL_PAINT_MS, INTERACTION_TO_NEXT_PAINT, CUMULATIVE_LAYOUT_SHIFT, FIRST_CONTENTFUL_PAINT_MS, EXPERIMENTAL_TIME_TO_FIRST_BYTE):
     - Extract `.percentile` (p75 value)
     - Extract `.category` (FAST / AVERAGE / SLOW)
     - Extract `.distributions` array (proportions for good / needs-improvement / poor)

4. **Extract Lighthouse lab scores** from `.lighthouseResult` (both mobile and desktop):
   - Overall performance score: `.categories.performance.score` × 100
   - Individual audit values:
     - LCP: `.audits["largest-contentful-paint"].numericValue`
     - CLS: `.audits["cumulative-layout-shift"].numericValue`
     - TBT: `.audits["total-blocking-time"].numericValue`
     - FCP: `.audits["first-contentful-paint"].numericValue`
     - Speed Index: `.audits["speed-index"].numericValue`

5. **Extract top opportunities** from `.lighthouseResult.audits` in the mobile response:
   - Filter audits where `.score` is not null and `.score < 1`
   - Sort by `.score` ascending (worst first)
   - Include up to 10 opportunities with: audit title, score, displayValue (savings estimate)

6. **Correlate code-level findings with live data**:
   - For each CWV metric (LCP, INP/TBT, CLS), match the code-level risk assessment against the field/lab result
   - Highlight **confirmed issues**: code pattern flagged as risky AND field data shows AVERAGE/SLOW
   - Highlight **hidden issues**: field data shows AVERAGE/SLOW but no code pattern found (may be infrastructure, CDN, or third-party related)
   - Highlight **latent risks**: code pattern flagged as risky but field data is FAST (fix before it regresses)

7. **Present the combined report**:

   ```markdown
   # Performance Report: {project name}

   **Date**: {current date}
   **URL analyzed**: {url}
   **Data sources**: Code analysis + CrUX field data + Lighthouse lab data

   ---

   ## CrUX Field Data (Real Users) — {URL-level | Origin-level}

   | Metric | p75 Value | Rating | Good | Needs Improvement | Poor |
   |--------|-----------|--------|------|-------------------|------|
   | LCP | {value}s | {FAST/AVERAGE/SLOW} | {%} | {%} | {%} |
   | INP | {value}ms | {FAST/AVERAGE/SLOW} | {%} | {%} | {%} |
   | CLS | {value} | {FAST/AVERAGE/SLOW} | {%} | {%} | {%} |
   | FCP | {value}s | {FAST/AVERAGE/SLOW} | {%} | {%} | {%} |
   | TTFB | {value}ms | {FAST/AVERAGE/SLOW} | {%} | {%} | {%} |

   **Overall CWV Assessment**: {PASS if LCP + INP + CLS all FAST, else FAIL}

   ---

   ## Lighthouse Lab Scores

   | Metric | Mobile | Desktop |
   |--------|--------|---------|
   | Performance Score | {score}/100 | {score}/100 |
   | LCP | {value}s | {value}s |
   | CLS | {value} | {value} |
   | TBT | {value}ms | {value}ms |
   | FCP | {value}s | {value}s |
   | Speed Index | {value}s | {value}s |

   ---

   ## Code ↔ Field Correlation

   ### Confirmed Issues
   Code patterns causing real-world impact:
   {List issues where code risk matches field AVERAGE/SLOW, with file paths and fixes}

   ### Hidden Issues
   Field data problems not visible in code (infrastructure, CDN, third-party):
   {List metrics that are AVERAGE/SLOW but have no matching code pattern}

   ### Latent Risks
   Code patterns that haven't impacted field data yet:
   {List code issues where field data is still FAST — fix before regression}

   ---

   ## Top Lighthouse Opportunities

   | Opportunity | Potential Savings |
   |-------------|-------------------|
   | {audit title} | {displayValue} |
   | ... | ... |

   ---

   ## All Code-Level Issues

   {Full issue list from the performance agent, sorted by priority}
   ```

   Format CrUX values for readability: LCP/FCP in seconds (÷1000), INP/TTFB in ms, CLS as decimal. Round to 1 decimal place. Map CrUX categories to visual indicators: FAST = Good, AVERAGE = Needs Improvement, SLOW = Poor.

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
- `web-seo-framework`: Must contain **{{framework}} Patterns** (e.g., "Next.js Patterns", "Nuxt Patterns") with framework-specific context echoed (e.g., router type for Next.js)
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
| {Framework} Patterns | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Meta & Structured Data | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| Image Optimization | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |
| AI Search Readiness | {score}/100 | {PASS/WARNING/FAIL} | {n}C {n}H {n}M {n}L |

> Omit the "{Framework} Patterns" row when no framework agent was spawned (plain SPAs, static HTML).

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
4. Overall score = weighted average based on whether a framework agent was spawned, rounded to nearest integer (half-up). With framework agent (Next.js, Nuxt, Gatsby, Astro): Technical 22%, Performance 22%, Framework Patterns 18%, Meta 18%, Images 10%, AEO 10%. Without framework agent (React, Vue, Angular, Svelte, static): Technical 27%, Performance 27%, Meta 23%, Images 13%, AEO 10%.
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
