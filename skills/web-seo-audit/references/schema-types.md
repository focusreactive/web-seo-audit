# Structured Data (JSON-LD) Reference

## Overview

Structured data helps search engines understand page content and can enable rich results (rich snippets, knowledge panels, carousels). JSON-LD is the recommended format. This reference covers priority schema types, required properties, and Next.js implementation patterns.

## General Rules

1. **Always use JSON-LD format** — Google recommends JSON-LD over Microdata or RDFa
2. **Place in `<head>` or `<body>`** — Both are valid, but `<head>` is conventional
3. **One primary entity per page** — Additional supporting types are fine (e.g., BreadcrumbList alongside Article)
4. **Validate with Google Rich Results Test** — https://search.google.com/test/rich-results
5. **Use absolute URLs** — All URL properties must be fully qualified

---

## Priority Schema Types

### 1. Organization

**Use on**: Homepage or about page
**Rich result**: Knowledge Panel, logo in search results

**Required properties**:
- `@type`: "Organization"
- `name`: Organization name
- `url`: Homepage URL

**Recommended properties**:
- `logo`: URL to organization logo (min 112x112px, square)
- `sameAs`: Array of social media profile URLs
- `contactPoint`: Customer service contact info
- `description`: Short description of the organization
- `foundingDate`: ISO 8601 date

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Example Company",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "description": "We build tools for developers.",
  "foundingDate": "2020-01-15",
  "sameAs": [
    "https://twitter.com/example",
    "https://linkedin.com/company/example",
    "https://github.com/example"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-555-5555",
    "contactType": "customer service",
    "availableLanguage": ["English"]
  }
}
```

### 2. WebSite

**Use on**: Homepage
**Rich result**: Sitelinks search box

**Required properties**:
- `@type`: "WebSite"
- `name`: Site name
- `url`: Homepage URL

**Recommended properties**:
- `potentialAction`: SearchAction for sitelinks search box
- `description`: Site description

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "name": "Example",
  "url": "https://example.com",
  "description": "Developer tools and resources",
  "potentialAction": {
    "@type": "SearchAction",
    "target": {
      "@type": "EntryPoint",
      "urlTemplate": "https://example.com/search?q={search_term_string}"
    },
    "query-input": "required name=search_term_string"
  }
}
```

### 3. Article / BlogPosting / NewsArticle

**Use on**: Blog posts, news articles, editorial content
**Rich result**: Article rich result with headline, image, date

**Required properties**:
- `@type`: "Article" (or "BlogPosting", "NewsArticle")
- `headline`: Article title (max 110 characters)
- `image`: Representative image(s)
- `datePublished`: ISO 8601 date
- `author`: Person or Organization

**Recommended properties**:
- `dateModified`: Last modified date
- `description`: Article summary
- `publisher`: Organization with logo
- `mainEntityOfPage`: URL of the page

```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "How to Optimize Core Web Vitals",
  "image": ["https://example.com/images/cwv-guide.jpg"],
  "datePublished": "2024-06-15T08:00:00+00:00",
  "dateModified": "2024-07-01T10:30:00+00:00",
  "author": {
    "@type": "Person",
    "name": "Jane Smith",
    "url": "https://example.com/authors/jane-smith"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Example Blog",
    "logo": {
      "@type": "ImageObject",
      "url": "https://example.com/logo.png"
    }
  },
  "description": "A comprehensive guide to improving LCP, INP, and CLS.",
  "mainEntityOfPage": {
    "@type": "WebPage",
    "@id": "https://example.com/blog/optimize-cwv"
  }
}
```

### 4. BreadcrumbList

**Use on**: Any page with breadcrumb navigation
**Rich result**: Breadcrumb trail in search results

**Required properties**:
- `@type`: "BreadcrumbList"
- `itemListElement`: Array of ListItem objects with `position`, `name`, `item` (URL)

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Home", "item": "https://example.com" },
    { "@type": "ListItem", "position": 2, "name": "Blog", "item": "https://example.com/blog" },
    { "@type": "ListItem", "position": 3, "name": "Core Web Vitals Guide" }
  ]
}
```

Note: The last item should omit `item` (URL) as it represents the current page.

### 5. FAQPage

**Use on**: FAQ pages, pages with Q&A sections
**Rich result**: Expandable FAQ in search results

**Required properties**:
- `@type`: "FAQPage"
- `mainEntity`: Array of Question objects, each with `acceptedAnswer`

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What are Core Web Vitals?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Core Web Vitals are a set of metrics that measure real-world user experience: LCP (loading), INP (interactivity), and CLS (visual stability)."
      }
    },
    {
      "@type": "Question",
      "name": "How do I measure Core Web Vitals?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Use Google PageSpeed Insights, Chrome DevTools, or the web-vitals JavaScript library."
      }
    }
  ]
}
```

### 6. Product

**Use on**: Product pages, e-commerce
**Rich result**: Price, availability, reviews in search results

**Required properties**:
- `@type`: "Product"
- `name`: Product name
- `image`: Product image(s)

**Recommended properties**:
- `description`: Product description
- `offers`: Pricing and availability
- `aggregateRating`: Review summary
- `brand`: Brand information
- `sku` / `gtin`: Product identifiers

```json
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Performance Monitoring Tool",
  "image": ["https://example.com/product.jpg"],
  "description": "Real-time web performance monitoring.",
  "brand": { "@type": "Brand", "name": "Example" },
  "sku": "PMT-001",
  "offers": {
    "@type": "Offer",
    "url": "https://example.com/product",
    "priceCurrency": "USD",
    "price": "29.99",
    "availability": "https://schema.org/InStock",
    "priceValidUntil": "2025-12-31"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "156"
  }
}
```

### 7. LocalBusiness

**Use on**: Local business pages
**Rich result**: Business info in Maps and Search

**Required properties**:
- `@type`: Specific subtype (e.g., "Restaurant", "Store", "MedicalBusiness")
- `name`: Business name
- `address`: PostalAddress object

**Recommended properties**:
- `telephone`, `openingHoursSpecification`, `geo`, `image`, `priceRange`, `url`

```json
{
  "@context": "https://schema.org",
  "@type": "Restaurant",
  "name": "Example Cafe",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "San Francisco",
    "addressRegion": "CA",
    "postalCode": "94102",
    "addressCountry": "US"
  },
  "telephone": "+1-555-555-5555",
  "url": "https://example-cafe.com",
  "image": "https://example-cafe.com/storefront.jpg",
  "priceRange": "$$",
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "07:00",
      "closes": "22:00"
    }
  ],
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": 37.7749,
    "longitude": -122.4194
  }
}
```

### 8. HowTo

**Use on**: Tutorial/guide pages with step-by-step instructions
**Rich result**: Step-by-step instructions in search results

**Required properties**:
- `@type`: "HowTo"
- `name`: Title of the how-to
- `step`: Array of HowToStep objects

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Optimize Images for Web",
  "description": "A step-by-step guide to optimizing images for better web performance.",
  "totalTime": "PT15M",
  "step": [
    {
      "@type": "HowToStep",
      "name": "Choose the right format",
      "text": "Use WebP for photographs and AVIF for modern browsers. Use SVG for icons and logos.",
      "image": "https://example.com/step1.jpg"
    },
    {
      "@type": "HowToStep",
      "name": "Resize to display dimensions",
      "text": "Never serve images larger than their display size. Use srcset for responsive images.",
      "image": "https://example.com/step2.jpg"
    },
    {
      "@type": "HowToStep",
      "name": "Compress images",
      "text": "Use tools like Sharp, Squoosh, or ImageOptim to compress without visible quality loss.",
      "image": "https://example.com/step3.jpg"
    }
  ]
}
```

### 9. VideoObject

**Use on**: Pages with video content
**Rich result**: Video thumbnails in search results

**Required properties**:
- `@type`: "VideoObject"
- `name`: Video title
- `thumbnailUrl`: Thumbnail image
- `uploadDate`: ISO 8601 date

**Recommended properties**:
- `description`, `duration` (ISO 8601), `contentUrl`, `embedUrl`

```json
{
  "@context": "https://schema.org",
  "@type": "VideoObject",
  "name": "Core Web Vitals Explained",
  "description": "A 10-minute introduction to LCP, INP, and CLS.",
  "thumbnailUrl": "https://example.com/video-thumb.jpg",
  "uploadDate": "2024-06-15T08:00:00+00:00",
  "duration": "PT10M30S",
  "contentUrl": "https://example.com/videos/cwv-explained.mp4",
  "embedUrl": "https://www.youtube.com/embed/abc123"
}
```

### 10. SoftwareApplication

**Use on**: Software product pages, app landing pages
**Rich result**: App info with rating in search results

**Required properties**:
- `@type`: "SoftwareApplication"
- `name`: Application name
- `operatingSystem` or `applicationCategory`

**Recommended properties**:
- `offers`, `aggregateRating`, `screenshot`, `description`

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "PerformanceBot",
  "operatingSystem": "Web",
  "applicationCategory": "DeveloperApplication",
  "description": "Automated web performance monitoring and alerting.",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.6",
    "ratingCount": "89"
  }
}
```

---

## Next.js Implementation Patterns

### App Router — JSON-LD in Server Component

```tsx
// app/blog/[slug]/page.tsx
export default async function BlogPost({ params }) {
  const post = await getPost(params.slug);

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    image: [post.image],
    datePublished: post.publishedAt,
    dateModified: post.updatedAt,
    author: { '@type': 'Person', name: post.author.name },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article>
        <h1>{post.title}</h1>
        {/* ... */}
      </article>
    </>
  );
}
```

### App Router — Reusable JSON-LD Component

```tsx
// components/json-ld.tsx
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

// Usage in page:
<JsonLd data={articleSchema} />
<JsonLd data={breadcrumbSchema} />
```

### Pages Router — JSON-LD with next/head

```tsx
// pages/blog/[slug].tsx
import Head from 'next/head';

export default function BlogPost({ post }) {
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    image: [post.image],
    datePublished: post.publishedAt,
    author: { '@type': 'Person', name: post.author.name },
  };

  return (
    <>
      <Head>
        <title>{post.title}</title>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </Head>
      <article>
        <h1>{post.title}</h1>
      </article>
    </>
  );
}
```

---

## Validation Rules

### Common Mistakes to Check For

1. **Missing `@context`** — Every JSON-LD block must include `"@context": "https://schema.org"`
2. **Relative URLs** — All URLs must be absolute (start with `https://`)
3. **Missing required properties** — Check each type's required fields above
4. **Mismatched types** — Using "Article" when "BlogPosting" is more specific
5. **Empty or placeholder values** — Properties with empty strings or "TODO"
6. **Invalid dates** — Must be ISO 8601 format
7. **Invalid JSON** — Trailing commas, unquoted keys, template literal issues
8. **Duplicate schemas** — Multiple Organization or WebSite schemas on one page
9. **Schema on wrong page type** — Product schema on non-product pages
10. **Missing image dimensions** — ImageObject without width/height

### Detection Patterns

```
# Find all JSON-LD blocks
grep "application/ld\+json" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}

# Find inline structured data objects
grep "@context.*schema.org|@type.*Organization|@type.*Article|@type.*Product" app/**/*.{tsx,jsx} pages/**/*.{tsx,jsx} components/**/*.{tsx,jsx}

# Check for schema libraries
grep "schema-dts|next-seo|next-sitemap" package.json
```

### Recommended Libraries

- **next-seo** — Simplified metadata and JSON-LD for Next.js
- **schema-dts** — TypeScript types for Schema.org, gives type safety on JSON-LD objects
- **next-sitemap** — Automated sitemap and robots.txt generation
