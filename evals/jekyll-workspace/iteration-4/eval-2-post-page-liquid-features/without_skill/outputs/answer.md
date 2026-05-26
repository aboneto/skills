# Jekyll Post Features: Reading Time, TOC, and Related Posts

## Directory Structure

```
your-jekyll-site/
├── _plugins/
│   └── reading_time.rb          # Reading time filter
├── _includes/
│   ├── reading-time.html        # Reading time display
│   ├── toc.html                 # Table of contents
│   └── related-posts.html       # Related posts
├── _layouts/
│   └── post.html                # Post layout (modify existing)
├── _posts/
│   └── *.md                     # Your posts
└── _config.yml                  # Optional TOC settings
```

## 1. Estimated Reading Time

### `_plugins/reading_time.rb`

```ruby
module Jekyll
  module ReadingTimeFilter
    def reading_time(input, words_per_minute = 200)
      words = input.split.size
      minutes = (words.to_f / words_per_minute).ceil
      "#{minutes} min read"
    end
  end
end

Liquid::Template.register_filter(Jekyll::ReadingTimeFilter)
```

### `_includes/reading-time.html`

```html
<span class="reading-time">
  {{ content | reading_time }}
</span>
```

## 2. Table of Contents (H2/H3)

### `_includes/toc.html`

```html
{% assign headings = content | split: '<h' %}

{% if headings.size > 1 %}
<nav class="table-of-contents">
  <h2>Table of Contents</h2>
  <ul>
    {% for heading in headings %}
      {% if heading contains '</h2>' or heading contains '</h3>' %}
        {% assign level = heading | slice: 0, 1 %}
        {% assign id_part = heading | split: 'id="' %}
        {% if id_part.size > 1 %}
          {% assign id = id_part[1] | split: '"' | first %}
          {% assign title_part = heading | split: '>' %}
          {% assign title = title_part[1] | split: '</' | first | strip_html %}
          
          {% if level == '2' %}
            <li class="toc-h2">
              <a href="#{{ id }}">{{ title }}</a>
            </li>
          {% elsif level == '3' %}
            <li class="toc-h3">
              <a href="#{{ id }}">{{ title }}</a>
            </li>
          {% endif %}
        {% endif %}
      {% endif %}
    {% endfor %}
  </ul>
</nav>
{% endif %}
```

### Important kramdown config in `_config.yml`

```yaml
kramdown:
  input: GFM
  auto_ids: true
  toc_levels: "2,3"
```

This ensures kramdown generates `id` attributes for H2 and H3 headings automatically.

## 3. Related Posts by Tag

### `_includes/related-posts.html`

```html
{% if page.tags.size > 0 %}
  {% assign related_posts = "" | split: "" %}
  {% assign current_tags = page.tags %}
  
  {% for post in site.posts %}
    {% unless post.url == page.url %}
      {% assign has_common_tag = false %}
      
      {% for tag in current_tags %}
        {% if post.tags contains tag %}
          {% assign has_common_tag = true %}
          {% break %}
        {% endif %}
      {% endfor %}
      
      {% if has_common_tag %}
        {% assign related_posts = related_posts | push: post %}
      {% endif %}
    {% endunless %}
    
    {% if related_posts.size >= 5 %}
      {% break %}
    {% endif %}
  {% endfor %}
  
  {% if related_posts.size > 0 %}
  <aside class="related-posts">
    <h2>Related Posts</h2>
    <ul>
      {% for post in related_posts %}
      <li>
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        <span class="post-date">{{ post.date | date: "%B %d, %Y" }}</span>
        <span class="post-tags">
          {% for tag in post.tags %}
            {% if current_tags contains tag %}
              <mark>{{ tag }}</mark>{% unless forloop.last %}, {% endunless %}
            {% else %}
              {{ tag }}{% unless forloop.last %}, {% endunless %}
            {% endif %}
          {% endfor %}
        </span>
      </li>
      {% endfor %}
    </ul>
  </aside>
  {% endif %}
{% endif %}
```

## 4. Modified Post Layout

### `_layouts/post.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>{{ page.title }}</title>
  <style>
    .post-meta { color: #666; margin-bottom: 1rem; }
    .reading-time { font-style: italic; }
    .table-of-contents { 
      background: #f9f9f9; 
      padding: 1rem; 
      border-radius: 4px; 
      margin: 1rem 0; 
    }
    .table-of-contents ul { list-style: none; padding-left: 0; }
    .toc-h3 { padding-left: 1.5rem; }
    .related-posts { margin-top: 2rem; border-top: 1px solid #ddd; padding-top: 1rem; }
    .related-posts mark { background: #ffeb3b; }
  </style>
</head>
<body>
  <article>
    <header>
      <h1>{{ page.title }}</h1>
      <div class="post-meta">
        <time>{{ page.date | date: "%B %d, %Y" }}</time>
        {% include reading-time.html %}
      </div>
    </header>

    {% include toc.html %}

    <div class="post-content">
      {{ content }}
    </div>

    {% include related-posts.html %}
  </article>
</body>
</html>
```

## 5. Post Front Matter Example

```yaml
---
title: "My Awesome Post"
date: 2024-01-15
layout: post
tags: [jekyll, tutorial, web development]
---
```

## Summary

| Feature | Files |
|---------|-------|
| Reading Time | `_plugins/reading_time.rb` + `_includes/reading-time.html` |
| Table of Contents | `_includes/toc.html` + `_config.yml` (kramdown settings) |
| Related Posts | `_includes/related-posts.html` |
| Layout | `_layouts/post.html` (integrate all includes) |

The reading time uses a custom Liquid filter that counts words and divides by 200 wpm. The TOC parses the rendered HTML for `<h2>` and `<h3>` tags with `id` attributes (provided by kramdown's `auto_ids: true`). Related posts loop through all posts checking for common tags, limited to 5 results.
