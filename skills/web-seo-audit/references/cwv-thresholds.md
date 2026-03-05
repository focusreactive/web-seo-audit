# Core Web Vitals Thresholds & Optimization Reference

## Overview

Core Web Vitals (CWV) are Google's metrics for measuring real-world user experience. They directly impact search rankings. This reference covers current thresholds, code patterns that affect each metric, and optimization strategies.

> **IMPORTANT**: INP (Interaction to Next Paint) replaced FID (First Input Delay) as a Core Web Vital in March 2024. Never reference FID in audits. Always use INP.

## Current Core Web Vitals

### LCP — Largest Contentful Paint

Measures loading performance. Time until the largest content element is visible.

| Rating | Threshold |
|--------|-----------|
| Good | ≤ 2.5s |
| Needs Improvement | 2.5s – 4.0s |
| Poor | > 4.0s |

**Common LCP Elements**: `<img>`, `<video>`, elements with `background-image`, block-level text elements.

#### Code Patterns That Hurt LCP

```tsx
// BAD: Lazy-loading above-the-fold hero image
<img src="hero.jpg" loading="lazy" />

// BAD: Not preloading critical image
// (missing <link rel="preload"> for hero image)

// BAD: CSS background image for hero (not discoverable by preload scanner)
.hero { background-image: url('/hero.jpg'); }

// BAD: Client-side data fetching before rendering content
useEffect(() => {
  fetch('/api/content').then(data => setContent(data));
}, []);

// BAD: Render-blocking CSS/JS in <head>
<link rel="stylesheet" href="non-critical.css" />
<script src="analytics.js"></script>

// BAD: Unoptimized image (no width/height, no srcset, no modern format)
<img src="photo.png" />

// BAD: Web fonts blocking text rendering
@font-face {
  font-family: 'Custom';
  src: url('font.woff2');
  /* missing font-display */
}
```

#### Code Patterns That Help LCP

```tsx
// GOOD: Eager-load above-the-fold images with priority
<img src="hero.webp" fetchpriority="high" />
// Next.js:
<Image src="/hero.webp" priority alt="Hero" />

// GOOD: Preload critical resources
<link rel="preload" href="/hero.webp" as="image" />
<link rel="preload" href="/font.woff2" as="font" type="font/woff2" crossorigin />

// GOOD: Server-side rendering or static generation for content
// Next.js App Router: Server Components (default)
// Next.js Pages Router: getStaticProps / getServerSideProps

// GOOD: Inline critical CSS, defer non-critical
<link rel="preload" href="non-critical.css" as="style" onload="this.rel='stylesheet'" />

// GOOD: Responsive images with modern formats
<picture>
  <source srcset="hero.avif" type="image/avif" />
  <source srcset="hero.webp" type="image/webp" />
  <img src="hero.jpg" width="1200" height="600" alt="Hero" />
</picture>

// GOOD: Font display swap
@font-face {
  font-family: 'Custom';
  src: url('font.woff2') format('woff2');
  font-display: swap;
}
```

#### LCP Optimization Strategies

1. **Preload the LCP resource** — Add `<link rel="preload">` for the largest image/element
2. **Use SSR/SSG** — Don't rely on client-side JS to render main content
3. **Optimize images** — WebP/AVIF, proper sizing, responsive srcset
4. **Eliminate render-blocking resources** — Defer non-critical CSS/JS
5. **Use CDN** — Serve static assets from edge locations
6. **Minimize server response time** — Target TTFB < 800ms

---

### INP — Interaction to Next Paint

Measures responsiveness. Time from user interaction to the next visual update.

| Rating | Threshold |
|--------|-----------|
| Good | ≤ 200ms |
| Needs Improvement | 200ms – 500ms |
| Poor | > 500ms |

#### Code Patterns That Hurt INP

```tsx
// BAD: Heavy synchronous computation in event handlers
function handleClick() {
  const result = heavyComputation(largeDataSet); // blocks main thread
  setState(result);
}

// BAD: Synchronous layout thrashing
function handleScroll() {
  elements.forEach(el => {
    const height = el.offsetHeight; // forces layout
    el.style.height = height + 10 + 'px'; // triggers layout again
  });
}

// BAD: Large React component trees re-rendering on interaction
function Parent() {
  const [count, setCount] = useState(0);
  return (
    <div onClick={() => setCount(c => c + 1)}>
      <HeavyChildA />  {/* re-renders unnecessarily */}
      <HeavyChildB />  {/* re-renders unnecessarily */}
      <Counter count={count} />
    </div>
  );
}

// BAD: Third-party scripts running on main thread during interaction
<script src="https://heavy-analytics.com/tracker.js"></script>

// BAD: Unthrottled input handlers
input.addEventListener('input', (e) => {
  expensiveSearch(e.target.value);
});
```

#### Code Patterns That Help INP

```tsx
// GOOD: Defer heavy work with startTransition or requestIdleCallback
import { startTransition } from 'react';
function handleClick() {
  startTransition(() => {
    setState(heavyComputation(data));
  });
}

// GOOD: Use web workers for heavy computation
const worker = new Worker('/compute-worker.js');
function handleClick(data) {
  worker.postMessage(data);
}

// GOOD: Memoize expensive child components
const HeavyChildA = React.memo(function HeavyChildA() { ... });
const HeavyChildB = React.memo(function HeavyChildB() { ... });

// GOOD: Debounce input handlers
const debouncedSearch = useMemo(
  () => debounce((query) => search(query), 300),
  []
);

// GOOD: Use CSS transitions instead of JS animations
.element {
  transition: transform 0.3s ease;
  will-change: transform;
}

// GOOD: Load third-party scripts with defer/async or after interaction
<script src="analytics.js" defer></script>
// Or use next/script with strategy="lazyOnload"
```

#### INP Optimization Strategies

1. **Break up long tasks** — Keep event handlers under 50ms, defer heavy work
2. **Reduce React re-renders** — `React.memo`, `useMemo`, `useCallback`, proper state splitting
3. **Use `startTransition`** — Mark non-urgent state updates as transitions
4. **Minimize main thread work** — Move computation to Web Workers
5. **Debounce/throttle input handlers** — Avoid processing every keystroke
6. **Reduce DOM size** — Fewer nodes = faster style/layout recalculation
7. **Defer third-party scripts** — Use `async`, `defer`, or lazy loading

---

### CLS — Cumulative Layout Shift

Measures visual stability. Sum of unexpected layout shift scores during page lifecycle.

| Rating | Threshold |
|--------|-----------|
| Good | ≤ 0.1 |
| Needs Improvement | 0.1 – 0.25 |
| Poor | > 0.25 |

#### Code Patterns That Hurt CLS

```tsx
// BAD: Images without dimensions
<img src="photo.jpg" />
// Browser can't reserve space before image loads

// BAD: Dynamically injected content above existing content
useEffect(() => {
  setBanner(<PromoBanner />); // pushes content down after render
}, []);

// BAD: Web fonts causing text reflow (FOUT)
@font-face {
  font-family: 'Custom';
  src: url('font.woff2');
  font-display: swap; /* swap can cause layout shift if metrics differ */
}

// BAD: Ads or embeds without reserved space
<div id="ad-slot"></div>
// Ad loads later, expands, shifts content

// BAD: Dynamic content loaded via client-side fetch without skeleton
function Page() {
  const [data, setData] = useState(null);
  useEffect(() => { fetch('/api/data').then(...) }, []);
  if (!data) return null; // shows nothing, then shifts
  return <Content data={data} />;
}
```

#### Code Patterns That Help CLS

```tsx
// GOOD: Always set explicit dimensions on images/video
<img src="photo.jpg" width="800" height="600" alt="Photo" />
// Next.js: Image component handles this automatically
<Image src="/photo.jpg" width={800} height={600} alt="Photo" />

// GOOD: Reserve space for dynamic content
<div style={{ minHeight: '250px' }}>
  {banner && <PromoBanner />}
</div>

// GOOD: Use CSS aspect-ratio for responsive containers
.video-container {
  aspect-ratio: 16 / 9;
  width: 100%;
}

// GOOD: Use size-adjust or font metrics override to reduce FOUT shift
@font-face {
  font-family: 'Custom';
  src: url('font.woff2') format('woff2');
  font-display: swap;
  size-adjust: 105%;
  ascent-override: 90%;
}
// Or better: use next/font which handles this automatically

// GOOD: Show skeleton/placeholder during loading
function Page() {
  const [data, setData] = useState(null);
  useEffect(() => { fetch('/api/data').then(...) }, []);
  if (!data) return <ContentSkeleton />;
  return <Content data={data} />;
}

// GOOD: Use transform for animations (doesn't trigger layout)
.animate {
  transform: translateY(-10px); /* no layout shift */
}
```

#### CLS Optimization Strategies

1. **Always set image/video dimensions** — `width` and `height` attributes or CSS `aspect-ratio`
2. **Reserve space for dynamic content** — Skeletons, `min-height`, aspect-ratio boxes
3. **Avoid injecting content above the fold** — Banners, cookie notices should use fixed/sticky positioning
4. **Use `next/font`** — Automatic font metric overrides prevent FOUT shifts
5. **Preload fonts** — Reduce swap-induced layout shifts
6. **Use `content-visibility: auto`** — For off-screen content, prevents it from affecting layout
7. **Avoid `document.write()`** — Synchronous DOM manipulation causes shifts

---

## Supplementary Metrics

These are not Core Web Vitals but affect overall performance scoring:

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| TTFB (Time to First Byte) | ≤ 800ms | 800ms – 1800ms | > 1800ms |
| FCP (First Contentful Paint) | ≤ 1.8s | 1.8s – 3.0s | > 3.0s |
| TBT (Total Blocking Time) | ≤ 200ms | 200ms – 600ms | > 600ms |
| Speed Index | ≤ 3.4s | 3.4s – 5.8s | > 5.8s |

## Code Analysis Heuristics

When analyzing code (not live metrics), use these heuristics to estimate CWV risk:

### SSG / JAMstack Baseline

Static site generators (Eleventy, Hugo, Jekyll, Gatsby static, Astro static) serve pre-built HTML from CDN. This provides an inherent LCP advantage — content is in the HTML without server rendering or JS hydration. When assessing CWV risk for SSGs:
- Do NOT flag "No SSR/SSG" — SSGs ARE pre-rendered by definition
- Legacy JS libraries (jQuery, GSAP) affect INP but have lower LCP impact than on SPAs — downgrade severity unless render-blocking
- Bundle size concerns are reduced — no hydration bundle. Focus on render-blocking scripts
- Image optimization and CLS issues affect SSGs equally — do not downgrade these

### LCP Risk Indicators
- No SSR/SSG for main content → HIGH risk (does NOT apply to SSGs — they are pre-rendered)
- Hero image without `priority` or `fetchpriority="high"` → MEDIUM risk
- No image optimization (raw PNG/JPG, no srcset) → MEDIUM risk
- Render-blocking scripts in `<head>` → HIGH risk
- Client-side data fetching for above-the-fold content → HIGH risk

### INP Risk Indicators
- Event handlers with synchronous computation > 50ms → HIGH risk
- No `React.memo` on frequently re-rendered components → MEDIUM risk
- Inline third-party scripts without `defer`/`async` → MEDIUM risk
- No debouncing on input/search handlers → LOW risk
- Large DOM tree (>1500 nodes) → MEDIUM risk

### CLS Risk Indicators
- `<img>` without `width`/`height` → HIGH risk
- Dynamic content injection without reserved space → HIGH risk
- Web fonts without `font-display` or `next/font` → MEDIUM risk
- CSS animations using `top`/`left`/`width`/`height` that run on page load without user interaction → MEDIUM risk (user-triggered transitions do NOT affect CLS — CLS excludes shifts within 500ms of user input)
- No skeleton/loading states for async content → MEDIUM risk

---

## Field Data Interpretation (CrUX / PageSpeed Insights)

CrUX (Chrome User Experience Report) provides real-world performance data collected from opted-in Chrome users. The PageSpeed Insights API returns both CrUX field data and Lighthouse lab data in a single response.

### CrUX Assessment Categories

CrUX reports each metric with a category and distribution:

| CrUX Category | Maps To | Meaning |
|---------------|---------|---------|
| FAST | Good | p75 is within the "Good" threshold |
| AVERAGE | Needs Improvement | p75 is between "Good" and "Poor" thresholds |
| SLOW | Poor | p75 exceeds the "Poor" threshold |

### Overall Core Web Vitals Pass Rule

A URL **passes** Core Web Vitals assessment when all three core metrics meet the "Good" threshold at the 75th percentile:

| Metric | Must be | Threshold |
|--------|---------|-----------|
| LCP | FAST | p75 ≤ 2.5s |
| INP | FAST | p75 ≤ 200ms |
| CLS | FAST | p75 ≤ 0.1 |

If **any** of the three is AVERAGE or SLOW, the overall assessment is **FAIL**.

### Field vs Lab Data Comparison

| Aspect | Field Data (CrUX) | Lab Data (Lighthouse) |
|--------|-------------------|----------------------|
| **Source** | Real Chrome users over 28-day rolling window | Simulated page load in controlled environment |
| **Conditions** | Varied devices, networks, locations | Fixed device emulation (Moto G Power on 4G for mobile) |
| **Metrics** | LCP, INP, CLS, FCP, TTFB | LCP, CLS, TBT (proxy for INP), FCP, Speed Index |
| **Use case** | Understand actual user experience | Debug specific issues, measure impact of changes |
| **Updates** | Daily (28-day rolling) | Instant (per-run) |
| **Coverage** | Only sites with sufficient Chrome traffic | Any publicly accessible URL |

> **Note**: Lab data uses TBT (Total Blocking Time) as a proxy for INP. They correlate but are not equivalent — TBT measures total main-thread blocking during load, while INP measures worst-case interaction responsiveness throughout the page lifecycle.

### Distribution Interpretation

CrUX provides the percentage of page loads in each bucket (good / needs-improvement / poor). Even if the p75 is categorized as AVERAGE, a high proportion in the "poor" bucket signals serious issues:

- **>75% Good**: Healthy — most users have a good experience
- **>25% Poor**: Critical — more than 1 in 4 users hit the "poor" threshold, even if p75 is AVERAGE
- **Bimodal distribution** (high Good AND high Poor, low middle): Likely a device/network segmentation issue — mobile users on slow connections vs desktop on fast

### URL-Level vs Origin-Level Data

CrUX data is available at two granularities:

| Level | Source field | Description |
|-------|-------------|-------------|
| **URL-level** | `.loadingExperience.metrics` | Data for the specific URL — most relevant for per-page analysis |
| **Origin-level** | `.originLoadingExperience.metrics` | Aggregated data across the entire origin (domain) — broader view |

**Resolution rules**:
1. **Prefer URL-level data** — it reflects the specific page's real performance
2. **Fall back to origin-level** if URL-level is absent — note this in the report as "Origin-level (URL lacks sufficient traffic)"
3. **If neither exists** — the site does not have enough Chrome traffic for CrUX data. Report this clearly and rely on lab data only
