# Responsive Images with WebP Fallback & Lazy Loading for a Jekyll Travel Blog on Netlify

You have 150 posts × 3MB hero images, LCP ~5s, and you control the build (Netlify). The fix has four layers.

---

## 1. Gemfile — Add `jekyll-picture-tag`

This plugin automates resizing, format conversion (WebP, AVIF), and emits the full `<picture>` element from a single Liquid tag. It is **not** on the GitHub Pages allowlist, but you're on Netlify so that doesn't matter.

```ruby
# Gemfile
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-picture-tag",   "~> 2.1"   # <-- new
  gem "jekyll-include-cache", "~> 0.2"
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"
```

Run `bundle install`.

---

## 2. `_config.yml` — Configure the image pipeline

Add `jekyll-picture-tag` to the plugins list and define a preset:

```yaml
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-picture-tag        # <-- new
  - jekyll-include-cache

# ───── Responsive images ─────
picture:
  source: assets/images/hero    # source directory for original photos
  output: generated              # output relative to _site/
  presets:
    hero:
      formats: [webp, original] # original = JPEG fallback
      widths:  [480, 768, 1200, 1600]
      attributes:
        img: 'class="hero" loading="lazy" decoding="async"'
```

- `formats: [webp, original]` — generates a WebP variant at every width, plus the original format (JPEG) as fallback. Add `avif` before `webp` if you want AVIF too (encoders are slower).
- `widths` — four breakpoints cover phones (480), tablets (768), laptops (1200), and retina desktops (1600). No point shipping 4032×3024 when the layout is 720px.
- `loading="lazy" decoding="async"` — native lazy loading on every generated `<img>`. The browser defers offscreen images. Pair with `width`/`height` attributes (which the plugin also emits) to eliminate layout shift (CLS).

For above-the-fold images (e.g., the first post's hero on the homepage), set `loading="eager"` explicitly via a second preset.

---

## 3. Layout changes — Use `{% picture %}` in templates

### In `_layouts/post.html` (the per-post template)

Replace your existing `<img>` tag for the hero photo with:

```liquid
{% if page.hero_image %}
  {% picture hero {{ page.hero_image }} --alt {{ page.title | escape }} %}
{% endif %}
```

### In `_layouts/default.html` or the homepage listing

If you show hero thumbnails on index pages, same pattern — just point at a different preset with smaller widths:

```yaml
# _config.yml — add a thumbnail preset
picture:
  presets:
    thumbnail:
      formats: [webp, original]
      widths:  [200, 400]
      attributes:
        img: 'class="thumb" loading="lazy" decoding="async"'
```

```liquid
{% picture thumbnail {{ post.hero_image }} --alt "Thumbnail for {{ post.title | escape }}" %}
```

### In post front matter

Reference the original photo by its filename relative to the `picture.source` directory:

```yaml
---
layout: post
title: "Hiking in the Dolomites"
date: 2026-05-01 09:00:00 +0100
hero_image: dolomites.jpg
---
```

Place the original high-resolution source file at `assets/images/hero/dolomites.jpg`. The plugin reads from there and writes scaled + converted copies to `_site/generated/`.

### What `{% picture %}` emits at build time

```html
<picture>
  <source srcset="
    /generated/dolomites-480.webp   480w,
    /generated/dolomites-768.webp   768w,
    /generated/dolomites-1200.webp 1200w,
    /generated/dolomites-1600.webp 1600w"
    sizes="(min-width: 1200px) 1200px, 100vw"
    type="image/webp">
  <img
    src="/generated/dolomites-1200.jpg"
    srcset="
      /generated/dolomites-480.jpg   480w,
      /generated/dolomites-768.jpg   768w,
      /generated/dolomites-1200.jpg 1200w,
      /generated/dolomites-1600.jpg 1600w"
    sizes="(min-width: 1200px) 1200px, 100vw"
    alt="Hiking in the Dolomites"
    class="hero" loading="lazy" decoding="async"
    width="1600" height="1067">
</picture>
```

Browsers that support WebP load the `<source>` block. Older browsers fall through to the `<img>` JPEG. The `sizes` attribute tells the browser which width to select, so a phone downloads the 480w variant (~50KB) instead of 1600w (~500KB).

---

## 4. Netlify build pipeline (`netlify.toml`)

```toml
[build]
  command = "bundle exec jekyll build"
  publish = "_site"

[build.environment]
  JEKYLL_ENV = "production"
  RUBY_VERSION = "3.4.8"

# Cache the jekyll-picture-tag output so images aren't reprocessed on every build
[[plugins]]
  package = "@netlify/plugin-cache"
    [plugins.inputs]
    paths = ["_site/generated"]
```

`jekyll-picture-tag` caches generated images internally — only new or changed source images get reprocessed. The Netlify cache plugin persists `_site/generated` across builds, so a 150-image site only pays the conversion cost once.

### Pre-build compression (optional but recommended)

Add a pre-build step in `netlify.toml` to compress originals before they enter the pipeline:

```toml
[build]
  command = """
  npm i -g sharp-cli && \
  npx sharp -i 'assets/images/hero/**/*.jpg' -o 'assets/images/hero' \
    --format jpeg --quality 82 \
    --format webp --quality 82 && \
  bundle exec jekyll build
  """
```

This runs `sharp` on every JPG in the hero directory, compressing to JPEG (q82) and generating a base WebP copy. Then `jekyll-picture-tag` resizes those smaller files further. The two-pass approach means the build step works from already-compressed inputs.

For a simpler option: batch-compress your 150 originals locally once with `cwebp` and `mozjpeg`, commit the compressed files, and skip the pre-build step entirely. That's one-time work and keeps the build fast.

---

## Summary of changes

| File | Change |
|---|---|
| `Gemfile` | Add `gem "jekyll-picture-tag", "~> 2.1"` |
| `_config.yml` | Add `jekyll-picture-tag` to `plugins`, add `picture:` preset block |
| `_layouts/post.html` | Replace `<img>` with `{% picture hero page.hero_image %}` |
| Post front matter | Add `hero_image: filename.jpg` to each post |
| `netlify.toml` | Add `JEKYLL_ENV=production`, cache `_site/generated` |
| Optionally | Run `sharp` or `cwebp` pre-build on originals |

### Estimated improvement

- Before: 3MB JPEG per page, no lazy loading → ~3MB image payload, LCP ~5s
- After: 480w WebP (~50KB) on mobile, 1200w WebP (~200KB) on desktop, lazy below-fold → ~200KB image payload, LCP <1.5s
