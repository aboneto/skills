# Responsive Images with WebP Fallback and Lazy Loading — Jekyll Travel Blog

## The Problem

150 posts × 3MB hero photo = 450MB of raw images being served as uncompressed JPEGs. At 5+ Mbps average mobile connections, that's a 2.4-second load just for images — before any HTML downloads. LCP (Largest Contentful Paint) suffers directly because the hero image is the largest thing the browser finds.

The fix has four layers:
1. **Compress** — 3MB → ~200KB WebP (90%+ reduction)
2. **Resize** — Generate 3–4 widths so mobile doesn't download desktop size
3. **Modern formats** — WebP for modern browsers, JPEG fallback
4. **Lazy load** — Don't fetch below-fold images at all

Because you're on Netlify, you can use any plugin you want. `jekyll-picture-tag` handles all four layers automatically at build time.

---

## 1. Gemfile

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-paginate-v2",   "~> 3.0"
  gem "jekyll-picture-tag",   "~> 2.1"   # ← add this
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"
gem "jekyll-include-cache", "~> 0.2"

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
```

`jekyll-picture-tag` is not on the GitHub Pages allowlist, which is fine — Netlify builds your site, not GitHub.

Then run:

```bash
bundle install
```

---

## 2. _config.yml — plugin and picture settings

```yaml
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-paginate-v2
  - jekyll-include-cache
  - jekyll-picture-tag   # ← add this

picture:
  source: assets/images          # where your original 3MB photos live
  output: generated              # processed images go to _site/generated/
  presets:
    hero:
      formats: [webp, jpeg]     # WebP first, JPEG fallback
      widths: [400, 800, 1200, 1600]
      attributes:
        img: 'loading="lazy" decoding="async"'
    thumbnail:
      formats: [webp, jpeg]
      widths: [200, 400, 600]
      attributes:
        img: 'loading="lazy" decoding="async"'
```

The `generated/` directory is cacheable — only new/changed images get reprocessed on subsequent builds. Add it to your `.gitignore` if you don't want to commit processed images (or add it if you do — saves rebuild time).

---

## 3. Layout changes — post.html (or wherever your hero image lives)

### Option A: Use `jekyll-picture-tag` (recommended — handles everything automatically)

In your post layout, replace the hardcoded `<img>` for the hero:

```liquid
{% if page.hero %}
  {% picture hero {{ page.hero }} --alt {{ page.excerpt | default: page.title }} %}
{% endif %}
```

Or with explicit srcset control using a Liquid include:

```liquid
{% assign hero = page.hero | split: '.' %}
{% assign ext = hero | last %}
{% assign base = hero | join: '.' | replace: '.' | append: ext %}

<picture>
  <source
    type="image/webp"
    srcset="
      {% for w in (400,800,1200,1600) %}
        {{ base }}-{{ w }}.webp {{ w }}w{% unless forloop.last %},{% endunless %}
      {% endfor %}
    "
    sizes="(min-width: 768px) 1200px, 100vw">
  <img
    src="{{ page.hero | relative_url }}"
    srcset="
      {% for w in (400,800,1200,1600) %}
        {{ base }}-{{ w }}.jpg {{ w }}w{% unless forloop.last %},{% endunless %}
      {% endfor %}
    "
    sizes="(min-width: 768px) 1200px, 100vw"
    alt="{{ page.excerpt | default: page.title }}"
    loading="lazy"
    decoding="async"
    width="1200"
    height="675">
</picture>
```

But the cleanest approach is just `{% picture %}`:

```liquid
{% picture hero {{ page.hero }} --alt {{ page.excerpt | default: page.title }} %}
```

The `hero` preset in `_config.yml` tells it to generate WebP + JPEG at 400/800/1200/1600px with lazy loading attributes.

### Option B: Hand-rolled responsive images (no plugin)

If you want to avoid the plugin entirely, generate the variants yourself before building and use this markup pattern:

```html
<img
  src="{{ '/assets/images/hero-1200.jpg' | relative_url }}"
  srcset="
    /assets/images/hero-400.jpg  400w,
    /assets/images/hero-800.jpg  800w,
    /assets/images/hero-1200.jpg 1200w,
    /assets/images/hero-1600.jpg 1600w"
  sizes="(min-width: 768px) 1200px, 100vw"
  alt="{{ page.excerpt | default: page.title }}"
  loading="lazy"
  decoding="async"
  width="1200"
  height="675">
```

You'd pre-generate the variants with ImageMagick or `sharp` (see Build Pipeline section).

### Critical rule — hero images must NOT be lazy loaded

Above-the-fold images should use `loading="eager"`:

```liquid
{% picture hero {{ page.hero }} --alt {{ page.excerpt }} %}
```

This gets baked in via the `attributes.img` in the preset. But if you're hand-rolling, make sure your post hero has `loading="eager"` — it's the single biggest LCP improvement you can make.

---

## 4. Post front matter — declare the hero image path

In each post's front matter:

```yaml
---
layout: post
title: "Hiking the Dolomites"
date: 2026-05-01 08:00:00 +0100
hero: /assets/images/dolomites-hero.jpg   # path to the original 3MB image
excerpt: "Three days of via ferratas above the clouds."
---
```

`jekyll-picture-tag` reads the `hero` value, looks for the file in `assets/images/`, and generates all variants automatically.

---

## 5. Build pipeline — pre-processing with Sharp

`jekyll-picture-tag` does image processing at build time, but with 150 posts × 3MB photos, it can be slow if it has to process everything from scratch every build. The `sharp` CLI in a pre-build step is faster and gives you more control.

### netlify.toml (root of your repo)

```toml
[build]
  command = "npm run build:images && bundle exec jekyll build"
  publish = "_site"

[build.environment]
  JEKYLL_ENV = "production"
  RUBY_VERSION = "3.4.8"

[[plugins]]
  type = "build"
  name = "@netlify/plugin-cache-nextjs"
```

### Build script (scripts/build-images.js)

```javascript
#!/usr/bin/env node
const sharp = require('sharp');
const glob = require('fast-glob');
const path = require('path');
const fs = require('fs');

const SOURCE = 'assets/images';
const OUTPUT = 'assets/images-optimized';
const WIDTHS = [400, 800, 1200, 1600];

async function processImage(srcPath) {
  const dir = path.dirname(srcPath).replace(SOURCE, OUTPUT);
  fs.mkdirSync(dir, { recursive: true });

  const image = sharp(srcPath);
  const meta = await image.metadata();

  await Promise.all(
    WIDTHS.filter(w => w < meta.width).map(async (w) => {
      const name = path.basename(srcPath, path.extname(srcPath));
      const webpOut = path.join(dir, `${name}-${w}.webp`);
      const jpgOut = path.join(dir, `${name}-${w}.jpg`);

      await Promise.all([
        image.clone().resize(w).webp({ quality: 80 }).toFile(webpOut),
        image.clone().resize(w).jpeg({ quality: 85 }).toFile(jpgOut),
      ]);
    })
  );

  // Also generate the original-format version at full width for fallback
  const name = path.basename(srcPath, path.extname(srcPath));
  await image.clone().jpeg({ quality: 90 }).toFile(path.join(dir, `${name}-original.jpg`));
  await image.clone().webp({ quality: 80 }).toFile(path.join(dir, `${name}-original.webp`));
}

async function main() {
  const files = await glob(`${SOURCE}/**/*.{jpg,jpeg,png}`, { absolute: true });
  console.log(`Processing ${files.length} images...`);
  await Promise.all(files.map(processImage));
  console.log('Done.');
}

main().catch(console.error);
```

Run it:

```bash
npm install sharp fast-glob
chmod +x scripts/build-images.js
node scripts/build-images.js
```

This is a pre-build step. Netlify runs `npm run build:images` (defined in `package.json`) before Jekyll. Add to `package.json`:

```json
{
  "scripts": {
    "build:images": "node scripts/build-images.js"
  },
  "devDependencies": {
    "sharp": "^0.33",
    "fast-glob": "^3.3"
  }
}
```

**Caching**: Netlify caches `node_modules/` between builds. If you have a `vendor/` or `generated/` directory with processed images, cache that too. Add this to `netlify.toml`:

```toml
[build]
  command = "bundle exec jekyll build"
  publish = "_site"

[build.environment]
  JEKYLL_ENV = "production"
  RUBY_VERSION = "3.4.8"
```

Add a `.netlify/cache-opt-in` marker or use Netlify's build plugins to cache the image output directory. The `sharp` processing is the expensive part — you only want to rerun it when images actually change.

---

## 6. Layout update — responsive images in post.html

Assuming your posts use `_layouts/post.html`, update the hero section:

```liquid
<article class="post">
  {% if page.hero %}
  <header class="post-hero">
    {% picture hero {{ page.hero }} --alt {{ page.excerpt | default: page.title }} %}
  </header>
  {% endif %}

  <h1>{{ page.title }}</h1>
  <time>{{ page.date | date: "%B %-d, %Y" }}</time>
  {{ content }}
</article>
```

And add CSS to prevent layout shift:

```css
.post-hero img {
  width: 100%;
  height: auto;
  aspect-ratio: 16 / 9;
  object-fit: cover;
}
```

The `width` and `height` attributes on every `<img>` prevent Cumulative Layout Shift (CLS) — without these, images cause the page to jump as they load, which kills your Core Web Vitals score.

---

## 7. Netlify-specific headers for aggressive caching

Create `_headers` file in your repo root (already in the `include:` list in `_config.yml`):

```
/generated/*
  Cache-Control: public, max-age=31536000, immutable

/*.webp
  Cache-Control: public, max-age=31536000, immutable

/*.jpg
  Cache-Control: public, max-age=31536000, immutable
```

WebP and the processed variants never change — once generated, they get a content hash in the filename (handled by `jekyll-picture-tag`). Aggressive caching means return visitors never re-download your hero images.

---

## 8. Full pipeline summary

```
┌─────────────────────────────────────────────────────────────────┐
│  Local / Netlify build                                           │
│                                                                  │
│  1. npm run build:images                                         │
│     → sharp processes 150 × 3MB photos → 5-8 sizes × 2 formats  │
│     → outputs to assets/images-optimized/                       │
│     → cached between builds (only reprocess changed images)      │
│                                                                  │
│  2. bundle exec jekyll build                                     │
│     → jekyll-picture-tag generates <picture> elements           │
│     → outputs to _site/generated/                                │
│     → fingerprinting via content hash                           │
│                                                                  │
│  3. Netlify serves _site/                                        │
│     → _headers enables immutable cache for generated/            │
│     → WebP served to Chromium browsers, JPEG to Safari < 14     │
└─────────────────────────────────────────────────────────────────┘
```

Expected results:
- Hero images: 3MB → ~150KB WebP at 1600px (95% reduction)
- Mobile downloads: 1600px image → 400px version = ~25KB
- LCP improvement: 5+ seconds → under 2 seconds (depending on network)
- CLS: eliminated by `width`/`height` attributes
- Lighthouse Performance: 40–50 range → 85–95 range

---

## Key files to modify

| File | Change |
|---|---|
| `Gemfile` | Add `jekyll-picture-tag` to `:jekyll_plugins` |
| `_config.yml` | Add `jekyll-picture-tag` to plugins + `picture:` preset config |
| `_layouts/post.html` | Replace `<img>` with `{% picture %}` tag |
| `netlify.toml` | Add `npm run build:images` pre-step, set `JEKYLL_ENV=production` |
| `_headers` | Aggressive cache headers for `generated/` |
| `_posts/2026-*.md` | Add `hero: /assets/images/...` to front matter |
| `package.json` | Add `sharp`, `fast-glob`, `build:images` script |
| `scripts/build-images.js` | Pre-processing script (optional but recommended) |

---

## What you don't need to do

- **Don't** pre-generate all the `photo-400.webp`, `photo-800.webp` variants manually. `jekyll-picture-tag` does it at build time, or `sharp` does it in the pre-build step.
- **Don't** use a JavaScript-based lazy loader (lazysizes, etc.) — native `loading="lazy"` is supported in all browsers in 2026 and has zero runtime cost.
- **Don't** serve AVIF unless you're willing to wait a long time in CI. WebP at quality 80 gives you ~90% of the gain at 10% of the compute cost. If you do want AVIF, add it as a third format in the preset but know that encoding is 5–10× slower than WebP.

---

## Verification

After implementing, run Lighthouse against your Netlify preview URL:

```bash
npx Lighthouse https://your-preview-url.netlify.app --preset desktop
```

Focus on:
- **LCP** (target: < 2.5s) — should drop dramatically on hero images
- **CLS** (target: < 0.1) — `width`/`height` attributes fix this
- **Total Blocking Time** — large images blocking the main thread during decode

Also check in Chrome DevTools → Network →Img to confirm `.webp` variants are being requested by Chromium browsers and `.jpg` fallback is used in Safari.