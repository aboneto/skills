# Configuration Reference

Everything that lives in `_config.yml`, plus collections, data files, and permalink design. This is the layer where Jekyll sites become real projects rather than blog templates.

## Table of contents

1. [`_config.yml` — every key worth knowing](#_configyml--every-key-worth-knowing)
2. [Permalinks](#permalinks)
3. [Defaults (kill front matter repetition)](#defaults-kill-front-matter-repetition)
4. [Collections](#collections)
5. [Data files](#data-files)
6. [Includes vs layouts vs collections — when to use which](#includes-vs-layouts-vs-collections--when-to-use-which)

---

## `_config.yml` — every key worth knowing

```yaml
# ───── Site identity ─────
title: "My Site"
description: "Short description, used by jekyll-seo-tag"
url: "https://example.com"      # production URL, no trailing slash
baseurl: ""                     # "" if at root, "/blog" if at example.com/blog
author:
  name: "Jane Doe"
  email: "jane@example.com"

# ───── Build behavior ─────
markdown: kramdown              # default; alternatives: CommonMark
highlighter: rouge              # syntax highlighter
encoding: utf-8
permalink: /:year/:month/:day/:title/
timezone: Europe/Madrid         # affects date parsing

# ───── What to include/exclude ─────
include:
  - .htaccess
  - _redirects
exclude:
  - README.md
  - Gemfile
  - Gemfile.lock
  - node_modules
  - vendor
  - .git
  - .github

# ───── Plugins ─────
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-paginate-v2

# ───── Pagination (jekyll-paginate-v2) ─────
pagination:
  enabled: true
  per_page: 10
  permalink: '/page/:num/'
  title: ':title — Page :num'
  sort_field: 'date'
  sort_reverse: true

# ───── Collections ─────
collections:
  projects:
    output: true                # generate a page per item
    permalink: /projects/:path/
  docs:
    output: true
    permalink: /docs/:path/

# ───── Front-matter defaults ─────
defaults:
  - scope: { path: "", type: "posts" }
    values:
      layout: post
      comments: true
  - scope: { path: "", type: "projects" }
    values:
      layout: project
  - scope: { path: "" }         # everything else
    values:
      layout: default

# ───── Sass ─────
sass:
  style: compressed             # or "expanded" for dev
  sass_dir: _sass

# ───── Development conveniences (CLI flags also work) ─────
show_drafts: false
future: false
unpublished: false

# ───── Plugin-specific config (examples) ─────
feed:
  posts_limit: 20
  excerpt_only: true

webrick:
  headers:
    Cache-Control: "no-store, no-cache, must-revalidate"

# Liquid strict mode catches typos like {{ pag.title }} instead of {{ page.title }}
liquid:
  error_mode: strict
  strict_filters: true
  strict_variables: false       # true is nice but breaks many themes
```

Remember: **`_config.yml` changes are not picked up by `jekyll serve --watch`.** Restart the server. This catches almost everyone the first time.

## Permalinks

The `permalink` key in `_config.yml` controls URL shapes for posts. Default is `date` (`/:categories/:year/:month/:day/:title:output_ext`).

Built-in presets:

```yaml
permalink: date     # /news/2026/05/22/my-post.html
permalink: pretty   # /news/2026/05/22/my-post/
permalink: ordinal  # /news/2026/142/my-post/
permalink: none     # /news/my-post.html
```

Custom templates use these placeholders:

| Placeholder | Example value |
|---|---|
| `:year`, `:month`, `:day` | `2026`, `05`, `22` |
| `:i_day`, `:i_month` | day/month without leading zero |
| `:title` | slug from filename or `slug:` in front matter |
| `:slug` | alias for `:title` |
| `:categories` | slash-joined categories |
| `:path` | full source path (useful for collections) |
| `:name` | filename without extension |
| `:output_ext` | usually `.html` |

Examples:

```yaml
permalink: /:year/:month/:slug/      # /2026/05/my-post/
permalink: /blog/:slug/              # /blog/my-post/  (drop dates from URLs)
permalink: /:categories/:slug/       # /tutorials/jekyll/my-post/
```

You can override on a per-post basis in front matter:

```yaml
---
title: Special Post
permalink: /special/
---
```

**Trailing slashes matter for SEO.** Jekyll's pretty URLs end in `/` and serve from `index.html` inside a folder. If you mix `/about/` and `/about.html`, you create duplicates. Pick one and use redirects for the other.

## Defaults (kill front matter repetition)

Stop pasting `layout: post` in every file. Set defaults by `scope`:

```yaml
defaults:
  - scope:
      path: ""               # empty = whole site
      type: "posts"          # only posts (or "pages", or a collection name)
    values:
      layout: post
      author: "Site Author"
      comments: true

  - scope:
      path: "_projects"      # scoped to a folder
    values:
      layout: project
      sitemap: false

  - scope:
      path: ""
      type: "pages"
    values:
      layout: page
```

Front matter on individual files overrides defaults. Defaults are processed top to bottom — later entries win on conflict.

This is one of the highest-leverage features in Jekyll. A site with no defaults is a site with copy-paste bugs.

## Collections

Posts are the built-in collection. Anything else (docs, projects, team members, recipes) should be a custom collection. They give you:

- A folder Jekyll knows about (`_projects/`, `_docs/`, etc.)
- Rendered pages with their own layout
- An iterable array (`site.projects`)
- Per-collection permalinks and defaults

Declaration in `_config.yml`:

```yaml
collections:
  projects:
    output: true                  # render each item as its own page
    permalink: /projects/:path/
    sort_by: order                # sort by a front matter key
```

Then create `_projects/dashboard.md`:

```markdown
---
title: Dashboard
order: 1
client: Acme
status: shipped
---

Project description in markdown.
```

Iterate them anywhere:

```liquid
{% assign projects = site.projects | sort: "order" %}
{% for proj in projects %}
  <article>
    <h2><a href="{{ proj.url | relative_url }}">{{ proj.title }}</a></h2>
    <p>Client: {{ proj.client }} · Status: {{ proj.status }}</p>
  </article>
{% endfor %}
```

**Collection vs page**: Use a collection when you have N items of the same shape. Use pages for one-off things. Don't put 50 product pages in your root — make a `_products/` collection.

**Collection vs data file**: Use a collection when each item should have its own URL and Markdown body. Use a data file when the items are just structured data (team members in a sidebar, navigation menu).

## Data files

Drop YAML, JSON, CSV, or TSV in `_data/` and Jekyll exposes it as `site.data.FILENAME`.

`_data/navigation.yml`:

```yaml
- title: Home
  url: /
- title: Blog
  url: /blog/
- title: About
  url: /about/
```

Read it:

```liquid
<nav>
  {% for item in site.data.navigation %}
    <a href="{{ item.url | relative_url }}">{{ item.title }}</a>
  {% endfor %}
</nav>
```

Subdirectories nest as objects: `_data/authors/jane.yml` → `site.data.authors.jane`.

Useful patterns:

- **Author profiles**: `_data/authors.yml` keyed by username; reference by `{{ site.data.authors[page.author] }}`.
- **Site copy / strings table**: `_data/strings.yml` for translatable UI labels.
- **Menus and footers**: Editable navigation without HTML changes.
- **Tabular content**: A CSV of conference talks, rendered as a table.

## Includes vs layouts vs collections — when to use which

| Use this | When |
|---|---|
| **Layout** (`_layouts/x.html`) | Wraps a whole page. There's typically one layout per page type (post, project, default). |
| **Include** (`_includes/x.html`) | A reusable component called from a layout or page (`{% include header.html %}`). Lives inside the wrapper. |
| **Collection** (`_things/x.md`) | A repeated content type that should produce its own URL and have Markdown body. |
| **Data file** (`_data/x.yml`) | Structured data with no body and no individual URL. Pure information. |

Common mistake: building a sidebar by listing every page manually in an include. Use a collection or data file and iterate.

---

## A note on `_config.yml` inheritance

You can have multiple config files merged with `--config`:

```bash
bundle exec jekyll serve --config _config.yml,_config.dev.yml
```

The later file overrides the earlier. Typical use:

- `_config.yml` — production defaults
- `_config.dev.yml` — overrides `url`, disables analytics

Then in CI: `JEKYLL_ENV=production bundle exec jekyll build`. Locally: `bundle exec jekyll serve --config _config.yml,_config.dev.yml`.
