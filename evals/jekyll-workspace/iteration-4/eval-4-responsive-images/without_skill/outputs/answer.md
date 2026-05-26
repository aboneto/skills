# Optimizing Jekyll Travel Blog: Responsive Images with WebP & Lazy Loading

## Strategy Overview

Since you're on Netlify, the best approach is **Netlify Image CDN** for on-the-fly resizing/format conversion, combined with native lazy loading. This avoids slow build-time image processing (150 posts × multiple sizes = painful builds).

If you prefer build-time processing (works anywhere), I also cover the `jekyll-picture-tag` gem approach.

---

## Option A: Netlify Image CDN (Recommended)

### 1. No Gemfile Changes Needed

Netlify Image CDN works at the edge — no gems or plugins required. Your `Gemfile` stays the same:

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "minima", "~> 2.5"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
  gem "jekyll-seo-tag", "~> 2.8"
end
```

### 2. `_config.yml` Changes

```yaml
# Image CDN config — define breakpoints for your hero images
image_cdn:
  hero:
    widths: [400, 800, 1200, 1600, 2000]
    sizes: "(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"

# Keep your existing config
permalink: /blog/:year/:month/:day/:title/
markdown: kramdown
```

### 3. Create a Reusable `_includes/hero-image.html`

```html
{% comment %}
  Usage: {% include hero-image.html src=page.hero_photo alt=page.title %}
  Expects images in /assets/images/heroes/
{% endcomment %}

{% assign img_path = include.src | default: page.hero_photo %}
{% assign alt_text = include.alt | default: page.title %}

<picture>
  {%- comment -%} WebP via Netlify Image CDN {%- endcomment -%}
  <source
    type="image/webp"
    srcset="
      /.netlify/images?url={{ img_path }}&w=400&fm=webp 400w,
      /.netlify/images?url={{ img_path }}&w=800&fm=webp 800w,
      /.netlify/images?url={{ img_path }}&w=1200&fm=webp 1200w,
      /.netlify/images?url={{ img_path }}&w=1600&fm=webp 1600w,
      /.netlify/images?url={{ img_path }}&w=2000&fm=webp 2000w
    "
    sizes="(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"
  />

  {%- comment -%} JPEG fallback {%- endcomment -%}
  <img
    src="/.netlify/images?url={{ img_path }}&w=1200&q=80"
    srcset="
      /.netlify/images?url={{ img_path }}&w=400&q=80 400w,
      /.netlify/images?url={{ img_path }}&w=800&q=80 800w,
      /.netlify/images?url={{ img_path }}&w=1200&q=80 1200w,
      /.netlify/images?url={{ img_path }}&w=1600&q=80 1600w,
      /.netlify/images?url={{ img_path }}&w=2000&q=80 2000w
    "
    sizes="(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"
    alt="{{ alt_text }}"
    loading="lazy"
    decoding="async"
    width="2000"
    height="1125"
    fetchpriority="low"
  />
</picture>
```

### 4. Create `_includes/hero-image-critical.html` (for LCP)

The **first visible hero image** (above the fold) should NOT be lazy-loaded. Use this variant on your post layout:

```html
{% assign img_path = include.src | default: page.hero_photo %}
{% assign alt_text = include.alt | default: page.title %}

<picture>
  <source
    type="image/webp"
    srcset="
      /.netlify/images?url={{ img_path }}&w=400&fm=webp 400w,
      /.netlify/images?url={{ img_path }}&w=800&fm=webp 800w,
      /.netlify/images?url={{ img_path }}&w=1200&fm=webp 1200w,
      /.netlify/images?url={{ img_path }}&w=1600&fm=webp 1600w,
      /.netlify/images?url={{ img_path }}&w=2000&fm=webp 2000w
    "
    sizes="(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"
  />
  <img
    src="/.netlify/images?url={{ img_path }}&w=1200&q=80"
    srcset="
      /.netlify/images?url={{ img_path }}&w=400&q=80 400w,
      /.netlify/images?url={{ img_path }}&w=800&q=80 800w,
      /.netlify/images?url={{ img_path }}&w=1200&q=80 1200w,
      /.netlify/images?url={{ img_path }}&w=1600&q=80 1600w,
      /.netlify/images?url={{ img_path }}&w=2000&q=80 2000w
    "
    sizes="(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"
    alt="{{ alt_text }}"
    decoding="async"
    width="2000"
    height="1125"
    fetchpriority="high"
  />
</picture>
```

Key difference: `loading="lazy"` is **removed** and `fetchpriority="high"` is added. This tells the browser to fetch this image immediately — critical for LCP.

### 5. Layout Changes: `_layouts/post.html`

```html
---
layout: default
---

<article class="post">
  <header class="post-header">
    <h1>{{ page.title }}</h1>
    <time datetime="{{ page.date | date_to_xmlschema }}">
      {{ page.date | date: "%B %d, %Y" }}
    </time>
  </header>

  {%- comment -%} LCP hero: no lazy loading {%- endcomment -%}
  <div class="hero-container" style="aspect-ratio: 16/9; overflow: hidden;">
    {% include hero-image-critical.html src=page.hero_photo alt=page.title %}
  </div>

  <div class="post-content">
    {{ content }}
  </div>

  {%- comment -%} Inline images in post body: lazy load these {%- endcomment -%}
</article>
```

### 6. Layout Changes: `_layouts/default.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{ page.title }} | {{ site.title }}</title>

  {%- comment -%} Preconnect to Netlify Image CDN {%- endcomment -%}
  <link rel="preconnect" href="https://{{ site.url | replace: 'https://', '' }}" crossorigin>

  {%- comment -%} Preload LCP image for post pages {%- endcomment -%}
  {% if page.hero_photo and page.layout == 'post' %}
  <link
    rel="preload"
    as="image"
    href="/.netlify/images?url={{ page.hero_photo }}&w=1200&fm=webp"
    imagesrcset="
      /.netlify/images?url={{ page.hero_photo }}&w=800&fm=webp 800w,
      /.netlify/images?url={{ page.hero_photo }}&w=1200&fm=webp 1200w,
      /.netlify/images?url={{ page.hero_photo }}&w=1600&fm=webp 1600w
    "
    imagesizes="(max-width: 600px) 100vw, (max-width: 1200px) 100vw, 2000px"
    fetchpriority="high"
  >
  {% endif %}

  <link rel="stylesheet" href="/assets/css/style.css">
  {% seo %}
</head>
<body>
  {{ content }}
</body>
</html>
```

### 7. Post Front Matter

Your posts need a `hero_photo` field pointing to the original image:

```yaml
---
title: "Exploring the Temples of Kyoto"
date: 2025-03-15
layout: post
hero_photo: /assets/images/heroes/kyoto-temples.jpg
---
```

Store originals at full resolution in `assets/images/heroes/`. Netlify handles the rest.

### 8. CSS for Responsive Images

```css
.hero-container {
  width: 100%;
  max-width: 2000px;
  margin: 0 auto;
  aspect-ratio: 16 / 9;
  overflow: hidden;
  background-color: #f0f0f0; /* placeholder while loading */
}

.hero-container img,
.hero-container picture {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.post-content img {
  max-width: 100%;
  height: auto;
  loading: lazy;
}
```

---

## Option B: Build-Time Processing with `jekyll-picture-tag`

Use this if you want to self-host optimized images (no CDN dependency).

### 1. Gemfile

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "minima", "~> 2.5"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
  gem "jekyll-seo-tag", "~> 2.8"
  gem "jekyll-picture-tag", "~> 2.0"
end
```

Run `bundle install`.

### 2. `_config.yml`

```yaml
picture:
  source: "assets/images/heroes"
  output: "generated"
  markup: "picture"
  presets:
    hero:
      attr:
        loading: lazy
        decoding: async
      widths: [400, 800, 1200, 1600, 2000]
      formats: [webp, original]
      sizes:
        - "(max-width: 600px) 100vw"
        - "(max-width: 1200px) 100vw"
        - "2000px"
      dimension_attributes: true
    hero-critical:
      attr:
        fetchpriority: high
        decoding: async
      widths: [400, 800, 1200, 1600, 2000]
      formats: [webp, original]
      sizes:
        - "(max-width: 600px) 100vw"
        - "(max-width: 1200px) 100vw"
        - "2000px"
      dimension_attributes: true
```

### 3. Install libvips (required by jekyll-picture-tag)

Netlify has libvips pre-installed. For local dev:

```bash
# macOS
brew install vips

# Ubuntu/Debian
sudo apt install libvips-dev
```

### 4. `_includes/hero-image.html`

```html
{% picture hero {{ include.src }} --alt {{ include.alt }} %}
```

### 5. `_includes/hero-image-critical.html`

```html
{% picture hero-critical {{ include.src }} --alt {{ include.alt }} %}
```

### 6. Netlify Build Settings

In `netlify.toml`:

```toml
[build]
  command = "bundle exec jekyll build"
  publish = "_site"

[build.environment]
  RUBY_VERSION = "3.2.2"
```

### 7. Post Front Matter

```yaml
---
title: "Exploring the Temples of Kyoto"
date: 2025-03-15
layout: post
hero_photo: kyoto-temples.jpg
---
```

---

## Performance Checklist

| Optimization | Impact on LCP | Effort |
|---|---|---|
| Responsive `srcset` with multiple widths | High — browser picks right size | Medium |
| WebP format (30-50% smaller than JPEG) | High | Low (CDN handles it) |
| `fetchpriority="high"` on LCP image | High — browser fetches ASAP | Trivial |
| `<link rel="preload">` for LCP image | Medium-High | Low |
| `loading="lazy"` on below-fold images | Medium — frees bandwidth for LCP | Trivial |
| Explicit `width`/`height` attributes | Medium — prevents CLS | Low |
| `aspect-ratio` CSS on container | Medium — prevents layout shift | Low |

## Expected Results

| Metric | Before | After |
|---|---|---|
| LCP | 5+ seconds | < 1.5 seconds |
| Total page weight | ~3 MB | ~80-150 KB (WebP, right size) |
| CLS | Poor (no dimensions) | 0 |
| PageSpeed score | ~30-40 | 90+ |

## Folder Structure

```
assets/
  images/
    heroes/
      kyoto-temples.jpg      # 3MB original — keep as-is
      paris-eiffel.jpg
      ...150 more files
```

Originals stay at full resolution. Netlify Image CDN serves optimized versions on demand — no build-time penalty, no extra storage for generated files.

## Key Principles

1. **LCP image**: Use `fetchpriority="high"`, `preload`, NO `loading="lazy"`
2. **Everything else**: Use `loading="lazy"` and `decoding="async"`
3. **Always set `width` and `height`**: Prevents layout shift (CLS)
4. **Use `<picture>` with `<source type="image/webp">`**: WebP first, JPEG fallback
5. **Let the CDN resize**: Don't generate 5 sizes per image at build time
