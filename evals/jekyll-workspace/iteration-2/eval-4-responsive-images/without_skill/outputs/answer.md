# Jekyll Travel Blog: Responsive Images + WebP + Lazy Loading

## The Problem

- 150 posts × 3 MB hero photos = 450 MB of uncompressed full-resolution images
- PageSpeed LCP ~5+ seconds because desktop-sized originals are served to every device
- No WebP, no responsive `srcset`, no lazy loading

## 1. Gemfile — Add Required Gems

```ruby
group :jekyll_plugins do
  gem 'jekyll-webp'               # Auto-generate WebP versions on build
  gem 'jekyll-responsive-magick'  # Resize variants via ImageMagick
  gem 'jekyll-lazy-load-img'      # Injects loading="lazy" + data-src
  gem 'jekyll-srcset'             # Generates srcset markup automatically
end
```

Or for a lighter pipeline, drop `srcset` and do it manually in layouts:

```ruby
gem 'jekyll-webp'
gem 'jekyll-picture-tag'          # <picture> element with srcset + WebP
```

Install:

```bash
bundle install
```

## 2. _config.yml — Configure the Plugins

```yaml
# --- WebP ---
webp:
  enabled: true
  quality: 75
  img_dir: ["/assets/images"]       # scan these dirs
  formats: [".jpg", ".jpeg", ".png"]
  gif_to_webp: false
  resize: false                     # handled by responsive-magick

# --- Responsive Magick (resize variants) ---
responsive:
  widths: [480, 768, 1024, 1920]
  quality: 80
  strip: true                       # strip metadata

# --- Lazy load ---
lazyload:
  enabled: true
  placeholder: "/assets/img/placeholder.svg"  # tiny blurred placeholder
  effect: "fade-in"                           # optional CSS transition

# --- Picture tag ---
picture:
  source_formats: ["webp", "original"]
  fallback_format: "original"
  widths: [480, 768, 1024, 1920]
```

### Critical: Exclude Generated Images from Git

```yaml
# _config.yml — keep build output lean
exclude:
  - "*.webp"
  - Gemfile.lock
```

But better — add to `.gitignore`:

```
/assets/images/**/*-480x*
/assets/images/**/*-768x*
/assets/images/**/*-1024x*
/assets/images/**/*-1920x*
/assets/images/**/*.webp
```

## 3. Layout Change — The `<picture>` Element

Replace your current `<img>` tag in `_layouts/post.html` (or wherever hero images render):

### Before (the problem):

```liquid
<img src="{{ page.hero_image | relative_url }}" alt="{{ page.title }}">
```

### After (responsive + WebP + lazy loading):

Using **jekyll-picture-tag** (simplest):

```liquid
{% picture hero {{ page.hero_image }} --alt {{ page.title | escape }} %}
```

Using **manual markup** with jekyll-webp + jekyll-responsive-magick (more control):

```liquid
{% assign hero = page.hero_image %}
{% assign ext = hero | split: '.' | last %}
{% assign base = hero | replace: '.' | append: ext %}

<picture>
  <!-- WebP sources -->
  <source
    srcset="
      {{ hero | replace: ext, '480x480.webp' }} 480w,
      {{ hero | replace: ext, '768x768.webp' }} 768w,
      {{ hero | replace: ext, '1024x1024.webp' }} 1024w,
      {{ hero | replace: ext, '1920x1920.webp' }} 1920w"
    sizes="(max-width: 480px) 480px,
           (max-width: 768px) 768px,
           (max-width: 1024px) 1024px,
           1920px"
    type="image/webp">
  <!-- Fallback JPEG/PNG -->
  <source
    srcset="
      {{ hero | replace: ext, '480x480.' | append: ext }} 480w,
      {{ hero | replace: ext, '768x768.' | append: ext }} 768w,
      {{ hero | replace: ext, '1024x1024.' | append: ext }} 1024w,
      {{ hero | replace: ext, '1920x1920.' | append: ext }} 1920w"
    sizes="(max-width: 480px) 480px,
           (max-width: 768px) 768px,
           (max-width: 1024px) 1024px,
           1920px">
  <!-- Fallback img (required) + lazy loading -->
  <img
    src="{{ hero | relative_url }}"
    srcset="
      {{ hero | replace: ext, '480x480.' | append: ext }} 480w,
      {{ hero | replace: ext, '768x768.' | append: ext }} 768w,
      {{ hero | replace: ext, '1024x1024.' | append: ext }} 1024w"
    sizes="100vw"
    alt="{{ page.title | escape }}"
    loading="lazy"
    decoding="async"
    width="1920"
    height="1080">
</picture>
```

### Add explicit width/height to every `<img>` to eliminate Cumulative Layout Shift (CLS):

```liquid
{% if page.hero_width and page.hero_height %}
  width="{{ page.hero_width }}"
  height="{{ page.hero_height }}"
{% else %}
  width="1920"
  height="1080"
{% endif %}
```

Add these dimensions to your front matter:

```yaml
---
hero_image: /assets/images/iceland-waterfall.jpg
hero_width: 1920
hero_height: 1080
---
```

## 4. Preload the LCP Image — The Critical Fix

Since lazy loading delays the first hero, **do NOT lazy-load the LCP image**. Preload it instead.

In `_includes/head.html` or `_layouts/default.html` inside `<head>`:

```liquid
{% if page.hero_image %}
  {% assign hero_ext = page.hero_image | split: '.' | last %}
  {% assign hero_webp = page.hero_image | replace: hero_ext, 'webp' %}

  <!-- Preload LCP image (smallest adequate size for the viewport) -->
  <link
    rel="preload"
    href="{{ hero_webp | relative_url }}"
    as="image"
    type="image/webp"
    imagesrcset="
      {{ page.hero_image | replace: hero_ext, '480x480.webp' }} 480w,
      {{ page.hero_image | replace: hero_ext, '768x768.webp' }} 768w"
    imagesizes="(max-width: 768px) 100vw, 768px"
    fetchpriority="high">
{% endif %}
```

Then in the post layout, don't lazy-load the hero:

```liquid
<img
  ...
  {% if forloop.index > 1 or page.layout != 'post' %}
    loading="lazy"
  {% endif %}
  ...>
```

## 5. Build Pipeline

### Netlify config (`netlify.toml`):

```toml
[build]
  command = "jekyll build"

[build.environment]
  JEKYLL_ENV = "production"

[[headers]]
  for = "/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/assets/images/*.webp"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Install system deps (Netlify needs ImageMagick):

In `netlify.toml` build step (or a `prebuild` script):

```toml
[build]
  command = """
    apt-get update -qq && apt-get install -y -qq libwebp-dev imagemagick && \
    jekyll build
  """
```

Alternatively, use Netlify's build-image that includes ImageMagick by default (Ubuntu-based). If needed, add a `Gemfile`-adjacent `Brewfile` or use the **netlify-plugin-image-optim** plugin.

### Optional: Use `jekyll-compress-images` in CI

```yaml
# _config.yml
compress_images:
  images_path: "/assets/images/**/*.{jpg,jpeg,png,gif,svg}"
  quality: 80
  max_width: 1920
  progressive: true
```

## 6. Full File Checklist

| File | Change |
|---|---|
| `Gemfile` | Add `jekyll-webp`, `jekyll-responsive-magick` (or `jekyll-picture-tag`) |
| `_config.yml` | Add plugin configs — widths, quality, WebP options |
| `.gitignore` | Exclude generated resized images and WebP files |
| `_layouts/post.html` | Replace `<img>` with `<picture>` + `srcset` + preload LCP |
| `_includes/head.html` | Add `<link rel="preload">` for hero image |
| `netlify.toml` | Build command, Cache-Control headers, ImageMagick install |
| Front matter | Add `hero_width` and `hero_height` to every post |

## 7. Expected Outcome

| Metric | Before | After |
|---|---|---|
| Image weight (hero) | 3 MB | ~80–150 KB (WebP 768w) |
| LCP | 5+ s | ~1.2–1.8 s |
| CLS | >0.1 | ~0 (fixed dimensions) |
| Data on mobile | 3 MB per page | ~100–300 KB per page |
| Lighthouse Performance | ~25 | ~85–95 |

## 8. One-Time Migration Script (Optional)

Run this to add `hero_width` / `hero_height` to all 150 posts (requires ImageMagick):

```bash
#!/bin/bash
for post in _posts/*.md; do
  img=$(grep 'hero_image:' "$post" | sed 's/.*\/images\///')
  if [ -z "$img" ]; then continue; fi
  path="assets/images/$img"
  if [ -f "$path" ]; then
    dims=$(identify -format '%w %h' "$path")
    w=$(echo $dims | cut -d' ' -f1)
    h=$(echo $dims | cut -d' ' -f2)
    # Insert after hero_image line
    sed -i '' "/hero_image:/a\\
hero_width: $w\\
hero_height: $h" "$post"
  fi
done
```

Then batch-convert originals to WebP:

```bash
find assets/images -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" | \
  xargs -I {} sh -c 'cwebp -q 80 "{}" -o "{}.webp"'
```

## Summary

The biggest wins in order of impact:

1. **Resize to 4 widths + WebP** — cuts image weight by 95%+
2. **`<picture>` with `srcset` + `sizes`** — serves only what the device needs
3. **Preload LCP image** — eliminates the render-blocking image fetch
4. **Explicit `width` + `height`** — kills CLS
5. **Lazy load below-fold images** — defers 95% of images to idle time

Netlify gives you the freedom to use ImageMagick, so all of this runs at build time with zero client-side JS overhead.
