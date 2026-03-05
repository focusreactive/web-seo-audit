# Agent Output Schema

## Overview

Every agent MUST include a machine-readable JSON summary block at the end of its output, inside a fenced code block tagged `agent-output`. The orchestrator extracts scores and issues from this JSON — not from parsing markdown headings. The markdown portion of the output is for human consumption only.

## Schema

```json
{
  "categories": [
    {
      "name": "Technical SEO",
      "score": 77,
      "issueCount": { "critical": 0, "high": 1, "medium": 4, "low": 3 },
      "issues": [
        {
          "id": "missing-sitemap:site-wide",
          "severity": "HIGH",
          "category": "Technical SEO",
          "title": "No sitemap.xml or robots.txt",
          "location": "site-wide",
          "problem": "No sitemap or robots.txt found.",
          "impact": "Search engines have no guidance on which pages to crawl.",
          "fix": "Add app/sitemap.ts and app/robots.ts.",
          "fixability": "confirm-fix",
          "effort": "small",
          "confidence": "HIGH"
        }
      ]
    }
  ],
  "cwvRisk": {
    "lcp": { "level": "MEDIUM", "factors": ["Hero image missing priority", "Client-side data fetching"] },
    "inp": { "level": "LOW", "factors": ["Lightweight event handlers"] },
    "cls": { "level": "HIGH", "factors": ["12 images missing dimensions"] }
  }
}
```

## Field Definitions

### Category Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Exact category name matching the scoring system |
| `score` | number | Yes | Calculated score 0-100 after applying deductions |
| `issueCount` | object | Yes | Counts by severity: `{ critical, high, medium, low }` |
| `issues` | array | Yes | All issues found for this category |

### Issue Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Canonical ID: `{check-name}:{file-path}:{line}` or `{check-name}:site-wide` |
| `severity` | string | Yes | `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` |
| `category` | string | Yes | Category this issue is scored under |
| `title` | string | Yes | Brief description (same as markdown heading) |
| `location` | string | Yes | File path with line number or `site-wide` |
| `problem` | string | Yes | What is wrong and why it matters |
| `impact` | string | Yes | How this affects SEO, performance, or UX |
| `fix` | string | Yes | Specific action to resolve |
| `fixability` | string | Yes | `auto-fix` / `confirm-fix` / `manual` |
| `effort` | string | Yes | `trivial` / `small` / `medium` / `large` |
| `confidence` | string | Yes | `HIGH` / `MEDIUM` / `LOW` |
| `suppressed` | boolean | No | `true` if matched by `.seo-audit-ignore` rules |

### CWV Risk Object (performance agent only)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `lcp` | object | Yes | `{ level: "LOW/MEDIUM/HIGH", factors: [...] }` |
| `inp` | object | Yes | Same structure |
| `cls` | object | Yes | Same structure |

## Agent-Specific Requirements

| Agent | Required Categories |
|-------|-------------------|
| `web-seo-technical` | "Technical SEO", "Meta & Structured Data" |
| `web-seo-performance` | "Performance", "Image Optimization" (+ `cwvRisk` object) |
| `web-seo-aeo` | "AI Search Readiness" |
| `web-seo-framework` | "{Framework} Patterns" (e.g., "Next.js Patterns") |

## Validation Rules

The orchestrator validates each agent's JSON block:
1. All required fields must be present
2. `score` must be 0-100
3. `severity` must be one of the four valid values
4. `issueCount` must match the actual count of issues in the array
5. If validation fails, fall back to markdown parsing and add a warning: "Score derived from markdown parsing — may be imprecise"
