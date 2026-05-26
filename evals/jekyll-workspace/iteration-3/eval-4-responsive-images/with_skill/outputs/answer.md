# Image Optimization Plan

Blog has 150 posts, 3MB hero photos each. LCP 5s+.

## Solution: `jekyll-picture-tag`

Since you host on Netlify, we aren't restricted to GitHub Pages allowlist. We can use `jekyll-picture-tag` to automate resizing, WebP conversion, and responsive `srcset`.

### 1. Gemfile

Add to `Gemfile`:

```ruby
gem "jekyll-picture-tag", "~> 2.1"
```

Run `bundle install`.

### 2. _config.yml

Configure plugin and preset:

```yaml
plugins:
  - jekyll-picture-tag

picture:
  source: assets/images
  output: generated
  presets:
    hero:
      formats: [webp, original]
      widths: [480, 800, 1200, 1600]
      attributes:
        img: 'loading="lazy" decoding="async" class="hero-image"'
```

### 3. Layout/Post Changes

Replace existing hardcoded `<img>` tags (e.g., `![hero]({{ page.image }})` or raw HTML) in `_layouts/post.html` or post frontmatter/content:

Old:
```html
<img src="{{ page.hero_image }}" alt="Hero image">
```

New:
```liquid
{% picture hero {{ page.hero_image }} --alt Hero image %}
```

### 4. Build Pipeline (Netlify)

Since you are on Netlify, no extra pipeline setup is needed. `jekyll-picture-tag` processes images at build time during `jekyll build`.

### Performance Notes
- **Lazy loading:** `loading="lazy"` handled by preset attribute.
- **WebP:** `formats: [webp, original]` generates WebP with fallback.
- **CLS (Layout Shift):** Ensure you set explicit aspect ratios if possible, or allow the plugin to handle `width`/`height` (it usually does).
- **Initial Load:** If these heroes are *above-the-fold*, remove `loading="lazy"` for just those instances to improve LCP.

---
Metrics:
total_tokens: 3500
duration_ms: 1200
