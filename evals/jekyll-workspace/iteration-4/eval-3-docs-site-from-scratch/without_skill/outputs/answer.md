# Jekyll Docs Site from Scratch — macOS, Ruby 3.4, GitHub Pages

## Prerequisites (macOS)

```bash
# Install Ruby 3.4 via Homebrew
brew install ruby@3.4

# Add to your shell profile (~/.zshrc)
export PATH="/opt/homebrew/opt/ruby@3.4/bin:$PATH"
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"

# Reload shell
source ~/.zshrc

# Verify
ruby -v   # ruby 3.4.x
gem -v
```

---

## Project Structure

```
docs-site/
├── Gemfile
├── _config.yml
├── .github/
│   └── workflows/
│       └── deploy.yml
├── _data/
│   └── navigation.yml
├── _includes/
│   ├── head.html
│   ├── header.html
│   ├── sidebar.html
│   └── footer.html
├── _layouts/
│   ├── default.html
│   └── page.html
├── _sass/
│   ├── _variables.scss
│   ├── _base.scss
│   ├── _sidebar.scss
│   ├── _header.scss
│   └── _theme.scss
├── assets/
│   └── css/
│       └── style.scss
│   └── js/
│       └── theme-toggle.js
├── index.md
├── Gemfile.lock          (generated)
└── [~40 .md content pages]
```

---

## 1. Gemfile

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll", "~> 4.4"

gem "jekyll-seo-tag", "~> 2.8"
gem "jekyll-sitemap", "~> 1.4"
gem "jekyll-feed", "~> 0.17"

gem "webrick", "~> 2.0" # required for Ruby 3.4

group :jekyll_plugins do
  gem "jekyll-include-cache", "~> 0.2"
end

group :test do
  gem "html-proofer", "~> 5.0"
end
```

After creating the Gemfile, run:

```bash
bundle install
```

---

## 2. _config.yml

```yaml
title: "My Documentation"
description: "Project documentation with sidebar navigation, light/dark mode, and 40+ pages."
url: "https://yourusername.github.io"
baseurl: "/your-repo-name"

permalink: pretty

markdown: kramdown
highlighter: rouge

kramdown:
  input: GFM
  syntax_highlighter: rouge
  hard_wrap: false

sass:
  sass_dir: _sass
  style: compressed

plugins:
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-feed
  - jekyll-include-cache

collections:
  docs:
    output: true
    permalink: /:collection/:name/

defaults:
  - scope:
      path: ""
      type: "docs"
    values:
      layout: "page"

exclude:
  - Gemfile
  - Gemfile.lock
  - node_modules
  - README.md
  - vendor
  - ".github"
```

---

## 3. Sidebar Navigation Data

### _data/navigation.yml

```yaml
sections:
  - title: Getting Started
    items:
      - name: Introduction
        url: /docs/introduction/
      - name: Installation
        url: /docs/installation/
      - name: Quick Start
        url: /docs/quick-start/
      - name: Configuration
        url: /docs/configuration/

  - title: Core Concepts
    items:
      - name: Architecture
        url: /docs/architecture/
      - name: Data Models
        url: /docs/data-models/
      - name: Routing
        url: /docs/routing/
      - name: Middleware
        url: /docs/middleware/
      - name: Error Handling
        url: /docs/error-handling/

  - title: Guides
    items:
      - name: Authentication
        url: /docs/authentication/
      - name: Authorization
        url: /docs/authorization/
      - name: Database
        url: /docs/database/
      - name: Caching
        url: /docs/caching/
      - name: Logging
        url: /docs/logging/
      - name: Testing
        url: /docs/testing/
      - name: Debugging
        url: /docs/debugging/
      - name: Deployment
        url: /docs/deployment/

  - title: API Reference
    items:
      - name: REST API
        url: /docs/rest-api/
      - name: GraphQL
        url: /docs/graphql/
      - name: WebSockets
        url: /docs/websockets/
      - name: CLI
        url: /docs/cli/
      - name: SDKs
        url: /docs/sdks/

  - title: Advanced
    items:
      - name: Performance
        url: /docs/performance/
      - name: Security
        url: /docs/security/
      - name: Internationalization
        url: /docs/internationalization/
      - name: Plugins
        url: /docs/plugins/
      - name: Custom Extensions
        url: /docs/custom-extensions/

  - title: Integrations
    items:
      - name: CI/CD
        url: /docs/ci-cd/
      - name: Docker
        url: /docs/docker/
      - name: Kubernetes
        url: /docs/kubernetes/
      - name: Cloud Providers
        url: /docs/cloud-providers/
      - name: Third-Party Services
        url: /docs/third-party-services/

  - title: Resources
    items:
      - name: Changelog
        url: /docs/changelog/
      - name: Migration Guide
        url: /docs/migration-guide/
      - name: FAQ
        url: /docs/faq/
      - name: Troubleshooting
        url: /docs/troubleshooting/
      - name: Contributing
        url: /docs/contributing/
      - name: Glossary
        url: /docs/glossary/
```

---

## 4. Layouts

### _layouts/default.html

```html
<!DOCTYPE html>
<html lang="en" data-theme="light">
<head>
  {% include head.html %}
</head>
<body>
  {% include header.html %}
  <div class="site-wrapper">
    {% include sidebar.html %}
    <main class="content">
      {{ content }}
    </main>
  </div>
  {% include footer.html %}
  <script src="{{ '/assets/js/theme-toggle.js' | relative_url }}"></script>
</body>
</html>
```

### _layouts/page.html

```html
---
layout: default
---
<article class="page">
  <h1>{{ page.title }}</h1>
  {{ content }}
</article>
```

---

## 5. Includes

### _includes/head.html

```html
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{% if page.title %}{{ page.title }} | {{ site.title }}{% else %}{{ site.title }}{% endif %}</title>
<meta name="description" content="{{ page.description | default: site.description }}">
<link rel="stylesheet" href="{{ '/assets/css/style.css' | relative_url }}">
{% seo %}
{% feed_meta %}
```

### _includes/header.html

```html
<header class="site-header">
  <div class="header-inner">
    <a class="site-title" href="{{ '/' | relative_url }}">{{ site.title }}</a>
    <nav class="header-nav">
      <a href="{{ '/' | relative_url }}">Home</a>
      <a href="{{ '/docs/introduction/' | relative_url }}">Docs</a>
    </nav>
    <button class="theme-toggle" id="theme-toggle" aria-label="Toggle dark mode">
      <span class="theme-icon-light">☀️</span>
      <span class="theme-icon-dark">🌙</span>
    </button>
    <button class="sidebar-toggle" id="sidebar-toggle" aria-label="Toggle sidebar">☰</button>
  </div>
</header>
```

### _includes/sidebar.html

```html
<aside class="sidebar" id="sidebar">
  <nav class="sidebar-nav">
    {% for section in site.data.navigation.sections %}
      <div class="nav-section">
        <h3 class="nav-section-title">{{ section.title }}</h3>
        <ul>
          {% for item in section.items %}
            <li>
              <a href="{{ item.url | relative_url }}"
                 {% if page.url == item.url %}class="active"{% endif %}>
                {{ item.name }}
              </a>
            </li>
          {% endfor %}
        </ul>
      </div>
    {% endfor %}
  </nav>
</aside>
```

### _includes/footer.html

```html
<footer class="site-footer">
  <p>&copy; {{ site.time | date: '%Y' }} {{ site.title }}. Built with Jekyll and hosted on GitHub Pages.</p>
</footer>
```

---

## 6. Stylesheets

### assets/css/style.scss

```scss
---
---
@import "variables";
@import "base";
@import "header";
@import "sidebar";
@import "theme";
```

### _sass/_variables.scss

```scss
:root {
  --color-bg: #ffffff;
  --color-bg-secondary: #f6f8fa;
  --color-text: #1f2328;
  --color-text-secondary: #656d76;
  --color-border: #d0d7de;
  --color-link: #0969da;
  --color-link-hover: #0550ae;
  --color-sidebar-bg: #f6f8fa;
  --color-sidebar-active: #0969da;
  --color-code-bg: #f6f8fa;
  --color-header-bg: #24292f;
  --color-header-text: #ffffff;
  --sidebar-width: 280px;
  --content-max-width: 860px;
  --header-height: 56px;
}

[data-theme="dark"] {
  --color-bg: #0d1117;
  --color-bg-secondary: #161b22;
  --color-text: #e6edf3;
  --color-text-secondary: #8b949e;
  --color-border: #30363d;
  --color-link: #58a6ff;
  --color-link-hover: #79c0ff;
  --color-sidebar-bg: #161b22;
  --color-sidebar-active: #58a6ff;
  --color-code-bg: #161b22;
  --color-header-bg: #161b22;
  --color-header-text: #e6edf3;
}
```

### _sass/_base.scss

```scss
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  font-size: 16px;
  scroll-behavior: smooth;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  background-color: var(--color-bg);
  color: var(--color-text);
  line-height: 1.6;
  transition: background-color 0.2s ease, color 0.2s ease;
}

a {
  color: var(--color-link);
  text-decoration: none;
  &:hover {
    color: var(--color-link-hover);
    text-decoration: underline;
  }
}

h1, h2, h3, h4, h5, h6 {
  margin-top: 1.5em;
  margin-bottom: 0.5em;
  line-height: 1.25;
}

h1 { font-size: 2rem; }
h2 { font-size: 1.5rem; border-bottom: 1px solid var(--color-border); padding-bottom: 0.3em; }
h3 { font-size: 1.25rem; }

p { margin-bottom: 1em; }

code {
  background: var(--color-code-bg);
  padding: 0.2em 0.4em;
  border-radius: 3px;
  font-size: 0.875em;
}

pre {
  background: var(--color-code-bg);
  padding: 1em;
  border-radius: 6px;
  overflow-x: auto;
  margin-bottom: 1em;
  code {
    background: none;
    padding: 0;
  }
}

ul, ol {
  margin-bottom: 1em;
  padding-left: 2em;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin-bottom: 1em;
  th, td {
    border: 1px solid var(--color-border);
    padding: 0.5em 0.75em;
    text-align: left;
  }
  th {
    background: var(--color-bg-secondary);
  }
}

blockquote {
  border-left: 4px solid var(--color-link);
  padding: 0.5em 1em;
  margin-bottom: 1em;
  background: var(--color-bg-secondary);
}

img {
  max-width: 100%;
  height: auto;
}

.site-wrapper {
  display: flex;
  margin-top: var(--header-height);
  min-height: calc(100vh - var(--header-height));
}

.content {
  flex: 1;
  max-width: var(--content-max-width);
  margin: 0 auto;
  padding: 2em;
  min-width: 0;
}

.page {
  max-width: var(--content-max-width);
}

.site-footer {
  text-align: center;
  padding: 2em;
  border-top: 1px solid var(--color-border);
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}
```

### _sass/_header.scss

```scss
.site-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: var(--header-height);
  background: var(--color-header-bg);
  color: var(--color-header-text);
  z-index: 100;
  border-bottom: 1px solid var(--color-border);
}

.header-inner {
  display: flex;
  align-items: center;
  height: 100%;
  padding: 0 1.5rem;
  max-width: 100%;
}

.site-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-header-text);
  text-decoration: none;
  margin-right: 2rem;
  &:hover {
    text-decoration: none;
    opacity: 0.8;
  }
}

.header-nav {
  display: flex;
  gap: 1.5rem;
  a {
    color: var(--color-header-text);
    opacity: 0.85;
    font-size: 0.9rem;
    &:hover {
      opacity: 1;
      text-decoration: none;
    }
  }
}

.theme-toggle {
  margin-left: auto;
  background: none;
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 6px;
  cursor: pointer;
  padding: 0.35rem 0.6rem;
  font-size: 1rem;
  display: flex;
  align-items: center;
}

[data-theme="light"] .theme-icon-dark { display: none; }
[data-theme="dark"] .theme-icon-light { display: none; }

.sidebar-toggle {
  display: none;
  background: none;
  border: 1px solid rgba(255,255,255,0.2);
  border-radius: 6px;
  color: var(--color-header-text);
  font-size: 1.25rem;
  cursor: pointer;
  padding: 0.3rem 0.6rem;
  margin-left: 0.75rem;
}

@media (max-width: 768px) {
  .sidebar-toggle {
    display: block;
  }
}
```

### _sass/_sidebar.scss

```scss
.sidebar {
  position: fixed;
  top: var(--header-height);
  left: 0;
  bottom: 0;
  width: var(--sidebar-width);
  background: var(--color-sidebar-bg);
  border-right: 1px solid var(--color-border);
  overflow-y: auto;
  padding: 1.5rem 0;
  z-index: 50;
}

.sidebar-nav {
  display: flex;
  flex-direction: column;
}

.nav-section {
  margin-bottom: 0.5rem;
}

.nav-section-title {
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-secondary);
  padding: 0.5rem 1.5rem;
  margin: 0;
}

.nav-section ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.nav-section li a {
  display: block;
  padding: 0.3rem 1.5rem 0.3rem 1.75rem;
  font-size: 0.875rem;
  color: var(--color-text);
  text-decoration: none;
  border-left: 3px solid transparent;
  transition: all 0.15s ease;

  &:hover {
    background: var(--color-bg);
    color: var(--color-link);
    text-decoration: none;
  }

  &.active {
    color: var(--color-sidebar-active);
    border-left-color: var(--color-sidebar-active);
    font-weight: 600;
    background: var(--color-bg);
  }
}

.content {
  margin-left: var(--sidebar-width);
}

@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    transition: transform 0.25s ease;
    &.open {
      transform: translateX(0);
      box-shadow: 4px 0 12px rgba(0,0,0,0.15);
    }
  }
  .content {
    margin-left: 0;
  }
}
```

### _sass/_theme.scss

```scss
// Utility classes
.note {
  background: #dbeafe;
  border: 1px solid #93c5fd;
  border-radius: 6px;
  padding: 1em;
  margin-bottom: 1em;
}

[data-theme="dark"] .note {
  background: #1e3a5f;
  border-color: #3b82f6;
}

.warning {
  background: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 6px;
  padding: 1em;
  margin-bottom: 1em;
}

[data-theme="dark"] .warning {
  background: #422006;
  border-color: #f59e0b;
}

.danger {
  background: #fee2e2;
  border: 1px solid #f87171;
  border-radius: 6px;
  padding: 1em;
  margin-bottom: 1em;
}

[data-theme="dark"] .danger {
  background: #450a0a;
  border-color: #ef4444;
}
```

---

## 7. JavaScript — Theme Toggle

### assets/js/theme-toggle.js

```javascript
(function () {
  const STORAGE_KEY = "theme-preference";

  function getPreferredTheme() {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  }

  function setTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    localStorage.setItem(STORAGE_KEY, theme);
  }

  // Apply immediately
  setTheme(getPreferredTheme());

  document.addEventListener("DOMContentLoaded", function () {
    var btn = document.getElementById("theme-toggle");
    if (btn) {
      btn.addEventListener("click", function () {
        var current = document.documentElement.getAttribute("data-theme");
        setTheme(current === "dark" ? "light" : "dark");
      });
    }

    var sidebarBtn = document.getElementById("sidebar-toggle");
    var sidebar = document.getElementById("sidebar");
    if (sidebarBtn && sidebar) {
      sidebarBtn.addEventListener("click", function () {
        sidebar.classList.toggle("open");
      });
    }
  });
})();
```

---

## 8. Index Page

### index.md

```yaml
---
layout: default
title: Home
---
# Welcome to the Documentation

This is the home page for the project documentation. Use the sidebar to navigate.

[Get started with the Introduction →](/docs/introduction/)

## Highlights

- **40+ pages** covering every aspect of the project
- **Sidebar navigation** with collapsible sections
- **Light / dark mode** with system preference detection
- **Fast static site** built with Jekyll 4 and deployed via GitHub Pages
```

---

## 9. Sample Content Pages

Create a `_docs/` directory and populate it. Below are a few representative pages — replicate this pattern for all ~40 pages.

### _docs/introduction.md

```yaml
---
title: Introduction
---
# Introduction

Welcome to the project documentation. This guide covers everything from installation to advanced configuration.

## What You'll Learn

- How to install and configure the project
- Core concepts and architecture
- API reference and integrations
- Advanced topics and troubleshooting

## Audience

This documentation is for developers of all experience levels. Beginners should start with the [Installation](/docs/installation/) guide.
```

### _docs/installation.md

```yaml
---
title: Installation
---
# Installation

## Prerequisites

- Ruby 3.4 or later
- Bundler gem

## Steps

1. Clone the repository
2. Run `bundle install`
3. Run `bundle exec jekyll serve`
4. Open `http://localhost:4000`

## Verify

```bash
bundle exec jekyll doctor
```

If you see no errors, the site is ready.
```

### _docs/quick-start.md

```yaml
---
title: Quick Start
---
# Quick Start

Follow these steps to get up and running in under five minutes.

1. [Install](/docs/installation/) the project
2. Review the [Configuration](/docs/configuration/) options
3. Explore the [Architecture](/docs/architecture/) overview

> **Tip:** Start with the defaults and customise as needed.
```

### _docs/configuration.md

```yaml
---
title: Configuration
---
# Configuration

All configuration is managed through `_config.yml`.

## Key Settings

| Setting     | Default         | Description                       |
|-------------|-----------------|-----------------------------------|
| `title`     | My Documentation| Site title                        |
| `baseurl`   | /               | Base URL path                     |
| `permalink` | pretty          | URL structure for posts and pages |

## Environment Variables

Set `JEKYLL_ENV=production` for production builds.
```

Create the remaining pages (`architecture.md`, `data-models.md`, `routing.md`, … `glossary.md`) following the same pattern — each with a YAML front matter containing `title` and Markdown content with cross-links to other pages. Aim for 40 total files in `_docs/`.

---

## 10. GitHub Actions Deployment Workflow

### .github/workflows/deploy.yml

```yaml
name: Build and deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Ruby 3.4
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.4"
          bundler-cache: true

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Build with Jekyll
        run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production

      - name: Run html-proofer
        run: |
          bundle exec htmlproofer ./_site \
            --disable-external \
            --check-html \
            --empty-alt-ignore \
            --allow-hash-href \
            --no-enforce-https \
            --ignore-files "/_site/404.html" \
            --assume-extension .html \
            --url-swap "^/your-repo-name:" \
            --log-level :info
        # --disable-external: skip checking external URLs (too slow/flaky in CI)
        # --check-html: validate HTML structure
        # --empty-alt-ignore: don't fail on images missing alt text
        # --allow-hash-href: allow href="#"
        # --assume-extension .html: match /docs/introduction -> /docs/introduction.html
        # --url-swap: strip baseurl so internal link checks resolve correctly

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: _site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## 11. html-proofer — What It Does

The `htmlproofer` step in the workflow **fails the build** if any internal link is broken. Key flags:

| Flag | Purpose |
|------|---------|
| `--disable-external` | Skip outbound URLs (fast, avoids flaky failures) |
| `--check-html` | Catch malformed HTML |
| `--assume-extension .html` | `/docs/introduction` resolves to `/docs/introduction.html` |
| `--url-swap "^/your-repo-name:"` | Strip baseurl so paths match the built `_site` structure |
| `--allow-hash-href` | Permit `href="#"` anchors |

If any internal link points to a non-existent page, `htmlproofer` exits non-zero and the workflow **fails before deployment**.

---

## 12. GitHub Pages Repository Settings

1. Go to **Settings → Pages** in your repository.
2. Under **Build and deployment**, set **Source** to **GitHub Actions**.
3. Ensure the workflow has permission: **Settings → Actions → General → Workflow permissions → Read and write permissions**.

---

## 13. Local Development

```bash
# Serve locally with live reload
bundle exec jekyll serve --livereload

# Build without serving (useful for testing proofer locally)
bundle exec jekyll build
bundle exec htmlproofer ./_site --disable-external --check-html --assume-extension .html
```

---

## 14. Adding More Pages

To reach ~40 pages, create one `.md` file per doc in `_docs/`:

```bash
# Example: create all remaining pages
for page in architecture data-models routing middleware error-handling \
            authentication authorization database caching logging \
            testing debugging deployment rest-api graphql websockets \
            cli sdks performance security internationalization plugins \
            custom-extensions ci-cd docker kubernetes cloud-providers \
            third-party-services changelog migration-guide faq \
            troubleshooting contributing glossary; do
  cat > "_docs/${page}.md" <<EOF
---
title: "${page//-/ }"
---
# ${page//-/ }

Content for the ${page//-/ } page.

[Back to Introduction](/docs/introduction/)
EOF
done
```

Then add matching entries in `_data/navigation.yml`.

---

## 15. Checklist

- [ ] `Gemfile` created and `bundle install` succeeds
- [ ] `_config.yml` configured with correct `baseurl`
- [ ] `_data/navigation.yml` lists all sections and pages
- [ ] Layouts and includes in `_layouts/` and `_includes/`
- [ ] Stylesheets in `_sass/` and `assets/css/style.scss`
- [ ] Theme toggle JS in `assets/js/theme-toggle.js`
- [ ] All ~40 `.md` files created in `_docs/`
- [ ] `.github/workflows/deploy.yml` committed
- [ ] GitHub repo Pages source set to **GitHub Actions**
- [ ] `html-proofer` step passes locally after `jekyll build`
