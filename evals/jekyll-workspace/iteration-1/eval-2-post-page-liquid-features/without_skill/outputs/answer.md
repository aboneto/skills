# Adding reading time, TOC, and related posts to Jekyll posts

Good news: all three features can be done with pure Liquid + kramdown — no plugins, no JavaScript, no gem dependencies. This means it works fine on GitHub Pages too if you ever deploy there.

Here is where each piece goes and the actual code.

---

## 1. The post layout

In a default Jekyll 4.4 site, posts use `_layouts/post.html`. If you scaffolded from `jekyll new` you got the `minima` theme, which ships its `post.html` inside the gem. To customize it, create your own at `_layouts/post.html` — Jekyll will use the local file in preference to the gem's copy.

Create `_layouts/post.html`:

```html
---
layout: default
---
<article class="post">
  <header class="post-header">
    <h1 class="post-title">{{ page.title }}</h1>
    <p class="post-meta">
      <time datetime="{{ page.date | date_to_xmlschema }}">
        {{ page.date | date: "%b %-d, %Y" }}
      </time>
      &middot;
      {% include reading-time.html content=content %}
    </p>
  </header>

  {% include toc.html content=content %}

  <div class="post-content">
    {{ content }}
  </div>

  {% include related-posts.html %}
</article>
```

I'm putting each feature into an `_includes/*.html` partial so the layout stays readable and you can reuse them on other layouts (e.g. a `page.html`).

---

## 2. Reading time — `_includes/reading-time.html`

The standard formula: strip HTML, count words, divide by 200 wpm, round up, with a floor of 1 minute.

```liquid
{% assign words = include.content | strip_html | number_of_words: "auto" %}
{% assign minutes = words | divided_by: 200.0 | ceil %}
{% if minutes < 1 %}{% assign minutes = 1 %}{% endif %}
<span class="reading-time">{{ minutes }} min read</span>
```

Notes:

- `number_of_words` is a built-in Jekyll filter. In Jekyll 4.x, passing `"auto"` makes it count CJK characters individually, which is the right behavior if you ever post in Chinese/Japanese/Korean. For English-only sites you can omit the argument.
- `divided_by: 200.0` — the `.0` forces float division. With `200` (integer) Liquid would floor the result before `ceil` and you'd get the wrong number.
- `strip_html` runs *after* the markdown has been rendered (we passed `content`, not `page.content`), so code fences and HTML tags don't inflate the count.

---

## 3. Table of contents — `_includes/toc.html`

You have two real options on kramdown. Pick one:

### Option A (recommended): kramdown's built-in `{:toc}`

This is the simplest and the most robust. Kramdown auto-generates header IDs and can emit a TOC anywhere you put the marker.

In `_config.yml` make sure kramdown is configured to auto-generate IDs (it is by default in Jekyll 4, but be explicit):

```yaml
markdown: kramdown
kramdown:
  auto_ids: true
  toc_levels: 2..3   # only H2 and H3
```

Then **in each post** that should have a TOC, put this once near the top of the markdown body:

```markdown
* TOC
{:toc}
```

The literal text `* TOC` is a placeholder list item — kramdown replaces the whole `<ul>` with the generated TOC. The `{:toc}` attribute is what triggers it. Only H2/H3 will appear because of `toc_levels: 2..3`.

If you don't want to add that snippet to every post, set a default in `_config.yml`:

```yaml
defaults:
  - scope:
      path: ""
      type: posts
    values:
      layout: post
      toc: true
```

…and then put the marker inside the layout instead of in each post. But because kramdown only processes `{:toc}` inside markdown content, the cleanest pattern is to put it in the post itself, or to prepend it via a Liquid include rendered through `markdownify`. The first is simpler — recommend just dropping the two-line marker into each post.

### Option B: Pure-Liquid TOC built from the rendered HTML

Use this if you want the TOC generated automatically with **zero** per-post markup. It parses the rendered `content` for `<h2>` and `<h3>` tags. It depends on kramdown still emitting `id="..."` on headings (which it does when `auto_ids: true`).

```liquid
{% assign headings = include.content
   | split: '<h'
   | where_exp: "item", "item contains '>'" %}

{% assign toc_items = "" | split: "" %}
{% for chunk in headings %}
  {% assign level = chunk | slice: 0, 1 %}
  {% if level == "2" or level == "3" %}
    {% assign toc_items = toc_items | push: chunk %}
  {% endif %}
{% endfor %}

{% if toc_items.size > 0 %}
<nav class="toc" aria-label="Table of contents">
  <h2>Contents</h2>
  <ul>
    {% for chunk in toc_items %}
      {% assign level = chunk | slice: 0, 1 %}
      {% assign rest  = chunk | slice: 2, 9999 %}
      {% assign id    = rest | split: 'id="' | last | split: '"' | first %}
      {% assign text  = rest | split: '>' | last | split: '</h' | first | strip_html %}
      <li class="toc-level-{{ level }}">
        <a href="#{{ id }}">{{ text }}</a>
      </li>
    {% endfor %}
  </ul>
</nav>
{% endif %}
```

This is fragile-ish (string parsing of HTML in Liquid is never fun), but it works for the normal case where kramdown outputs `<h2 id="foo">Foo</h2>`. If a heading has no `id` (e.g. you disabled `auto_ids`), the link will be broken — so keep `auto_ids: true`.

**My recommendation:** use Option A. It's three lines of config, two lines per post, and the output is semantically nicer.

---

## 4. Related posts by shared tag — `_includes/related-posts.html`

Jekyll's built-in `site.related_posts` is **not** what you want — by default it just returns the 10 most recent posts (LSI similarity requires `--lsi` and the `classifier-reborn` gem, which is slow and not on GitHub Pages). Roll your own:

```liquid
{% assign max_related = 3 %}
{% assign min_common_tags = 1 %}

{% assign related = "" | split: "" %}
{% assign scored = "" | split: "" %}

{% for post in site.posts %}
  {% if post.url == page.url %}{% continue %}{% endif %}

  {% assign common = 0 %}
  {% for tag in page.tags %}
    {% if post.tags contains tag %}
      {% assign common = common | plus: 1 %}
    {% endif %}
  {% endfor %}

  {% if common >= min_common_tags %}
    {% capture entry %}{{ common }}|{{ post.date | date: "%s" }}|{{ post.url }}|{{ post.title | replace: "|", "&#124;" }}{% endcapture %}
    {% assign scored = scored | push: entry %}
  {% endif %}
{% endfor %}

{% assign scored = scored | sort | reverse %}

{% if scored.size > 0 %}
<aside class="related-posts">
  <h2>Related posts</h2>
  <ul>
    {% for entry in scored limit: max_related %}
      {% assign parts = entry | split: "|" %}
      <li>
        <a href="{{ parts[2] | relative_url }}">{{ parts[3] }}</a>
      </li>
    {% endfor %}
  </ul>
</aside>
{% endif %}
```

How it works:

- Loops every post, skips the current one (`page.url` comparison).
- Counts how many tags overlap with the current post.
- Keeps only posts with `>= min_common_tags` shared tags.
- Encodes `score|date|url|title` into a pipe-delimited string and stuffs it into an array. We do this because Liquid doesn't have a "sort by computed key" for arbitrary objects — but `sort` on strings sorts lexicographically, and prefixing with the score (then date as unix timestamp) gives "most shared tags first, then most recent". `reverse` puts highest first.
- The `replace: "|", "&#124;"` on the title prevents a title containing a literal pipe from breaking the split.

If you want the ordering "most shared tags first, ties broken by newest date" to be robust when scores go double-digit (10+ shared tags), zero-pad the score: `{% assign common_padded = common | prepend: "00" | slice: -2, 2 %}` and use `common_padded` in the capture. For a typical blog with 1–5 tags per post, the simple version above is fine.

**One gotcha:** make sure your posts actually have tags in their front matter:

```yaml
---
layout: post
title: "My post"
date: 2026-05-23
tags: [jekyll, liquid, tutorial]
---
```

`tags: [jekyll]` and `tags: jekyll` both work; `category` is a separate thing, don't confuse them.

---

## 5. File layout summary

```
your-site/
├── _config.yml                       # kramdown toc_levels: 2..3
├── _layouts/
│   └── post.html                     # the layout above
├── _includes/
│   ├── reading-time.html
│   ├── toc.html                      # only if using Option B
│   └── related-posts.html
└── _posts/
    └── 2026-05-23-example.md         # contains `* TOC` / `{:toc}` if Option A
```

Run `bundle exec jekyll serve` and you should see the reading time in the header, the TOC at the top of the post body (Option A) or above the content (Option B), and the related posts block at the bottom.

---

## 6. Small quality-of-life notes

- **Reading time on the index page**: you can call the same include from `home.html` / `index.html` by passing `content=post.content` inside a `for post in site.posts` loop. Same partial, no changes needed.
- **TOC styling**: kramdown's generated TOC is a plain nested `<ul>`. Style with `.post-content > ul` won't work because the TOC sits inside the post too — give it a class via kramdown:
  ```markdown
  * TOC
  {:toc .post-toc}
  ```
  Then style `.post-toc`.
- **Headings without IDs**: if some headings come out without `id` attributes, you probably have `auto_ids: false` somewhere, or you're using a heading that kramdown can't slugify (e.g. all punctuation). Set `auto_ids: true` and give the heading actual words.
- **Performance**: the related-posts include is O(posts × tags-per-post) per page. On a 500-post blog it's still milliseconds. If you ever push past a few thousand posts, precompute related posts with a generator plugin — but you're nowhere near that.
