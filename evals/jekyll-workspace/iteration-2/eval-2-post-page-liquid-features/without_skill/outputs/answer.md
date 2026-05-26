# Adding Reading Time, Table of Contents, and Related Posts to a Jekyll Post Layout

**Jekyll 4.4, kramdown, no plugins required.**

All three features live in your `_layouts/` and `_includes/` directories. The `_layouts/post.html` pulls everything together.

---

## 1. Estimated Reading Time

**File:** `_includes/reading-time.html`

```liquid
{% assign words = content | number_of_words %}
{% assign wpm = 200 %}
{% assign minutes = words | divided_by: wpm %}

{% if minutes == 0 %}
  Less than 1 min read
{% else %}
  {{ minutes }} min read
{% endif %}
```

`number_of_words` works on the rendered HTML text. 200 wpm is a comfortable reading speed; adjust as desired.

---

## 2. Table of Contents (H2 / H3)

**File:** `_includes/toc.html`

```liquid
{% assign toc = "" | split: "" %}
{% assign headings = content | split: "<h2" %}

{% for h2 in headings offset: 1 %}
  {% assign h2_id = h2 | split: 'id="' | last | split: '"' | first %}
  {% assign h2_text = h2 | split: "</h2>" | first | strip_html | strip %}
  {% capture h2_entry %}- <a href="#{{ h2_id }}">{{ h2_text }}</a>{% endcapture %}
  {% assign toc = toc | push: h2_entry %}

  {% assign h3chunks = h2 | split: "<h3" %}
  {% for h3 in h3chunks offset: 1 %}
    {% assign h3_id = h3 | split: 'id="' | last | split: '"' | first %}
    {% assign h3_text = h3 | split: "</h3>" | first | strip_html | strip %}
    {% capture h3_entry %}  - <a href="#{{ h3_id }}">{{ h3_text }}</a>{% endcapture %}
    {% assign toc = toc | push: h3_entry %}
  {% endfor %}
{% endfor %}

{% if toc.size > 0 %}
<nav class="toc">
  <h3>Contents</h3>
  <ul>
  {% for item in toc %}
    <li>{{ item | markdownify | remove: "<p>" | remove: "</p>" | strip }}</li>
  {% endfor %}
  </ul>
</nav>
{% endif %}
```

**How it works:** kramdown auto-generates `id` attributes on headings (`#h2-text`). This include parses the rendered `content`, extracts all `<h2>` and `<h3>` elements with their IDs, and builds a nested list of anchor links.

---

## 3. Related Posts (by shared tags)

**File:** `_includes/related-posts.html`

```liquid
{% assign related = "" | split: "" %}

{% for post in site.posts %}
  {% if post.url != page.url %}
    {% assign common = post.tags | intersect: page.tags %}
    {% if common.size > 0 %}
      {% assign related = related | push: post %}
    {% endif %}
  {% endif %}
{% endfor %}

{% if related.size > 0 %}
<aside class="related">
  <h3>Related Posts</h3>
  <ul>
  {% for post in related limit:5 %}
    <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
  {% endfor %}
  </ul>
</aside>
{% endif %}
```

`intersect` is a native Liquid filter — no plugin needed. `limit:5` keeps it tidy.

---

## 4. Putting It All Together

**File:** `_layouts/post.html`

```liquid
---
layout: default
---

<article>
  <h1>{{ page.title }}</h1>

  <p class="meta">
    <time>{{ page.date | date: "%b %d, %Y" }}</time>
    &middot;
    {% include reading-time.html %}
  </p>

  {% include toc.html %}

  {{ content }}

  {% include related-posts.html %}
</article>
```

---

## Important Notes

| Concern | Detail |
|---|---|
| **kramdown TOC IDs** | kramdown slugs headings automatically (e.g. `## My Heading` → `id="my-heading"`). No `{:toc}` needed in your markdown. |
| **`content` variable** | The layout's `{{ content }}` is the **rendered HTML** of the post, not raw markdown. The includes above all parse HTML, which is what we want. |
| **Order of operations** | `toc.html` must be included **before** `{{ content }}` so the TOC appears at the top. It can parse `content` because Liquid evaluates the variable before outputting it. |
| **Escaping** | If post titles or headings contain HTML entities or special chars, the `strip_html` and `strip` filters handle them safely. |
| **Performance** | For very large sites (1000+ posts), iterating `site.posts` on every post page can be slow. Consider `jekyll-tagories` or a JSON lookup if that becomes a problem. |
| **No plugin fallback** | All code above is pure Liquid — works out of the box with Jekyll 4.4. |

---

### Alternative: `jekyll-toc` plugin

If you prefer a zero-maintenance TOC, the [`jekyll-toc`](https://github.com/allejo/jekyll-toc) gem is a drop-in:

```liquid
{% include toc.html html=content %}
```

But the pure-Liquid version above gives you full control and zero dependencies.
