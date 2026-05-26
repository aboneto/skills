# Jekyll Docs Site from Scratch — Complete Setup

## 1. Install Ruby 3.4 on macOS

```bash
brew install rbenv ruby-build
rbenv install 3.4.8
rbenv global 3.4.8
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
exec zsh
ruby -v          # must print 3.4.x
gem install bundler
```

## 2. Scaffold the site

```bash
mkdir my-docs && cd my-docs
git init
echo "3.4.8" > .ruby-version
```

## 3. `Gemfile`

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

# Theme — sidebar nav, search, light/dark toggle out of the box
gem "just-the-docs", "~> 0.10"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-include-cache", "~> 0.2"
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"

group :test do
  gem "html-proofer", "~> 5.0"
end

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
```

Run:

```bash
bundle install
```

Commit `Gemfile.lock`.

## 4. `_config.yml`

```yaml
title: "My Project Docs"
description: "Documentation for My Project."
url: "https://yourusername.github.io"
baseurl: "/repo-name"           # "" for user/org site at username.github.io

theme: just-the-docs

# ── Just the Docs config ──────────────────────────────────────
color_scheme: auto              # follows OS preference; users can toggle
search_enabled: true
search.heading_level: 3
nav_sort: case_insensitive

aux_links:
  "GitHub":
    - "https://github.com/yourusername/repo-name"

nav_footer_links:
  - title: "License"
    url: "/license/"

heading_anchors: true

# ── Build ─────────────────────────────────────────────────────
markdown: kramdown
highlighter: rouge
encoding: utf-8
permalink: pretty

kramdown:
  input: GFM
  hard_wrap: false
  auto_ids: true
  syntax_highlighter: rouge

liquid:
  error_mode: strict
  strict_filters: true
  strict_variables: false

# ── Plugins (must match Gemfile :jekyll_plugins group) ────────
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-include-cache

# ── Exclude ───────────────────────────────────────────────────
exclude:
  - README.md
  - LICENSE
  - Gemfile
  - Gemfile.lock
  - node_modules
  - vendor
  - .git
  - .github

# ── Front-matter defaults ─────────────────────────────────────
defaults:
  - scope:
      path: ""
      type: "pages"
    values:
      layout: default
      nav_order: 99
```

## 5. Sidebar navigation (Just the Docs uses front matter)

Just the Docs builds the sidebar from page front matter — no separate YAML file needed. Each page declares its position:

**`index.md`** (homepage):

```markdown
---
title: Home
layout: home
nav_order: 1
permalink: /
---
Welcome to the project documentation.
```

**`getting-started.md`** (top-level page):

```markdown
---
title: Getting Started
nav_order: 2
permalink: /getting-started/
---
# Getting Started
Installation and first steps.
```

**`guides/installation.md`** (nested child page):

```markdown
---
title: Installation
parent: Guides
nav_order: 1
permalink: /guides/installation/
---
# Installation
```

**`guides/index.md`** (parent page that groups children):

```markdown
---
title: Guides
has_children: true
nav_order: 3
permalink: /guides/
---
# Guides
Browse the guides below.
```

Repeat for ~40 pages. The `parent:` key nests pages under a `has_children: true` page. `nav_order:` controls sort position (lower = higher).

## 6. Light / Dark mode

With `color_scheme: auto` in `_config.yml`, Just the Docs:

- Respects the user's OS preference (`prefers-color-scheme`)
- Shows a toggle button in the header by default

No extra CSS or JS needed. If you want to **force** a scheme, set `color_scheme: dark` or `color_scheme: light`. To customize colors, create `_sass/custom/setup.scss` and override the scheme variables:

```scss
// _sass/custom/setup.scss
$link-color: #2563eb;
$body-background-color: #ffffff;
$body-text-color: #1a1a1a;
```

## 7. GitHub Actions deployment workflow

`.github/workflows/deploy.yml`:

```yaml
name: Build and deploy Jekyll site

on:
  push:
    branches: [main]
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

      - name: Check internal links
        run: |
          bundle exec htmlproofer ./_site \
            --disable-external \
            --check-html \
            --allow-hash-href \
            --ignore-urls "/^http:\/\/localhost/"

      - uses: actions/upload-pages-artifact@v3

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

### html-proofer flags explained

| Flag | Purpose |
|---|---|
| `--disable-external` | Skip outbound links (fast; run external checks on a schedule) |
| `--check-html` | Validate HTML structure |
| `--allow-hash-href` | Allow `href="#"` (used by JS triggers) |
| `--ignore-urls` | Skip localhost URLs |

The proofer runs **between** build and deploy. If it finds a broken internal link, the workflow fails and the broken site never deploys.

### Scheduled external-link check (optional, weekly)

`.github/workflows/link-check.yml`:

```yaml
name: External link check

on:
  schedule:
    - cron: "0 9 * * 1"
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true
      - run: JEKYLL_ENV=production bundle exec jekyll build
      - run: bundle exec htmlproofer ./_site --enforce-https
```

## 8. Enable GitHub Pages

1. Push all files to `main`.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. The workflow triggers automatically on push.

## 9. Local development

```bash
bundle exec jekyll serve --livereload
# http://localhost:4000/repo-name/
```

## 10. Final directory structure

```
my-docs/
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       └── link-check.yml
├── _data/                   # (optional) YAML data files
├── _sass/
│   └── custom/
│       └── setup.scss       # color overrides
├── guides/
│   ├── index.md             # has_children: true
│   ├── installation.md
│   └── configuration.md
├── index.md
├── getting-started.md
├── api/
│   ├── index.md
│   └── endpoint.md
├── .ruby-version
├── _config.yml
├── Gemfile
└── Gemfile.lock
```

## Quick-reference checklist

- [x] Ruby 3.4 via rbenv + `.ruby-version`
- [x] `Gemfile` with Jekyll 4.4, Just the Docs, standard plugins, html-proofer
- [x] `_config.yml` with `theme: just-the-docs`, `color_scheme: auto`, search enabled
- [x] Sidebar nav via front matter (`nav_order`, `parent`, `has_children`)
- [x] Light/dark toggle built into theme (auto-detects OS preference)
- [x] GitHub Actions workflow: build → html-proofer → deploy
- [x] html-proofer breaks build on broken internal links (`--disable-external`, `--check-html`)
- [x] Optional weekly external-link check workflow
