# Jekyll Docs Site Setup — Iteration 1

## Overview

**Recommended theme**: [Just the Docs](https://just-the-docs.com/) — built-in sidebar nav, native light/dark mode, search, actively maintained. Perfect for ~40-page documentation sites.

**Deploy target**: GitHub Pages via GitHub Actions (builds unlocked from classic allowlist).

---

## Step 1 — Ruby Setup (macOS)

```bash
brew install rbenv ruby-build
rbenv install 3.4.8
rbenv global 3.4.8
ruby -v        # → ruby 3.4.8
gem install bundler
```

Add to shell rc (zsh): `eval "$(rbenv init - zsh)"`

---

## Step 2 — Gemfile

**File**: `Gemfile`

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"
gem "just-the-docs", "~> 0.10"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-paginate-v2",   "~> 3.0"
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"
gem "jekyll-include-cache", "~> 0.2"

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
```

**File**: `.ruby-version`

```
3.4.8
```

---

## Step 3 — _config.yml

**File**: `_config.yml`

```yaml
title: "My Docs Site"
description: "Documentation for My Project"
url: "https://yourusername.github.io"
baseurl: "/my-docs-site"

theme: just-the-docs

markdown: kramdown
highlighter: rouge
encoding: utf-8
timezone: UTC

permalink: /:year/:month/:day/:title/

liquid:
  error_mode: strict
  strict_filters: true
  strict_variables: false

include:
  - _redirects
  - _headers

exclude:
  - README.md
  - LICENSE
  - Gemfile
  - Gemfile.lock
  - node_modules
  - vendor
  - .git
  - .github
  - .vscode
  - scripts

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-paginate-v2
  - jekyll-include-cache

jekyll-redirect-from:
  quiet: true

kramdown:
  input: GFM
  hard_wrap: false
  auto_ids: true
  syntax_highlighter: rouge
  syntax_highlighter_opts:
    block:
      line_numbers: false

sass:
  style: compressed
  sass_dir: _sass

defaults:
  - scope:
      path: "_docs"
    values:
      layout: doc
      searchable: true
  - scope:
      path: ""
    values:
      layout: default

footer_content: "Copyright &copy; 2026 Your Name"

color_scheme: light

search_enabled: true
search_tokenizer_separator: /[\\/]+/
search_heading_level: 2
search_min_length: 2
search_lang: en

nav_external_links:
  - title: GitHub
    url: https://github.com/yourusername/yourrepo

callouts_level: quiet
callouts: true

# ─── Collections ───
collections:
  docs:
    output: true
    permalink: /docs/:path/
    sort_by: order

docs_collection:
  name: Documentation
  folder: _docs
  singleton: false

# ─── Front-matter defaults for docs ───
defaults:
  - scope:
      path: "_docs"
    values:
      layout: doc
      order: 999
  - scope:
      path: ""
    values:
      layout: default
```

---

## Step 4 — Create Docs Collection Structure

```bash
mkdir -p _docs _layouts _includes _sass assets/css
```

**File**: `_docs/.gitkeep` (or add your first doc)

**File**: `_docs/getting-started.md`

```markdown
---
title: Getting Started
order: 1
---

# Getting Started

Welcome to the documentation site.

## Installation

...
```

---

## Step 5 — Custom Sidebar (Optional Override)

**File**: `_includes/sidebar.html`

```liquid
{%- if page.url contains '/docs/' -%}
<nav class="sidebar-nav">
  {% assign docs = site.docs | sort: "order" %}
  {% for doc in docs %}
    <a href="{{ doc.url | relative_url }}" {% if page.url == doc.url %}class="active"{% endif %}>
      {{ doc.title }}
    </a>
  {% endfor %}
</nav>
{%- endif -%}
```

---

## Step 6 — Light/Dark Mode

Just the Docs supports `theme_mode` out of the box:

```yaml
# In _config.yml — uncomment one:
# theme_mode: light    # force light
# theme_mode: dark     # force dark
theme_mode: auto       # follows OS (default)
```

Or set per-user via a toggle by overriding `_includes/head_custom.html`:

```liquid
<script>
  const theme = localStorage.getItem('jd-theme');
  document.documentElement.setAttribute('data-theme', theme || 'auto');
</script>
```

---

## Step 7 — GitHub Actions Deployment + html-proofer

**File**: `.github/workflows/jekyll.yml`

```yaml
name: Build and deploy Jekyll site

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true

      - id: pages
        uses: actions/configure-pages@v5

      - name: Build
        run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production

      - name: HTML proofer (internal links)
        run: bundle exec htmlproofer ./_site --disable-external --check-html --allow-hash-href

      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

### Why `--disable-external` on the proofer step

- PRs and pushes should not be blocked by third-party sites going down.
- External link rot is checked weekly via a scheduled workflow (see below).

**File**: `.github/workflows/link-check.yml`

```yaml
name: Weekly external link check

on:
  schedule:
    - cron: "0 9 * * 1"   # 09:00 UTC every Monday
  workflow_dispatch:

jobs:
  link-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true

      - run: bundle exec jekyll build
        env:
          JEKYLL_ENV: production

      - run: bundle exec htmlproofer ./_site --enforce-https
```

---

## Step 8 — GitHub Pages Settings

1. Go to **Settings → Pages → Build and deployment → Source**: select **GitHub Actions**.
2. Push to `main`. The workflow runs automatically.

---

## Step 9 — Local Dev

```bash
bundle install
bundle exec jekyll serve                    # http://localhost:4000
bundle exec jekyll serve --livereload       # with browser auto-refresh
bundle exec jekyll build                    # one-shot build to _site/
```

---

## Quick Reference

| Task | Command |
|---|---|
| Create new doc page | Add `_docs/filename.md` with front matter |
| Add to sidebar sort | Set `order: N` in front matter |
| Switch dark mode | Set `theme_mode: dark` in `_config.yml` |
| Check for broken links locally | `bundle exec jekyll build && bundle exec htmlproofer ./_site --disable-external` |
| Rebuild from clean | `bundle exec jekyll clean && bundle exec jekyll build` |

---

## File Structure Summary

```
my-site/
├── .github/
│   └── workflows/
│       ├── jekyll.yml         # build + deploy + html-proofer
│       └── link-check.yml     # weekly external link check
├── .ruby-version
├── Gemfile
├── Gemfile.lock
├── _config.yml
├── _docs/                     # ~40 doc pages go here
│   ├── getting-started.md
│   └── ...
├── _layouts/
├── _includes/
├── _sass/
├── assets/
│   └── css/
└── index.md
```