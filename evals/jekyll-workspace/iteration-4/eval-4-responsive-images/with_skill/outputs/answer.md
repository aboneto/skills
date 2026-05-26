# Fixing LCP on a Jekyll Travel Blog with Responsive Images

Your 3MB hero photos are the bottleneck. A 4032×3024 phone photo served at 720px layout width is ~20× more pixels than needed. The fix is a four-step pipeline: **compress → resize → modern formats → lazy load**. Since you're on Netlify, you can use any plugin — no allowlist restrictions.

---

## 1. Gemfile — add `jekyll-picture-tag`

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-paginate-v2",   "~> 3.0"
  gem "jekyll-include-cache", "~> 0.2"
  gem "jekyll-picture-tag",   "~> 2.1"   # ← add this
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"
```

Run `bundle install` after editing.

---

## 2. `_config.yml` — configure the picture tag

Add this block to your existing `_config.yml`:

```yaml
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-paginate-v2
  - jekyll-include-cache
  - jekyll-picture-tag    # ← add this

# Responsive image configuration
picture:
  source: assets/images          # where your originals live
  output: generated              # resized outputs go to _site/assets/images/generated/
  presets:
    hero:
      formats: [webp, original]  # WebP for modern browsers, JPEG fallback
      widths: [480, 720, 1200, 1920]
      sizes:
        - "(min-width: 1200px) 1200px"
        - "100vw"
      attributes:
        img: 'loading="eager" decoding="async"'
    thumbnail:
      formats: [webp, original]
      widths: [360, 720]
      sizes: "(min-width: 768px) 720px, 100vw"
      attributes:
        img: 'loading="lazy" decoding="async"'
```

Key decisions:
- **`hero` preset**: `loading="eager"` because hero images are above the fold — don't lazy-load them (that hurts LCP).
- **`thumbnail` preset**: `loading="lazy"` for everything below the fold.
- **`formats: [webp, original]`**: WebP is ~30% smaller than JPEG with universal browser support. `original` keeps the JPEG/PNG fallback.
- **`widths`**: four breakpoints cover phones through desktops. The `sizes` attribute tells the browser which width to pick at each viewport.

---

## 3. Layout changes — `_layouts/post.html` and `_includes/`

### 3a. Create `_includes/hero-image.html`

```liquid
{% comment %}
  Hero image include. Expects:
    - include.src: filename relative to assets/images/ (e.g. "2026-05-01-paris/hero.jpg")
    - include.alt: alt text
    - include.width: intrinsic width (default 1200)
    - include.height: intrinsic height (default 675)
{% endassign %}

{% assign w = include.width | default: 1200 %}
{% assign h = include.height | default: 675 %}

<figure class="hero-image">
  {% picture hero {{ include.src }} --alt {{ include.alt }} --width {{ w }} --height {{ h }} %}
</figure>
```

### 3b. Update `_layouts/post.html`

```html
---
layout: default
---
<article class="post">
  <header class="post-header">
    <h1>{{ page.title }}</h1>
    <time datetime="{{ page.date | date_to_xmlschema }}">
      {{ page.date | date: "%B %-d, %Y" }}
    </time>
  </header>

  {% if page.hero %}
    {% include hero-image.html
       src=page.hero
       alt=page.hero_alt
       width=page.hero_width
       height=page.hero_height %}
  {% endif %}

  <div class="post-content">
    {{ content }}
  </div>
</article>
```

### 3c. Update post front matter

```yaml
---
layout: post
title: "A Week in Paris"
date: 2026-05-01
hero: 2026-05-01-paris/hero.jpg
hero_alt: "Eiffel Tower at sunset from Trocadéro"
hero_width: 1920
hero_height: 1280
---
```

Place the original photo at `assets/images/2026-05-01-paris/hero.jpg`. At build time, `jekyll-picture-tag` generates:

```
_site/assets/images/generated/hero-480.webp
_site/assets/images/generated/hero-480.jpg
_site/assets/images/generated/hero-720.webp
_site/assets/images/generated/hero-720.jpg
_site/assets/images/generated/hero-1200.webp
_site/assets/images/generated/hero-1200.jpg
_site/assets/images/generated/hero-1920.webp
_site/assets/images/generated/hero-1920.jpg
```

And emits the full `<picture>` element with `srcset` and `sizes`.

### 3d. For inline images in post body (below the fold)

Use the `thumbnail` preset in your Markdown:

```liquid
{% picture thumbnail some-photo.jpg --alt "Street café in Montmartre" %}
```

This gets `loading="lazy"` automatically.

---

## 4. Build pipeline — Netlify configuration

### `netlify.toml`

```toml
[build]
  command = "bundle exec jekyll build"
  publish = "_site"

[build.environment]
  JEKYLL_ENV = "production"
  RUBY_VERSION = "3.4.8"

# Cache generated images between builds
[[headers]]
  for = "/assets/images/generated/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Pre-build image optimization (optional but recommended)

If you want to also compress the *originals* before they hit the plugin (saves build time and ensures the source is already lean), add a pre-build script.

Create `scripts/optimize-source-images.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Only process images larger than 500KB
find assets/images -name '*.jpg' -size +500k -exec sh -c '
  for f; do
    # Strip EXIF, resize to max 2400px wide, quality 82
    # Requires ImageMagick (available on Netlify build image)
    magick "$f" -strip -resize "2400x>" -quality 82 "$f"
  done
' _ {} +
```

Update `netlify.toml`:

```toml
[build]
  command = "bash scripts/optimize-source-images.sh && bundle exec jekyll build"
  publish = "_site"
```

This ensures no 3MB file ever enters the pipeline. A 3MB phone photo typically shrinks to ~200-400KB after this step, then `jekyll-picture-tag` generates the smaller variants from there.

---

## 5. Why this fixes your LCP

| Before | After |
|---|---|
| 3MB JPEG, full resolution | ~150KB WebP at 1200px (hero above fold) |
| No `srcset` — browser downloads full size | Browser picks 480/720/1200/1920 based on viewport |
| No `width`/`height` → layout shift (CLS) | Intrinsic dimensions prevent CLS |
| No `loading` strategy | Hero loads eagerly (correct for LCP), rest lazy |

Expected impact:
- **LCP**: drops from 5s+ to ~1-2s on 4G (the hero is now ~150KB instead of 3MB)
- **CLS**: near zero with explicit `width`/`height`
- **Total page weight**: ~80-90% reduction per post

---

## 6. Bulk migration strategy (150 posts)

You don't need to edit all 150 posts at once. Do it incrementally:

1. **Move existing hero images** into per-post folders:
   ```
   assets/images/2026-05-01-paris/hero.jpg
   assets/images/2026-04-15-tokyo/hero.jpg
   ```

2. **Add front matter** to each post:
   ```yaml
   hero: 2026-05-01-paris/hero.jpg
   hero_alt: "Description"
   hero_width: 1920
   hero_height: 1280
   ```

3. **Update the layout once** (the `post.html` change above). Posts without `hero` in front matter just skip the hero section — no breakage.

4. **For post-body images**, replace raw `<img>` tags with `{% picture %}` tags as you touch each post. Unedited posts still work (they just don't get the responsive treatment).

---

## 7. Quick verification

After deploying, check with Lighthouse:

```bash
# Local build test
JEKYLL_ENV=production bundle exec jekyll build
# Check the output
ls -la _site/assets/images/generated/
```

The `generated/` folder should contain WebP + original variants at each width. Verify the emitted HTML contains `<picture>` with `<source type="image/webp">` and an `<img>` fallback with `loading="eager"` on the hero and `loading="lazy"` on thumbnails.
