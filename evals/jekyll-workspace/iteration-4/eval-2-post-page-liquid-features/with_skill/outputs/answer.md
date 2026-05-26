# Post Page Features: Reading Time, TOC, and Related Posts

All three features use Jekyll's built-in capabilities — no extra gems required.

---

## 1. Estimated Reading Time

### Option A: Pure Liquid (no plugin needed)

Add this snippet wherever you want the reading time to appear in your post layout (`_layouts/post.html`):

```liquid
{% assign words = page.content | number_of_words %}
{% assign minutes = words | divided_by: 200 | plus: 1 %}
<span class="reading-time">{{ minutes }} min read</span>
```

### Option B: Custom filter (cleaner syntax in templates)

Create `_plugins/reading_time.rb`:

```ruby
module Jekyll
  module ReadingTimeFilter
    def reading_time(input)
      words = input.to_s.split.length
      minutes = (words / 200.0).ceil
      minutes < 1 ? "less than a minute" : "#{minutes} min read"
    end
  end
end
Liquid::Template.register_filter(Jekyll::ReadingTimeFilter)
```

Then in your layout:

```liquid
<span class="reading-time">{{ page.content | reading_time }}</span>
```

### Option C: Hook (precomputed, fastest builds)

Create `_plugins/reading_time_hook.rb`:

```ruby
Jekyll::Hooks.register :posts, :post_init do |post|
  word_count = post.content.split.size
  post.data["reading_minutes"] = (word_count / 200.0).ceil
end
```

Then in your layout:

```liquid
<span class="reading-time">{{ page.reading_minutes }} min read</span>
```

**Recommendation:** Option A for simplicity (zero files to add). Option C if you have many posts and want to avoid recomputing on every template render.

---

## 2. Table of Contents (H2 and H3 only)

### Step 1: Configure kramdown in `_config.yml`

```yaml
kramdown:
  input: GFM
  auto_ids: true
  toc_levels: 2..3
```

`toc_levels: 2..3` restricts the TOC to H2 and H3 headings only. `auto_ids: true` (the default) ensures each heading gets an `id` attribute for anchor links.

### Step 2: Add the TOC to your post layout

In `_layouts/post.html`, place this before `{{ content }}`:

```markdown
* TOC
{:toc}
```

Or with a CSS class for styling:

```markdown
* Table of contents
{:toc .post-toc}
```

**Full `_layouts/post.html` example:**

```html
---
layout: default
---
<article class="post">
  <header>
    <h1>{{ page.title }}</h1>
    <time>{{ page.date | date: "%B %-d, %Y" }}</time>
    · {{ page.content | number_of_words | divided_by: 200 | plus: 1 }} min read
  </header>

  <nav class="post-toc">
    <p><strong>Table of contents</strong></p>

  * TOC
  {:toc}
  </nav>

  {{ content }}

  {% assign related = "" | split: "" %}
  {% assign my_tags = page.tags %}
  {% for p in site.posts %}
    {% if p.url == page.url %}{% continue %}{% endif %}
    {% assign combined = p.tags | concat: my_tags %}
    {% assign deduped = combined | uniq %}
    {% if deduped.size < combined.size %}
      {% assign related = related | push: p %}
    {% endif %}
  {% endfor %}

  {% if related.size > 0 %}
  <aside class="related-posts">
    <h2>Related posts</h2>
    <ul>
      {% for p in related limit:3 %}
        <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
      {% endfor %}
    </ul>
  </aside>
  {% endif %}
</article>
```

**Skip a heading from the TOC** by adding `{:.no_toc}` directly after it:

```markdown
## Internal notes
{:.no_toc}
```

---

## 3. Related Posts by Shared Tags

This uses a pure Liquid approach — no `--lsi` or `classifier-reborn` gem needed.

```liquid
{% assign related = "" | split: "" %}
{% assign my_tags = page.tags %}
{% for p in site.posts %}
  {% if p.url == page.url %}{% continue %}{% endif %}
  {% assign combined = p.tags | concat: my_tags %}
  {% assign deduped = combined | uniq %}
  {% if deduped.size < combined.size %}
    {% assign related = related | push: p %}
  {% endif %}
{% endfor %}

{% if related.size > 0 %}
<section class="related-posts">
  <h2>Related posts</h2>
  <ul>
    {% for p in related limit:3 %}
      <li>
        <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
        <span class="post-date">{{ p.date | date: "%B %-d, %Y" }}</span>
      </li>
    {% endfor %}
  </ul>
</section>
{% endif %}
```

**How it works:** For each other post, it concatenates both tag arrays and removes duplicates. If the deduplicated array is smaller than the combined one, at least one tag matched. This avoids the slow `--lsi` flag and works entirely with built-in Liquid filters (`concat`, `uniq`).

**Optional: sort by number of shared tags** (most related first). Add a scoring step:

```liquid
{% assign related = "" | split: "" %}
{% assign scores = "" | split: "" %}
{% assign my_tags = page.tags %}
{% for p in site.posts %}
  {% if p.url == page.url %}{% continue %}{% endif %}
  {% assign combined = p.tags | concat: my_tags %}
  {% assign deduped = combined | uniq %}
  {% assign overlap = combined.size | minus: deduped.size %}
  {% if overlap > 0 %}
    {% assign related = related | push: p %}
  {% endif %}
{% endfor %}
```

---

## Complete `_layouts/post.html`

Here's the full layout putting all three features together:

```html
---
layout: default
---
<article class="post">
  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
    <div class="post-meta">
      <time datetime="{{ page.date | date_to_xmlschema }}">
        {{ page.date | date: "%B %-d, %Y" }}
      </time>
      · {{ page.content | number_of_words | divided_by: 200 | plus: 1 }} min read
    </div>
    {% if page.tags.size > 0 %}
    <div class="post-tags">
      {% for tag in page.tags %}
        <span class="tag">{{ tag }}</span>
      {% endfor %}
    </div>
    {% endif %}
  </header>

  <nav class="table-of-contents" aria-label="Table of contents">
    <p><strong>Contents</strong></p>

  * TOC
  {:toc}
  </nav>

  <div class="post-content">
    {{ content }}
  </div>

  {% assign related = "" | split: "" %}
  {% assign my_tags = page.tags %}
  {% for p in site.posts %}
    {% if p.url == page.url %}{% continue %}{% endif %}
    {% assign combined = p.tags | concat: my_tags %}
    {% assign deduped = combined | uniq %}
    {% if deduped.size < combined.size %}
      {% assign related = related | push: p %}
    {% endif %}
  {% endfor %}

  {% if related.size > 0 %}
  <aside class="related-posts">
    <h2>Related posts</h2>
    <ul>
      {% for p in related limit:3 %}
        <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
      {% endfor %}
    </ul>
  </aside>
  {% endif %}
</article>
```

---

## `_config.yml` additions

Add or update the kramdown section:

```yaml
markdown: kramdown

kramdown:
  input: GFM
  auto_ids: true
  toc_levels: 2..3
  syntax_highlighter: rouge
```

---

## Where each piece lives

| Feature | File(s) | Approach |
|---|---|---|
| Reading time | `_layouts/post.html` | Pure Liquid (or `_plugins/reading_time.rb` for filter) |
| Table of contents | `_config.yml` + `_layouts/post.html` | kramdown built-in `{:toc}` |
| Related posts | `_layouts/post.html` | Pure Liquid with `concat`/`uniq` |

No gems to add. No `Gemfile` changes. Works on Jekyll 4.4 with kramdown out of the box.
