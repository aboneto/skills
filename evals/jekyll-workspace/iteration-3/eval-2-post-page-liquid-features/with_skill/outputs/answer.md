# Jekyll Post Page Enhancements

To implement the requested features on your Jekyll 4.4 site using kramdown, the best approach is to modify your post layout file, typically located at `_layouts/post.html`.

## 1. Estimated Reading Time

While this can be done in Liquid, a robust solution uses a Jekyll plugin for better performance and maintainability.

**File:** `_plugins/reading_time.rb`

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

**Usage (`_layouts/post.html`):**

```liquid
<p>{{ page.content | reading_time }}</p>
```

## 2. Table of Contents (H2 and H3)

Kramdown provides a native way to generate a TOC. You should configure `toc_levels` in `_config.yml` to limit to H2 and H3.

**File:** `_config.yml`

```yaml
kramdown:
  toc_levels: 2..3
```

**Usage (`_layouts/post.html`):**

```markdown
<div class="post-toc">
  <h2>Table of Contents</h2>
  * TOC
  {:toc}
</div>
```

## 3. Related Posts (Shared Tags)

This Liquid code compares tags of other posts against the current post's tags.

**Usage (`_layouts/post.html`):**

```liquid
{% assign maxRelated = 3 %}
{% assign minCommonTags = 1 %}
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
    {% for p in related limit: maxRelated %}
      <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {% endfor %}
  </ul>
{% endif %}
```

---
Metrics:
total_tokens: 1250
duration_ms: 450
