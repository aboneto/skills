# Jekyll Post Features

## 1. Estimated Reading Time
File: `_layouts/post.html`
Code:
```liquid
{% assign word_count = content | number_of_words %}
{% assign minutes = word_count | divided_by: 200 %}
{% if minutes == 0 %} {% assign minutes = 1 %} {% endif %}
<p>Reading time: {{ minutes }} min</p>
```

## 2. Table of Contents
File: `_posts/*.md` (or `_layouts/post.html`)
Code:
```markdown
* {:toc}
```
Ensure `kramdown` is used in `_config.yml`.

## 3. Related Posts (by tag)
File: `_layouts/post.html`
Code:
```liquid
<h3>Related Posts</h3>
<ul>
{% for post in site.posts %}
  {% if post.url != page.url %}
    {% assign shared_tags = false %}
    {% for tag in page.tags %}
      {% if post.tags contains tag %}
        {% assign shared_tags = true %}
      {% endif %}
    {% endfor %}
    {% if shared_tags %}
      <li><a href="{{ post.url }}">{{ post.title }}</a></li>
    {% endif %}
  {% endif %}
{% endfor %}
</ul>
```
