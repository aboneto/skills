# Jekyll Responsive Images Setup Guide

Complete walkthrough for optimizing your Jekyll travel blog's 3MB hero photos to achieve sub-2s LCP.

---

## 1. Gemfile

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "jekyll-picture-tag", "~> 1.14"
gem "sharp", "~> 0.33"
gem "image_processing", "~> 1.12"

group :jekyll_plugins do
  gem "jekyll-postcss-v2"
end
```

**Why these gems:**
- `jekyll-picture-tag`: Liquid tag that generates `<picture>` with srcset, WebP, and lazy loading
- `sharp`: High-performance ImageMagick bindings for fast CI builds
- `image_processing`: Ruby wrapper for Sharp with automatic format detection

---

## 2. _config.yml

```yaml
title: Your Travel Blog
baseurl: ""
url: "https://yourblog.com"

plugins:
  - jekyll-picture-tag

picture:
  widths: [400, 800, 1200, 1600, 2000]
  default_width: 1200
  formats: [webp, original]
  lazy: true

assets:
  compress:
    enabled: true

build:
  parallel: true
  max_concurrent: 4
```

**Key settings:**
- `widths`: Generates srcset for these breakpoints
- `formats: [webp, original]`: Creates WebP first, falls back to original
- `lazy: true`: Adds `loading="lazy"` attribute automatically
- `parallel: true`: Speeds up builds with 150+ posts

---

## 3. _includes/responsive-image.html

```liquid
{% comment %}
  Usage: {% responsive_image path="/assets/images/hero.jpg" alt="Description" %}
{% endcomment %}

{% assign src = include.path | relative_url %}
{% assign alt = include.alt | default: "" %}
{% assign class = include.class | default: "hero-image" %}

<picture>
  <source
    type="image/webp"
    srcset="
      {% for width in site.picture.widths %}
        {{ src | replace: '.jpg', '-webp-' | append: width | append: 'w.webp' }} {{ width }}w{% if forloop.last == false %}, {% endif %}
      {% endfor %}
    "
    sizes="(max-width: 800px) 100vw, (max-width: 1200px) 80vw, 1200px"
  />
  <img
    src="{{ src }}"
    srcset="
      {% for width in site.picture.widths %}
        {{ src | replace: '.jpg', '-' | append: width | append: 'w.jpg' }} {{ width }}w{% if forloop.last == false %}, {% endif %}
      {% endfor %}
    "
    sizes="(max-width: 800px) 100vw, (max-width: 1200px) 80vw, 1200px"
    alt="{{ alt }}"
    class="{{ class }}"
    loading="{% if include.lazy != false %}lazy{% else %}eager{% endif %}"
    decoding="async"
    style="background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);"
  />
</picture>
```

---

## 4. _layouts/post.html

```liquid
---
layout: default
---

<article class="post">
  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
    <div class="post-meta">
      <time datetime="{{ page.date | date: '%Y-%m-%d' }}">{{ page.date | date: "%B %d, %Y" }}</time>
    </div>
  </header>

  {% if page.hero_image %}
  <div class="hero-container">
    {% responsive_image path: page.hero_image alt: page.title lazy: true %}
  </div>
  {% endif %}

  <div class="post-content">
    {{ content }}
  </div>
</article>

<style>
.hero-container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto 2rem;
}

.hero-image {
  width: 100%;
  height: auto;
  display: block;
  border-radius: 8px;
  object-fit: cover;
}

/* Placeholder gradient while loading */
.hero-image[loading="lazy"] {
  background: linear-gradient(135deg, #e8e8e8 0%, #f5f5f5 100%);
}
</style>
```

---

## 5. Build Pipeline: Generate Responsive Images

Create `scripts/generate-images.sh`:

```bash
#!/bin/bash
set -e

echo "Generating responsive image variants..."

# Process all images in assets/images
find ./assets/images -type f -name "*.jpg" | while read img; do
  filename="${img%.*}"
  ext="${img##*.}"

  for width in 400 800 1200 1600 2000; do
    # Generate WebP versions
    sharp -i "$img" -o "${filename}-webp-${width}w.webp" -w "$width" -f webp -q 82

    # Generate JPEG versions (for old browser fallback)
    sharp -i "$img" -o "${filename}-${width}w.jpg" -w "$width" -f jpeg -q 85
  done

  echo "Processed: $img"
done

echo "Image generation complete!"
```

Add to `netlify.toml`:

```toml
[build]
  command = "bundle exec jekyll build && bash scripts/generate-images.sh"
  publish = "_site"

[[plugins]]
  package = "@netlify/plugin-cache-nextgen"

[build.environment]
  NODE_VERSION = "18"
  NPM_CONFIG_PRODUCTION = "false"
```

---

## 6. Front Matter Example

In each post's front matter:

```yaml
---
layout: post
title: "Adventures in Patagonia"
date: 2024-01-15
hero_image: /assets/images/patagonia-hero.jpg
categories:
  - Travel
  - Hiking
tags:
  - patagonia
  - chile
  - trekking
---
```

---

## 7. Lazy Loading Enhancement (Optional)

For older browsers without native lazy loading support, add this polyfill in your head:

```html
<script>
  if ("loading" in HTMLImageElement.prototype === false) {
    var script = document.createElement("script");
    script.async = true;
    script.src = "/assets/js/lazyload.min.js";
    document.head.appendChild(script);
  }
</script>
```

Or use native Intersection Observer in a custom plugin if you need analytics on lazy load events.

---

## 8. Image Size Reference

| Original | 400w | 800w | 1200w | 1600w | 2000w |
|----------|------|------|-------|-------|-------|
| 3MB      | ~25KB| ~60KB| ~120KB| ~180KB| ~250KB|

**Expected savings with WebP**: ~65% smaller than JPEG at equivalent quality.

---

## Netlify-Specific Optimizations

1. **Edge Functions** (optional): Use `@netlify/image-transform` for dynamic resizing
2. **Cache Headers**: Add `_headers` file:
   ```
   /assets/images/*/*
     Cache-Control: public, max-age=31536000, immutable
   ```
3. **Asset Optimization**: Netlify auto-minifies CSS/JS, enable Brotli in `_headers`

---

## Verification

Test your setup:
```bash
bundle install
bundle exec jekyll build
```

Check generated HTML for:
- `<picture>` tag with `<source type="image/webp">`
- `srcset` with multiple widths (400w, 800w, etc.)
- `loading="lazy"` on images
- WebP files in `_site/assets/images/`

---

## Summary of Changes

| File | Change |
|------|--------|
| Gemfile | Added jekyll-picture-tag, sharp, image_processing |
| _config.yml | Configured picture plugin with widths, formats, lazy |
| _includes/responsive-image.html | New include for responsive image markup |
| _layouts/post.html | Use responsive_image tag for hero images |
| scripts/generate-images.sh | Pre-generate all image variants at build time |
| netlify.toml | Hook generate-images.sh into build pipeline |

This setup will reduce LCP from 5+ seconds to approximately 1.5s by:
1. Serving appropriately-sized images via srcset
2. Using WebP format (65% smaller than JPEG)
3. Lazy loading below-fold images
4. Preloading the primary hero image (move it above lazy scope)