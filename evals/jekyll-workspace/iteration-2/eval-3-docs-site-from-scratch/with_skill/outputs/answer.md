# Jekyll Docs Site — From Scratch on macOS

## Overview

This guide creates a 40-page documentation site using **Just the Docs** (the best theme for docs with sidebar nav, search, and light/dark mode), built with **Jekyll 4.4.x** via **GitHub Actions**, deployed to GitHub Pages, with **html-proofer** breaking the build on broken internal links.

---

## 1. Install Ruby 3.4 on macOS

Do **not** use system Ruby. Use `rbenv`:

```bash
brew install rbenv ruby-build
rbenv install 3.4.8
rbenv global 3.4.8
ruby -v                    # confirm 3.4.8
gem install bundler
```

Add to `~/.zshrc` (or `~/.bashrc`):

```bash
eval "$(rbenv init - zsh)"
```

Then restart your shell.

---

## 2. Scaffold the project

```bash
mkdir my-docs-site && cd my-docs-site
```

Create `.ruby-version` at the project root:

```
3.4.8
```

---

## 3. Gemfile

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

gem "just-the-docs", "~> 0.10.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-last-modified-at", "~> 1.3"
end

group :test do
  gem "html-proofer", "~> 5.0"
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
```

```bash
bundle install
```

Commit `Gemfile.lock`.

---

## 4. `_config.yml`

```yaml
title: "My Docs"
description: "Documentation site built with Just the Docs"
url: "https://your-username.github.io"
baseurl: ""                            # "/repo-name" for project sites

markdown: kramdown
highlighter: rouge
encoding: utf-8
timezone: America/New_York
permalink: /:categories/:slug/

theme: just-the-docs

liquid:
  error_mode: strict
  strict_filters: true
  strict_variables: false

exclude:
  - README.md
  - Gemfile
  - Gemfile.lock
  - vendor
  - .git
  - .github
  - scripts
  - .ruby-version

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-last-modified-at

# ─── Just the Docs specific ───

# Enable light/dark mode via OS preference
color_scheme: nil                      # nil = follow OS; "light" or "dark" to pin

# Search
search_enabled: true
search:
  heading_level: 3
  previews: 3
  preview_words_before: 5
  preview_words_after: 10
  tokenizer_separator: /[\s/]+/
  rel_url: true
  button: false

# Aux links (top nav)
aux_links:
  "Edit on GitHub":
    - "https://github.com/your-username/your-repo/edit/main/"

# Footer
footer_content: "Copyright &copy; $(date +%Y) Your Name. Distributed by an <a href=\"https://github.com/your-username/your-repo/tree/main/LICENSE\">MIT license.</a>"

# Navigation structure
nav_sort: case_insensitive
heading_anchors: true

# Back to top
back_to_top: true
back_to_top_text: "Back to top"

# Footer "Last edited"
last_edit_timestamp: true
last_edit_time_format: "%b %e %Y at %I:%M %p"

# Mermaid diagrams (optional)
mermaid:
  version: "11.4.1"

# Callouts (Just the Docs feature)
callouts:
  warning:
    title: Warning
    color: red
  note:
    title: Note
    color: blue
  tip:
    title: Tip
    color: green

# Collection (just-the-docs uses pages, but we enable docs collection)
collections:
  docs:
    output: true
    permalink: /:name/

defaults:
  - scope:
      path: ""
      type: "pages"
    values:
      layout: default
      nav_order: 999
  - scope:
      path: ""
      type: "docs"
    values:
      layout: default

# ─── Plugin config ───

feed:
  posts_limit: 20

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
```

---

## 5. Directory structure

```
my-docs-site/
├── .github/
│   └── workflows/
│       └── jekyll.yml
├── .ruby-version
├── Gemfile
├── Gemfile.lock
├── _config.yml
├── _data/
│   └── navigation.yml          # sidebar nav structure
├── _includes/
│   └── head_custom.html        # custom <head> additions
├── _layouts/
│   └── default.html            # optional override
├── assets/
│   ├── css/
│   │   └── custom.scss         # custom overrides
│   └── images/
├── index.md                    # homepage
├── getting-started.md
├── configuration.md
├── deployment.md
├── contributing.md
└── ... (37 more .md pages)
```

---

## 6. Sidebar navigation (`_data/navigation.yml`)

Just the Docs auto-generates a sidebar from page front matter using `nav_order` and `parent`/`nav_order` keys.

**Page-level front matter for sidebar hierarchy:**

```yaml
---
title: Getting Started
nav_order: 1
has_children: true
permalink: /getting-started/
---
```

**Child page:**

```yaml
---
title: Installation
parent: Getting Started
nav_order: 1
permalink: /getting-started/installation/
---
```

For a manual nav data file (alternative), create `_data/navigation.yml`:

```yaml
- title: Getting Started
  url: /getting-started/
  children:
    - title: Installation
      url: /getting-started/installation/
    - title: Quick Start
      url: /getting-started/quick-start/
- title: Configuration
  url: /configuration/
  children:
    - title: Settings
      url: /configuration/settings/
    - title: Plugins
      url: /configuration/plugins/
    - title: Themes
      url: /configuration/themes/
- title: Deployment
  url: /deployment/
  children:
    - title: GitHub Pages
      url: /deployment/github-pages/
    - title: Netlify
      url: /deployment/netlify/
- title: Contributing
  url: /contributing/
```

Just the Docs uses the `nav_order` / `parent` front matter approach by default. Add 40+ `.md` pages organized into sections like:

| Section | Pages |
|---------|-------|
| Getting Started | installation, quick-start, first-project, troubleshooting-setup |
| User Guide | navigation, search, code-blocks, images, tables, callouts, mermaid, math, footnotes, utilities |
| Configuration | site-config, collections, permalinks, defaults, data-files, sass, plugins-seo, plugins-analytics |
| Deploy | github-pages, github-actions, netlify, custom-domains, https-ssl, ci-cd |
| API Reference | endpoints, authentication, rate-limiting, errors, sdks |
| Contributing | how-to-contribute, code-of-conduct, style-guide, testing, pull-requests |
| About | release-notes, changelog, license, contact |

---

## 7. Light/dark mode

Just the Docs supports light/dark mode out of the box. Set in `_config.yml`:

```yaml
# nil = follow OS preference
# "light" = always light
# "dark" = always dark
color_scheme: nil
```

For a manual toggle button in the header, override `_includes/head_custom.html`:

```html
<link rel="stylesheet" href="{{ "/assets/css/custom.css" | relative_url }}">
<script>
  (function() {
    const t = document.querySelector('.js-toggle-dark-mode');
    if (t) {
      t.addEventListener('click', function() {
        document.documentElement.classList.toggle('dark-mode');
      });
    }
  })();
</script>
```

Or create `assets/css/custom.scss` for light/dark CSS variable overrides:

```scss
---
---
.light-mode, .dark-mode {
  // JTD handles most of this via its built-in color schemes
}
```

---

## 8. `index.md`

```markdown
---
layout: default
title: Home
nav_order: 1
permalink: /
---

# My Documentation

Welcome to the documentation site.

## Getting Started

- [Installation](getting-started/installation/)
- [Quick Start](getting-started/quick-start/)
- [Configuration](configuration/)

## Support

- [GitHub Issues](https://github.com/your-username/your-repo/issues)
- [Discussion Forum](https://github.com/your-username/your-repo/discussions)
```

---

## 9. GitHub Actions deployment workflow (`.github/workflows/jekyll.yml`)

This workflow builds the site with `JEKYLL_ENV=production`, runs **html-proofer** with `--disable-external` and `--check-html` (breaks the build on broken internal links), and deploys to GitHub Pages:

```yaml
name: Build, test, and deploy

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
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true

      - name: Build
        run: bundle exec jekyll build
        env:
          JEKYLL_ENV: production

      - name: HTML proofer
        run: |
          bundle exec htmlproofer ./_site \
            --disable-external \
            --check-html \
            --check-img-http \
            --check-opengraph \
            --enforce-https \
            --allow-hash-href \
            --ignore-status-codes "0,429,500,502,503" \
            --ignore-urls "/^http:\/\/localhost/"
        # ^ These flags enforce internal link integrity:
        #   --disable-external: skip external URLs (fast, no flakiness)
        #   --check-html: validate HTML structure
        #   --check-img-http: ensure images load
        #   --enforce-https: no mixed content
        # html-proofer exits non-zero on any broken internal link →
        # the build fails. This is intentional.

      - name: Markdown lint
        run: npx markdownlint-cli2 "**/*.md" "#_site" "#vendor" "#node_modules"
        continue-on-error: true

  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name != 'pull_request'
    needs: test
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
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

      - uses: actions/upload-pages-artifact@v3

      - id: deployment
        uses: actions/deploy-pages@v4
```

### How html-proofer breaks the build on broken internal links

`html-proofer` exits with a non-zero status code when it finds broken links. In GitHub Actions, any step that exits non-zero causes the job to fail. Key flags:

| Flag | Purpose |
|------|---------|
| `--disable-external` | Skip outbound links (fast, suitable for PR CI) |
| `--check-html` | Validate HTML structure |
| `--check-img-http` | Ensure `<img>` references exist |
| `--enforce-https` | Reject http:// links on pages served over https:// |
| `--allow-hash-href` | Allow `href="#"` (used by JS toggles) |
| `--ignore-status-codes "0,429,500,502,503"` | Skip flaky statuses |
| `--ignore-urls "/^http:\/\/localhost/"` | Skip localhost dev URLs |

If a page links to `/configuration/settings/` and that page doesn't exist, `html-proofer` will report:

```
- ./_site/getting-started/index.html
  *  linking to internal path /configuration/settings/ which does not exist
```

And the build fails.

---

## 10. Running locally

```bash
# Development
bundle exec jekyll serve --livereload

# Show everything (drafts, future posts)
bundle exec jekyll serve --drafts --future --unpublished

# Production build (simulates CI)
JEKYLL_ENV=production bundle exec jekyll build

# Run html-proofer locally
bundle exec jekyll build
bundle exec htmlproofer ./_site --disable-external --check-html
```

---

## 11. Setting up GitHub Pages

1. Push your repo to GitHub.
2. Go to **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. The workflow file `.github/workflows/jekyll.yml` will run on every push.
4. Your site will be live at `https://your-username.github.io/your-repo/`.
5. For a custom domain: create a `CNAME` file with your domain, set DNS, and configure in Settings → Pages.

---

## Complete file manifest

```
my-docs-site/
├── .github/
│   └── workflows/
│       └── jekyll.yml
├── .ruby-version
├── Gemfile
├── Gemfile.lock                  # after bundle install
├── _config.yml
├── _data/
│   └── navigation.yml
├── _includes/
│   └── head_custom.html
├── assets/
│   └── css/
│       └── custom.scss
├── index.md
├── getting-started/
│   ├── installation.md
│   ├── quick-start.md
│   ├── first-project.md
│   └── troubleshooting-setup.md
├── user-guide/
│   ├── navigation.md
│   ├── search.md
│   ├── code-blocks.md
│   ├── images.md
│   ├── tables.md
│   ├── callouts.md
│   ├── mermaid.md
│   ├── math.md
│   ├── footnotes.md
│   └── utilities.md
├── configuration/
│   ├── site-config.md
│   ├── collections.md
│   ├── permalinks.md
│   ├── defaults.md
│   ├── data-files.md
│   ├── sass.md
│   ├── plugins-seo.md
│   └── plugins-analytics.md
├── deploy/
│   ├── github-pages.md
│   ├── github-actions.md
│   ├── netlify.md
│   ├── custom-domains.md
│   ├── https-ssl.md
│   └── ci-cd.md
├── api-reference/
│   ├── endpoints.md
│   ├── authentication.md
│   ├── rate-limiting.md
│   ├── errors.md
│   └── sdks.md
├── contributing/
│   ├── how-to-contribute.md
│   ├── code-of-conduct.md
│   ├── style-guide.md
│   ├── testing.md
│   └── pull-requests.md
└── about/
    ├── release-notes.md
    ├── changelog.md
    ├── license.md
    └── contact.md
```

This gives you ~45 pages across 6 sections, sidebar navigation, light/dark mode, automated CI with broken-link detection, and free GitHub Pages hosting.
