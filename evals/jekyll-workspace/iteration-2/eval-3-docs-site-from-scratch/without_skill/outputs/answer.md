# Setting Up a Jekyll Docs Site from Scratch on macOS

Below is a complete, production-ready setup for a ~40-page Jekyll documentation site deployed via GitHub Actions to GitHub Pages, with sidebar navigation, light/dark mode, and `html-proofer` enforcement.

---

## 1. Prerequisites (macOS, Ruby 3.4)

```bash
# Install Ruby 3.4 (if not already installed)
brew install ruby@3.4

# Verify
ruby -v
# => ruby 3.4.x

# Install Bundler and Jekyll
gem install bundler jekyll
```

---

## 2. Project Scaffold

```bash
mkdir my-docs-site
cd my-docs-site
jekyll new . --skip-git --force
```

Remove the default post (`_posts`) directory — we'll use `_docs` for pages instead.

---

## 3. Directory Structure

```
my-docs-site/
├── _config.yml
├── Gemfile
├── Gemfile.lock
├── .ruby-version
├── index.md
├── _docs/
│   ├── getting-started.md
│   ├── installation.md
│   ├── configuration.md
│   ├── deployment.md
│   └── ... (~40 total)
├── _layouts/
│   ├── default.html
│   └── docs.html
├── _includes/
│   ├── sidebar.html
│   ├── header.html
│   ├── head.html
│   └── footer.html
├── assets/
│   ├── css/
│   │   ├── main.scss
│   │   └── syntax.scss
│   └── js/
│       └── theme-toggle.js
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## 4. `Gemfile`

```ruby
source "https://rubygems.org"

ruby "~> 3.4"

gem "jekyll", "~> 4.3"
gem "jekyll-seo-tag"
gem "jekyll-feed"
gem "jekyll-sitemap"

# Windows/CI-specific
gem "wdm", "~> 0.2" if Gem.win_platform?
gem "webrick"

group :jekyll_plugins do
  # Add any Jekyll plugins here
end

group :test do
  gem "html-proofer", "~> 5.0"
end
```

Run `bundle install`.

---

## 5. `_config.yml`

```yaml
title: My Documentation Site
description: >-
  A comprehensive documentation site built with Jekyll.
baseurl: ""  # "/repo-name" for project pages
url: "https://your-username.github.io"

# Build settings
markdown: kramdown
highlighter: rouge
permalink: pretty

# Collections
collections:
  docs:
    output: true
    sort_by: order

# Defaults
defaults:
  - scope:
      path: ""
      type: "docs"
    values:
      layout: docs
      sidebar: true
  - scope:
      path: ""
    values:
      layout: default

# Plugins
plugins:
  - jekyll-seo-tag
  - jekyll-feed
  - jekyll-sitemap

# Exclude from processing
exclude:
  - Gemfile
  - Gemfile.lock
  - node_modules
  - vendor
  - spec
  - Rakefile
  - README.md
  - .ruby-version
  - .github
```

---

## 6. Document Pages (`_docs/`)

Each file in `_docs/` uses front matter with an `order` field for sidebar sorting:

**`_docs/getting-started.md`**

```markdown
---
layout: docs
title: Getting Started
order: 1
---

# Getting Started

Welcome to the docs. This page appears first in the sidebar.
```

Create ~40 files with sequential `order` values (1–40). A quick script:

```bash
for i in $(seq 2 40); do
  cat > "_docs/page-$(printf '%02d' $i).md" <<EOF
---
layout: docs
title: "Page $i"
order: $i
---

# Page $i

Content for page $i.
EOF
done
```

---

## 7. Layouts

### `_layouts/default.html`

```html
<!DOCTYPE html>
<html lang="en" data-theme="{{ site.theme | default: 'light' }}">
{% include head.html %}
<body>
  {% include header.html %}
  <main class="main-content">
    {{ content }}
  </main>
  {% include footer.html %}
  <script src="{{ '/assets/js/theme-toggle.js' | relative_url }}"></script>
</body>
</html>
```

### `_layouts/docs.html`

```html
---
layout: default
---

<div class="docs-layout">
  {% if page.sidebar %}
    {% include sidebar.html %}
  {% endif %}
  <article class="doc-content">
    {{ content }}
  </article>
</div>
```

---

## 8. Includes

### `_includes/head.html`

```html
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}</title>
<link rel="stylesheet" href="{{ '/assets/css/main.scss' | relative_url }}">
{% feed_meta %}
{% seo %}
```

### `_includes/header.html`

```html
<header class="site-header">
  <a href="{{ '/' | relative_url }}" class="site-title">{{ site.title }}</a>
  <button id="theme-toggle" aria-label="Toggle theme">🌙</button>
</header>
```

### `_includes/sidebar.html`

```html
<nav class="sidebar">
  <ul>
    {% assign docs = site.docs | sort: 'order' %}
    {% for doc in docs %}
      <li>
        <a href="{{ doc.url | relative_url }}"
           class="{% if doc.url == page.url %}active{% endif %}">
          {{ doc.title }}
        </a>
      </li>
    {% endfor %}
  </ul>
</nav>
```

### `_includes/footer.html`

```html
<footer class="site-footer">
  <p>&copy; {{ site.time | date: '%Y' }} {{ site.title }}</p>
</footer>
```

---

## 9. Assets

### `assets/css/main.scss`

```scss
---
---

:root {
  --bg: #ffffff;
  --text: #1a1a2e;
  --sidebar-bg: #f4f4f8;
  --link: #4361ee;
  --border: #e0e0e0;
}

[data-theme="dark"] {
  --bg: #1a1a2e;
  --text: #e0e0e0;
  --sidebar-bg: #16213e;
  --link: #7b9cff;
  --border: #2a2a4a;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  background: var(--bg);
  color: var(--text);
  transition: background 0.3s, color 0.3s;
}

.site-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 2rem;
  border-bottom: 1px solid var(--border);
}

.site-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--text);
  text-decoration: none;
}

#theme-toggle {
  background: none;
  border: 1px solid var(--border);
  border-radius: 6px;
  padding: 0.4rem 0.8rem;
  cursor: pointer;
  font-size: 1.2rem;
}

.docs-layout {
  display: flex;
  max-width: 1200px;
  margin: 0 auto;
}

.sidebar {
  width: 260px;
  min-width: 260px;
  padding: 1.5rem;
  background: var(--sidebar-bg);
  border-right: 1px solid var(--border);
  min-height: calc(100vh - 60px);
}

.sidebar ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.sidebar li {
  margin-bottom: 0.4rem;
}

.sidebar a {
  display: block;
  padding: 0.4rem 0.8rem;
  color: var(--text);
  text-decoration: none;
  border-radius: 4px;
}

.sidebar a:hover,
.sidebar a.active {
  background: var(--link);
  color: #ffffff;
}

.doc-content {
  flex: 1;
  padding: 2rem;
  max-width: 800px;
}

.site-footer {
  text-align: center;
  padding: 1rem;
  border-top: 1px solid var(--border);
  font-size: 0.875rem;
}
```

### `assets/js/theme-toggle.js`

```javascript
(function () {
  const STORAGE_KEY = 'jekyll-docs-theme';

  function getTheme() {
    return localStorage.getItem(STORAGE_KEY) || 'light';
  }

  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem(STORAGE_KEY, theme);
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = theme === 'dark' ? '☀️' : '🌙';
  }

  function toggle() {
    const current = getTheme();
    setTheme(current === 'dark' ? 'light' : 'dark');
  }

  document.addEventListener('DOMContentLoaded', function () {
    setTheme(getTheme());
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.addEventListener('click', toggle);
  });
})();
```

---

## 10. GitHub Actions Deployment Workflow

### `.github/workflows/deploy.yml`

```yaml
name: Build and Deploy

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
          bundler-cache: true

      - name: Setup Pages
        id: pages
        uses: actions/configure-pages@v5

      - name: Build with Jekyll
        run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production

      - name: Run html-proofer (blocking on broken internal links)
        run: |
          bundle exec htmlproofer ./_site \
            --check-html \
            --check-internal-hash \
            --check-img-http \
            --enforce-https \
            --empty-alt-ignore \
            --only-4xx \
            --url-ignore "/^http:\/\/localhost/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'

  deploy:
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    needs: build
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 11. html-proofer Details

The proofer runs *inside* the build step as part of CI:

- **`--check-html`** — validates HTML structure.
- **`--check-internal-hash`** — checks anchor links (`#section`) resolve within pages.
- **`--check-img-http`** — flags images served over plain HTTP.
- **`--enforce-https`** — ensures all external URLs use HTTPS.
- **`--empty-alt-ignore`** — skips empty `alt` attributes.
- **`--only-4xx`** — only fail on 4xx status codes (broken internal links, missing pages).
- **`--url-ignore`** — ignores `http://localhost` (used in local dev).

**How it breaks the build**: `html-proofer` exits with a non-zero status code when it finds broken links. Since it runs as a regular `run:` step in the GitHub Actions workflow (not under `continue-on-error`), a non-zero exit will cause the job to fail and the deployment to abort.

The `deploy` job requires the `build` job (which runs the proofer) via `needs: build`. If the build job fails, the deploy job is skipped.

---

## 12. Local Development

```bash
bundle exec jekyll serve --livereload
```

Visit `http://localhost:4000`. The sidebar shows all ~40 docs pages sorted by the `order` front matter field. The theme toggle persists to `localStorage`.

---

## 13. Quick-Start Script

Save this as `setup.sh` and run it to bootstrap the entire project:

```bash
#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-my-docs-site}"
mkdir -p "$NAME" && cd "$NAME"

# Gemfile
cat > Gemfile <<'GEMFILE'
source "https://rubygems.org"
ruby "~> 3.4"
gem "jekyll", "~> 4.3"
gem "jekyll-seo-tag"
gem "jekyll-feed"
gem "jekyll-sitemap"
gem "webrick"
group :test do
  gem "html-proofer", "~> 5.0"
end
GEMFILE

bundle install

# .ruby-version
echo "3.4" > .ruby-version

# _config.yml
cat > _config.yml <<CONFIG
title: "${NAME}"
description: "Documentation site"
baseurl: ""
url: ""
markdown: kramdown
highlighter: rouge
permalink: pretty
collections:
  docs:
    output: true
    sort_by: order
defaults:
  - scope:
      path: ""
      type: "docs"
    values:
      layout: docs
      sidebar: true
plugins:
  - jekyll-seo-tag
  - jekyll-feed
  - jekyll-sitemap
exclude:
  - Gemfile
  - Gemfile.lock
  - vendor
  - .github
CONFIG

# Create directories
mkdir -p _docs _layouts _includes assets/css assets/js .github/workflows

# index.md
cat > index.md <<'EOF'
---
layout: default
title: Home
---

# Welcome

This is the documentation site.
EOF

# Generate 40 doc pages
for i in $(seq 1 40); do
  cat > "_docs/page-$(printf '%02d' $i).md" <<DOCEOF
---
layout: docs
title: "Page $i"
order: $i
---

## Page $i

Content for page $i.
DOCEOF
done

# Layouts
cat > _layouts/default.html <<'EOF'
<!DOCTYPE html>
<html lang="en" data-theme="light">
{% include head.html %}
<body>
  {% include header.html %}
  <main>{{ content }}</main>
  {% include footer.html %}
  <script src="{{ '/assets/js/theme-toggle.js' | relative_url }}"></script>
</body>
</html>
EOF

cat > _layouts/docs.html <<'EOF'
---
layout: default
---
<div class="docs-layout">
  {% include sidebar.html %}
  <article class="doc-content">{{ content }}</article>
</div>
EOF

# Includes
cat > _includes/head.html <<'EOF'
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}</title>
<link rel="stylesheet" href="{{ '/assets/css/main.scss' | relative_url }}">
{% feed_meta %}
{% seo %}
EOF

cat > _includes/header.html <<'EOF'
<header class="site-header">
  <a href="{{ '/' | relative_url }}" class="site-title">{{ site.title }}</a>
  <button id="theme-toggle">🌙</button>
</header>
EOF

cat > _includes/sidebar.html <<'EOF'
<nav class="sidebar">
  <ul>
    {% assign docs = site.docs | sort: 'order' %}
    {% for doc in docs %}
      <li><a href="{{ doc.url | relative_url }}" class="{% if doc.url == page.url %}active{% endif %}">{{ doc.title }}</a></li>
    {% endfor %}
  </ul>
</nav>
EOF

cat > _includes/footer.html <<'EOF'
<footer><p>&copy; {{ site.time | date: '%Y' }} {{ site.title }}</p></footer>
EOF

cat > assets/css/main.scss <<'SCC'
---
---
:root { --bg: #fff; --text: #111; --sidebar-bg: #f4f4f8; --link: #4361ee; --border: #ddd; }
[data-theme="dark"] { --bg: #1a1a2e; --text: #e0e0e0; --sidebar-bg: #16213e; --link: #7b9cff; --border: #2a2a4a; }
body { margin: 0; font-family: system-ui, sans-serif; background: var(--bg); color: var(--text); }
.docs-layout { display: flex; }
.sidebar { width: 260px; padding: 1rem; background: var(--sidebar-bg); min-height: 100vh; border-right: 1px solid var(--border); }
.sidebar a { display: block; padding: 0.3rem 0.6rem; color: var(--text); text-decoration: none; }
.sidebar a.active { background: var(--link); color: #fff; border-radius: 4px; }
.doc-content { flex: 1; padding: 2rem; max-width: 800px; }
.site-header { display: flex; justify-content: space-between; padding: 1rem 2rem; border-bottom: 1px solid var(--border); }
SCC

cat > assets/js/theme-toggle.js <<'JS'
(function(){
  function t(){var k='theme',v=localStorage.getItem(k)||'light',n=v==='dark'?'light':'dark';document.documentElement.setAttribute('data-theme',n);localStorage.setItem(k,n);document.getElementById('theme-toggle').textContent=n==='dark'?'☀️':'🌙';}
  document.addEventListener('DOMContentLoaded',function(){document.getElementById('theme-toggle').addEventListener('click',t);});
})();
JS

# .github/workflows/deploy.yml
cat > .github/workflows/deploy.yml <<'YML'
name: Build and Deploy
on:
  push: { branches: [main, master] }
  pull_request: { branches: [main, master] }
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: false
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
          bundler-cache: true
      - id: pages
        uses: actions/configure-pages@v5
      - run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production
      - run: bundle exec htmlproofer ./_site --check-html --check-internal-hash --check-img-http --enforce-https --empty-alt-ignore --only-4xx --url-ignore "/^http:\/\/localhost/"
      - uses: actions/upload-pages-artifact@v3
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
  deploy:
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    needs: build
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
YML

echo "Done. Run: cd $NAME && bundle exec jekyll serve"
```

Run it:

```bash
chmod +x setup.sh && ./setup.sh my-docs-site
```

---

## 14. Summary

| Requirement | Implementation |
|---|---|
| ~40 pages | 40 `_docs/*.md` files with sequential `order` |
| Sidebar nav | `_includes/sidebar.html`, sorted via Liquid |
| Light/dark mode | CSS custom properties + JS toggle + `localStorage` |
| Ruby 3.4 | `.ruby-version` + `Gemfile` + `ruby/setup-ruby@v1` |
| GitHub Actions deploy | `.github/workflows/deploy.yml` with `actions/deploy-pages@v4` |
| html-proofer breaks on broken links | `bundle exec htmlproofer` with `--only-4xx`, non-zero exit halts the job |
