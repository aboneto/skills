# Post Page: Reading Time, Table of Contents, and Related Posts

Everything below goes into `_layouts/post.html` (create it if it doesn't exist) or you can split each feature into its own `_includes/*.html` file and `{% include ... %}` them into the layout.

---

## (a) Estimated Reading Time

Put this anywhere inside the post layout's `<article>` (or similar container):

```liquid
{% assign words = page.content | number_of_words %}
{% assign minutes = words | divided_by: 200 | plus: 1 %}
{{ minutes }} min read
```

This counts words in `page.content`, divides by 200 (average reading speed), and adds 1 so the minimum is "1 min read" rather than "0 min read".

**Optional:** turn it into a reusable include file at `_includes/reading_time.html`:

```liquid
{% assign words = page.content | number_of_words %}
{% assign minutes = words | divided_by: 200 | plus: 1 %}
{{ minutes }} min read
```

Then in the layout: `{% include reading_time.html %}`.

**Plugin alternative:** write a custom Liquid filter in `_plugins/reading_time.rb` (see `references/plugins.md`), but the inline snippet above is simpler and requires zero plugin code.

---

## (b) Table of Contents (H2 and H3 headings)

kramdown has a built-in TOC generator — **no plugin needed**.

Inside your post layout, include this where you want the TOC:

```markdown
* This unordered list item is required but its text is ignored
{:toc}
```

But since you're inside a Liquid template (`.html`), wrap it in a `{% capture %}` or use `markdownify`:

```liquid
{% capture toc %}
* TOC
{:toc}
{% endcapture %}
{{ toc | markdownify }}
```

Or the simpler approach — put the TOC directly in your Markdown **post files**:

```markdown
---
layout: post
title: "My Post"
tags: [jekyll, tutorial]
---

* TOC
{:toc}

## Introduction

Post content here...
```

If you want it to appear automatically on every post without editing each one, use the capture approach in the layout.

**Control heading levels** in `_config.yml`:

```yaml
kramdown:
  input: GFM
  auto_ids: true
  toc_levels: 2..3       # only H2 and H3 in the TOC
```

Exclude specific headings from the TOC:

```markdown
## Don't show me {:.no_toc}
```

For a class on the TOC `<ul>`: `{:toc .doc-toc}`.

---

## (c) Related Posts via Shared Tags

Jekyll's built-in `site.related_posts` requires `--lsi` (Latent Semantic Indexing) plus the `classifier-reborn` gem and is slow. The pragmatic alternative is tag overlap — a post is "related" if it shares at least one tag with the current page.

Add this to the post layout where you want the related list:

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
  <h3>Related Posts</h3>
  <ul>
  {% for p in related limit: 5 %}
    <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
  {% endfor %}
  </ul>
{% endif %}
```

**How it works:** for every other post, it concatenates that post's tags with the current page's tags. If the deduplicated array is smaller than the sum, at least one tag matched.

---

## Putting It All Together — Complete `_layouts/post.html`

```liquid
---
layout: default
---

<article>
  <header>
    <h1>{{ page.title }}</h1>
    <time>{{ page.date | date: "%B %-d, %Y" }}</time>
    {% assign words = page.content | number_of_words %}
    {% assign minutes = words | divided_by: 200 | plus: 1 %}
    — {{ minutes }} min read
  </header>

  {% capture toc %}
  * TOC
  {:toc}
  {% endcapture %}
  {{ toc | markdownify }}

  {{ content }}

  {%- comment -%} Related posts via shared tags {%- endcomment -%}
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
    <hr>
    <h2>Related Posts</h2>
    <ul>
    {% for p in related limit: 5 %}
      <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {% endfor %}
    </ul>
  {% endif %}
</article>
```

---

## Key `_config.yml` Settings

```yaml
markdown: kramdown

kramdown:
  input: GFM
  auto_ids: true
  toc_levels: 2..3    # H2 and H3 only
```

`auto_ids: true` is required for the TOC — kramdown generates `id` attributes on headings from their text. `toc_levels: 2..3` restricts the TOC to H2 and H3 as requested.

---

## No Extra Plugins Required

All three features are built-in Liquid or kramdown — zero `Gemfile` changes. The only assumption is `markdown: kramdown` (Jekyll's default). If the TOC doesn't render, verify `auto_ids: true` is set in the kramdown config and restart `jekyll serve`.
