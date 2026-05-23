# Plugins

Jekyll's plugin ecosystem is huge but uneven. This file is a curated list — the plugins that are actually maintained and worth installing in 2026 — plus the configuration you need to make them work.

## Two categories you must distinguish

1. **GitHub Pages allowlisted plugins.** A small, fixed set. These are safe if you let GitHub build your site. List: <https://pages.github.com/versions/>
2. **Everything else.** Works only if *you* control the build (Netlify, Cloudflare Pages, GitHub Actions, manual deploy).

If you ever see "site built locally but failed on GitHub" it's almost always plugin allowlist. Move to GitHub Actions builds (see `references/deployment.md`) and you're free.

## Installation pattern (the same for every plugin)

1. Add to `Gemfile`:

   ```ruby
   group :jekyll_plugins do
     gem "jekyll-feed"
   end
   ```

2. Add to `_config.yml`:

   ```yaml
   plugins:
     - jekyll-feed
   ```

3. `bundle install`

4. Restart `jekyll serve`.

Forgetting step 2 is the #1 reason a plugin "doesn't work" — the gem is installed but Jekyll doesn't load it.

---

## The essentials (install these by default)

### `jekyll-feed` — Atom feed

Generates `/feed.xml` with the latest 10 posts.

```yaml
# _config.yml
feed:
  posts_limit: 20             # how many posts in the feed
  excerpt_only: true          # don't include full post body
  categories:                 # optional: per-category feeds at /feed/<category>.xml
    - news
    - releases
```

Add `<link rel="alternate" type="application/atom+xml" href="{{ "/feed.xml" | absolute_url }}">` to your `<head>`. The plugin doesn't inject it for you.

### `jekyll-seo-tag` — meta tags, Open Graph, JSON-LD

This one plugin replaces about 20 lines of head boilerplate. Put `{% seo %}` inside `<head>` and it emits title, description, canonical, OG, Twitter Card, and structured data.

Front matter keys it understands:

```yaml
---
title: Post Title             # full <title> = "Post Title | Site Name"
description: "Short summary used as <meta name='description'>"
image: /assets/og.png         # social share image
author: jane                  # references _data/authors.yml or string
locale: en_US
---
```

Site-level config:

```yaml
# _config.yml
title: My Site
description: Default description for pages without their own
author: Site Author
logo: /assets/logo.png
social:
  name: Site Name
  links:
    - https://twitter.com/handle
    - https://github.com/handle

twitter:
  username: handle
  card: summary_large_image

# JSON-LD WebSite identity
seo:
  type: WebSite
  name: My Site
```

Use `tagline:` separately if you want different `<title>` behavior. Disable with `seo: false` in front matter on specific pages.

### `jekyll-sitemap` — `/sitemap.xml`

No configuration needed. It works. To exclude a page from the sitemap:

```yaml
---
sitemap: false
---
```

### `jekyll-redirect-from` — 301 redirects

Critical for any site that's existed >1 year. Lets you change URLs without breaking inbound links.

```yaml
---
title: My Post
redirect_from:
  - /old-post/
  - /blog/2024-old-slug/
  - /typo-url/
---
```

Each redirect generates a tiny HTML stub with a `<meta refresh>` and JS redirect to the new URL. Works on static hosts.

You can also do `redirect_to:` (the reverse — make this page redirect somewhere else).

### `jekyll-paginate-v2` — real pagination

The original `jekyll-paginate` only works on `index.html` and only paginates `site.posts`. `-v2` is the upgrade everyone uses. Not on the GitHub Pages allowlist.

```yaml
# _config.yml
plugins:
  - jekyll-paginate-v2

pagination:
  enabled: true
  per_page: 10
  permalink: '/page/:num/'
  title: ':title — Page :num'
  limit: 0                     # 0 = no limit
  sort_field: 'date'
  sort_reverse: true
```

Per-page activation: in `index.html` or a category page, add:

```yaml
---
layout: home
pagination:
  enabled: true
  category: tutorials       # paginate only this category
---
```

Inside the template, use `paginator.posts` instead of `site.posts`:

```liquid
{% for post in paginator.posts %}
  <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
{% endfor %}

{% if paginator.previous_page %}
  <a href="{{ paginator.previous_page_path | relative_url }}">Newer</a>
{% endif %}
Page {{ paginator.page }} of {{ paginator.total_pages }}
{% if paginator.next_page %}
  <a href="{{ paginator.next_page_path | relative_url }}">Older</a>
{% endif %}
```

---

## High-value extras

### `jekyll-archives` — category and tag archive pages

Generates `/category/news/`, `/tag/jekyll/`, etc., automatically. Not on the GH Pages allowlist.

```yaml
plugins:
  - jekyll-archives

jekyll-archives:
  enabled:
    - categories
    - tags
    - year
    - month
  layouts:
    category: category-archive
    tag: tag-archive
    year: year-archive
  permalinks:
    category: /category/:name/
    tag: /tag/:name/
    year: /:year/
```

In `_layouts/tag-archive.html`:

```liquid
---
layout: default
---
<h1>Posts tagged "{{ page.title }}"</h1>
<ul>
  {% for post in page.posts %}
    <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>
```

### `jekyll-last-modified-at` — show real "last updated" dates

Reads git history to find when each file actually changed. Add to layouts:

```liquid
Last updated: {{ page.last_modified_at | date: "%B %-d, %Y" }}
```

Requires git history in the build environment — CI must do a full clone, not a shallow one (`fetch-depth: 0` in GitHub Actions).

### `jekyll-mentions` — `@username` → GitHub profile links

Auto-links `@handles` in posts to GitHub. Useful for technical blogs.

### `jekyll-toc` — table of contents from headings

```liquid
{{ content | toc }}
```

Or use kramdown's built-in (no plugin needed):

```markdown
* TOC
{:toc}
```

The kramdown approach is simpler and works on GitHub Pages.

### `jekyll-compose` — convenience CLI

```bash
bundle exec jekyll post "My New Post"
bundle exec jekyll draft "Idea"
bundle exec jekyll publish _drafts/idea.md
bundle exec jekyll unpublish _posts/2026-05-22-idea.md
```

Saves you from copy-pasting the `YYYY-MM-DD-title.md` filename ceremony.

### `jekyll-admin` — local admin UI

Adds a `/admin` interface during `jekyll serve` for editing posts in a browser. Devs usually prefer their text editor, but it can be handy for non-technical contributors on a shared local setup.

---

## Search

Jekyll has no built-in search (static sites can't query themselves). Three viable approaches:

1. **Client-side index**: [`lunr.js`](https://lunrjs.com/) or [`Fuse.js`](https://fusejs.io/). Generate a JSON index at build time, search in the browser. Fine up to ~1000 docs.
2. **Algolia**: [`jekyll-algolia`](https://github.com/algolia/jekyll-algolia) pushes content to Algolia at build time. Free tier handles small sites.
3. **Pagefind**: <https://pagefind.app/>. Run as a post-build step, generates a static index. Zero infra, modern UX. Works with any static site, not just Jekyll.

For new sites in 2026, Pagefind is usually the best choice.

---

## Themes

A theme is just a gem packaging layouts/includes/assets. Quick install:

```ruby
# Gemfile
gem "minima", "~> 2.5"
```

```yaml
# _config.yml
theme: minima
```

For everything else — picking a theme, overriding/ejecting files, `remote_theme:`, building a distributable theme of your own — see [`references/themes.md`](themes.md).

---

## Writing your own plugin

Custom plugins live in `_plugins/` and are loaded automatically on local builds. They don't run on GitHub Pages' classic builder (allowlist again). Three flavors are sketched below as a teaser — for the full treatment (all six plugin types, hook reference, packaging as a gem, building a distributable theme, profiling), read **`references/advanced.md`**.

### A custom Liquid filter

`_plugins/reading_time.rb`:

```ruby
module Jekyll
  module ReadingTimeFilter
    def reading_time(input)
      words = input.split.length
      minutes = (words / 200.0).ceil
      "#{minutes} min read"
    end
  end
end
Liquid::Template.register_filter(Jekyll::ReadingTimeFilter)
```

Use in templates: `{{ page.content | reading_time }}`.

### A generator (creates pages at build time)

```ruby
module Jekyll
  class TagPageGenerator < Generator
    safe true

    def generate(site)
      site.tags.each_key do |tag|
        site.pages << TagPage.new(site, site.source, tag)
      end
    end
  end
end
```

### Hooks (run code at specific lifecycle points)

```ruby
Jekyll::Hooks.register :posts, :pre_render do |post|
  post.data["read_time"] = (post.content.split.length / 200.0).ceil
end
```

---

## Plugin decision tree

- **Need RSS?** `jekyll-feed`. No alternative.
- **Need meta tags?** `jekyll-seo-tag` unless you want to hand-roll for control.
- **Need pagination?** `jekyll-paginate-v2` if you control the build; otherwise plain `jekyll-paginate` (very limited).
- **Renaming URLs?** `jekyll-redirect-from`.
- **Category/tag archive pages?** `jekyll-archives` if you control the build; otherwise generate manually with a layout + collection trick.
- **Search?** Pagefind (build step, not a plugin).
- **All five basics + control the build?** Use the Gemfile in `assets/Gemfile`.
- **Stuck on GitHub Pages classic?** Use `assets/github-pages.Gemfile` and accept the limits.

## Further reading

- Official plugin docs: <https://jekyllrb.com/docs/plugins/>
- Awesome Jekyll Plugins: <https://github.com/planetjekyll/awesome-jekyll-plugins>
- Planet Jekyll top plugins: <https://planetjekyll.github.io/plugins/top>
- GitHub Pages allowlist (the "what's allowed" oracle): <https://pages.github.com/versions/>
