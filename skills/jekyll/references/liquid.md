# Liquid Reference

Liquid is the templating language Jekyll uses. It has three concepts and that's it:

- **Objects** output content: `{{ page.title }}`
- **Tags** do logic and flow control: `{% if x %}...{% endif %}`
- **Filters** transform output: `{{ "hello" | upcase }}` → `HELLO`

This file is the cheatsheet for all three, plus the Jekyll-specific extensions that aren't in vanilla Liquid.

## Table of contents

1. [Variables you can read from anywhere](#variables-you-can-read-from-anywhere)
2. [Filters by category](#filters-by-category)
3. [Tags](#tags)
4. [Common patterns](#common-patterns)
5. [Whitespace control](#whitespace-control)
6. [Gotchas](#gotchas)

---

## Variables you can read from anywhere

### `site.*` — from `_config.yml` and the file tree

| Variable | What it is |
|---|---|
| `site.title`, `site.description`, `site.url`, `site.baseurl` | From `_config.yml` |
| `site.posts` | All posts, newest first |
| `site.pages` | All pages (everything with front matter that isn't a post/collection doc) |
| `site.static_files` | Files copied as-is (images, etc.) |
| `site.categories.NAME` | Posts in category `NAME` |
| `site.tags.NAME` | Posts tagged `NAME` |
| `site.data.FILENAME` | Contents of `_data/FILENAME.yml` (or `.json`, `.csv`, `.tsv`) |
| `site.collections` | All collections (including posts) |
| `site.time` | Build time |
| `site.MY_CUSTOM_KEY` | Anything you add to `_config.yml` |

### `page.*` — current page/post

| Variable | What it is |
|---|---|
| `page.title`, `page.url`, `page.content`, `page.excerpt` | The basics |
| `page.date` | Date from front matter or filename |
| `page.categories`, `page.tags` | Arrays |
| `page.path` | Source path relative to site root |
| `page.id` | Stable identifier (useful in feeds) |
| `page.next`, `page.previous` | Navigation between posts in chronological order |
| `page.MY_CUSTOM_KEY` | Any custom front matter key |

### `layout.*`

In a layout file, `layout.something` reads the layout's own front matter. Useful for layouts that wrap other layouts.

### `content`

Inside a layout, `{{ content }}` is the rendered content of whatever's using this layout. This is how layout nesting works.

### `paginator.*` (only with paginator plugin)

`paginator.posts`, `paginator.page`, `paginator.total_pages`, `paginator.previous_page_path`, `paginator.next_page_path`.

---

## Filters by category

Liquid ships with these. Jekyll adds extras (marked **J**).

### Strings

```liquid
{{ "hello world" | upcase }}                  → HELLO WORLD
{{ "HELLO WORLD" | downcase }}                → hello world
{{ "hello" | capitalize }}                    → Hello
{{ "hello world" | size }}                    → 11
{{ "hello" | append: " world" }}              → hello world
{{ "hello world" | prepend: "say: " }}        → say: hello world
{{ "hello world" | replace: "world", "you" }} → hello you
{{ "hello world" | remove: "l" }}             → heo word
{{ "hello world" | truncate: 8 }}             → hello...
{{ "hello world here" | truncatewords: 2 }}   → hello world...
{{ "  hi  " | strip }}                        → hi
{{ "<p>hi</p>" | strip_html }}                → hi
{{ "hi\nyou" | newline_to_br }}               → hi<br />you
{{ "Hello World" | slugify }}                 → hello-world           (J)
{{ "café" | slugify: "latin" }}               → cafe                  (J)
{{ "Hello" | markdownify }}                   → <p>Hello</p>          (J)
{{ "Hello" | smartify }}                      → "smart quotes"        (J)
```

### Numbers

```liquid
{{ 4 | plus: 2 }}              → 6
{{ 4 | minus: 2 }}             → 2
{{ 4 | times: 3 }}             → 12
{{ 16 | divided_by: 4 }}       → 4
{{ 16 | divided_by: 5 }}       → 3   (integer division)
{{ 16 | divided_by: 5.0 }}     → 3.2
{{ 16 | modulo: 3 }}           → 1
{{ 4.6 | round }}              → 5
{{ 4.6 | round: 1 }}           → 4.6
{{ 4.2 | ceil }}               → 5
{{ 4.8 | floor }}              → 4
{{ -5 | abs }}                 → 5
```

### Arrays

```liquid
{{ array | size }}
{{ array | first }}
{{ array | last }}
{{ array | join: ", " }}
{{ array | reverse }}
{{ array | sort }}                            (case-sensitive)
{{ array | sort_natural }}                    (case-insensitive)
{{ array | sort: "date" }}                    by property
{{ array | uniq }}
{{ array | compact }}                          remove nils
{{ array | concat: other_array }}
{{ array | where: "category", "news" }}        filter by property        (J)
{{ array | where_exp: "p", "p.date > now" }}  filter by expression       (J)
{{ array | group_by: "category" }}                                       (J)
{{ array | group_by_exp: "p", "p.date | date: '%Y'" }}                   (J)
{{ array | map: "title" }}                     pluck property
{{ array | find: "title", "Hello" }}           first match               (J, Jekyll 4.2+)
{{ array | find_exp: "p", "p.draft != true" }}                           (J, Jekyll 4.2+)
{{ array | sample }}                           random element            (J)
{{ array | sample: 3 }}                                                  (J)
```

### Dates

```liquid
{{ page.date | date: "%Y-%m-%d" }}             → 2026-05-22
{{ page.date | date: "%B %-d, %Y" }}           → May 22, 2026
{{ page.date | date: "%I:%M %p" }}             → 03:30 PM
{{ page.date | date_to_string }}               → 22 May 2026            (J)
{{ page.date | date_to_long_string }}          → 22 May 2026            (J)
{{ page.date | date_to_xmlschema }}            → 2026-05-22T15:30:00Z   (J, for feeds)
{{ page.date | date_to_rfc822 }}                                         (J, for RSS)
```

Full strftime cheat: `%Y` year, `%m` month, `%d` day, `%B` month name, `%b` abbreviated month, `%H` 24h hour, `%I` 12h hour, `%M` minute, `%S` second, `%p` AM/PM, `%A` day name, `%-d` day without leading zero.

### URLs (Jekyll-specific, critical)

```liquid
{{ "/about/" | relative_url }}     → /baseurl/about/    use for in-site links
{{ "/about/" | absolute_url }}     → https://site.com/baseurl/about/   for feeds, OG tags
{{ "page.html" | url_encode }}     for query strings
{{ "page.html" | uri_escape }}     RFC 3986 escape
```

**The single most common Jekyll bug is hardcoding paths like `<a href="/about/">`.** This breaks the moment you deploy with a `baseurl`. Always pipe through `relative_url`.

### Files / assets

```liquid
{{ "logo.png" | asset_url }}        if your theme defines it
{% asset "logo.png" %}              with jekyll-assets plugin
```

### Booleans / coercion

```liquid
{{ value | default: "fallback" }}      use fallback if nil/false/empty
```

---

## Tags

### Output (Liquid built-in)

```liquid
{% assign x = "hello" %}
{% assign posts = site.posts | where: "category", "news" %}

{% capture greeting %}
  Hello, {{ page.title }}
{% endcapture %}
{{ greeting }}

{% increment counter %}    {%- comment -%} 0, 1, 2 across uses on the page {%- endcomment -%}
{% decrement counter %}
```

### Conditionals

```liquid
{% if page.tags contains "featured" %}
  ★
{% elsif page.draft %}
  (draft)
{% else %}
  normal
{% endif %}

{% unless page.published == false %}
  publish
{% endunless %}

{% case page.layout %}
  {% when "post" %}…
  {% when "page" %}…
  {% else %}…
{% endcase %}
```

Operators: `==`, `!=`, `<`, `>`, `<=`, `>=`, `and`, `or`, `contains` (for strings and arrays — there is no `in` keyword).

Truthiness: only `false` and `nil` are falsy. Empty string `""` and `0` are truthy. This bites Python and JS devs.

### Loops

```liquid
{% for post in site.posts limit:5 offset:2 %}
  {{ post.title }}
  {% if forloop.first %}(latest!){% endif %}
  {% if forloop.last %}(end){% endif %}
  index: {{ forloop.index }} of {{ forloop.length }}
{% endfor %}

{% for post in site.posts reversed %}
{% endfor %}

{% for i in (1..5) %}{{ i }}{% endfor %}    → 12345

{% break %}      exit the loop
{% continue %}   skip iteration
```

### Includes (partials)

```liquid
{% include header.html %}

{%- comment -%} pass parameters — they become include.LABEL inside header.html {%- endcomment -%}
{% include button.html label="Click me" url="/x/" %}

{%- comment -%} dynamic include path {%- endcomment -%}
{% assign name = "header" %}
{% include {{ name }}.html %}

{%- comment -%} include from a path relative to the current file {%- endcomment -%}
{% include_relative footnotes.md %}

{%- comment -%} cached include — much faster, but parameters baked in on first render {%- endcomment -%}
{% include_cached nav.html %}
```

`include_cached` is a huge perf win on big sites — use it for components that produce identical output every time (footer, navigation), but **not** for parameterized includes.

### Linking to posts (avoid hardcoded URLs)

```liquid
{% post_url 2026-05-22-hello %}
{%- comment -%} → /2026/05/22/hello/   regardless of permalink settings {%- endcomment -%}

<a href="{% post_url 2026-05-22-hello %}">read this</a>
```

If you rename or re-date the post, this still works. Hardcoded links don't.

### Linking to other pages/docs

```liquid
{% link _docs/install.md %}
{% link about.md %}
```

### Code highlighting

```liquid
{% highlight ruby linenos %}
def hello
  puts "hi"
end
{% endhighlight %}
```

### Raw (escape Liquid)

```liquid
{% raw %}
  {{ this is not parsed }}
{% endraw %}
```

Essential when writing Liquid code samples inside a Jekyll-rendered file.

---

## Common patterns

### Build a tag cloud

```liquid
<ul>
  {% for tag in site.tags %}
    {%- assign tag_url = tag[0] | slugify | prepend: "/tags/" | append: "/" -%}
    <li>
      <a href="{{ tag_url | relative_url }}">
        {{ tag[0] }} ({{ tag[1].size }})
      </a>
    </li>
  {% endfor %}
</ul>
```

`site.tags` is a hash; iterating gives `[name, posts_array]` pairs.

### Group posts by year

```liquid
{% assign by_year = site.posts | group_by_exp: "p", "p.date | date: '%Y'" %}
{% for year in by_year %}
  <h2>{{ year.name }}</h2>
  <ul>
    {% for post in year.items %}
      <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>
{% endfor %}
```

### Estimated reading time

```liquid
{% assign words = page.content | number_of_words %}
{% assign minutes = words | divided_by: 200 | plus: 1 %}
{{ minutes }} min read
```

### Related posts via shared tags

The trick: a post shares a tag with the current page iff the union of their tag arrays is *smaller* than their sum — i.e. `concat | uniq` collapsed at least one duplicate.

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

{% for p in related limit: 3 %}
  <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
{% endfor %}
```

(Jekyll has a built-in `site.related_posts` but it requires `--lsi` plus the `classifier-reborn` gem and is slow. For most sites the tag overlap above is enough.)

### Detect production

```liquid
{% if jekyll.environment == "production" %}
  <!-- analytics, comments, ads -->
{% endif %}
```

Set with `JEKYLL_ENV=production bundle exec jekyll build`.

---

## Whitespace control

Liquid leaves whitespace where the tags were. To trim:

```liquid
{%- if condition -%}
  no leading or trailing whitespace from this block
{%- endif -%}

{{- variable -}}
```

The `-` eats whitespace on that side. Important for compact HTML (sitemaps, feeds, JSON output).

---

## Gotchas

1. **`{% include %}` is slow.** On sites with 500+ posts, includes called inside loops dominate build time. Use `{% include_cached %}` where possible.

2. **Variables don't leak across includes.** `{% assign x = 1 %}` in a partial does not propagate up. Pass values as include parameters and read them via `include.NAME`.

3. **`for` doesn't break on `if false` inside.** Use `{% break %}` explicitly.

4. **`where` filter doesn't do nested access.** `{{ array | where: "meta.published", true }}` does not work. Use `where_exp`: `{{ array | where_exp: "i", "i.meta.published == true" }}`.

5. **`contains` works on arrays and strings, but the semantics differ.** On a string, it does substring match. On an array, it does element equality. There's no element substring matching.

6. **Date comparisons need conversion.** `{% if post.date > site.time %}` works because both are Time objects. But `{% if post.date > "2026-01-01" %}` is a Time-vs-String comparison and may misbehave. Use `| date: "%s"` to compare as Unix timestamps.

7. **`limit:0` returns the empty array, not an error.** Handy for conditional display.

8. **Comments**: `{% comment %}...{% endcomment %}` is the canonical form. Liquid 5.4+ also supports an inline form `{% # this is a comment %}`. There is **no** `{# … #}` syntax in Liquid (that belongs to Twig/Nunjucks/Jinja); using it will either render literally or trip strict mode.

9. **`site.posts` is reverse chronological by default.** Use `reversed` keyword to flip back to old-first.

10. **There's no `else` for `for`.** To handle "empty array" cases:
    ```liquid
    {% if site.posts.size == 0 %}
      No posts yet.
    {% else %}
      {% for post in site.posts %}...{% endfor %}
    {% endif %}
    ```

## Going further

- Shopify Liquid reference (the canonical source for built-in filters/tags): <https://shopify.github.io/liquid/>
- Jekyll's Liquid additions: <https://jekyllrb.com/docs/liquid/filters/>
- Jekyll variables reference: <https://jekyllrb.com/docs/variables/>
