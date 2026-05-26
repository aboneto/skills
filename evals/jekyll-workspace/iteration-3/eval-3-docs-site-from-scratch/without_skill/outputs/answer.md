# Jekyll Docs Site Setup

## 1. Gemfile
```ruby
source 'https://rubygems.org'

gem 'jekyll'
gem 'github-pages', group: :jekyll_plugins
gem 'html-proofer', group: :test
```

## 2. _config.yml
```yaml
title: My Docs Site
theme: minima
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap

defaults:
  - scope:
      path: ""
    values:
      layout: default
```

## 3. Sidebar Navigation (_data/navigation.yml)
```yaml
- title: Introduction
  url: /
- title: Getting Started
  url: /getting-started/
```
(Reference `site.data.navigation` in your layout file).

## 4. Light/Dark Mode (assets/css/style.css)
```css
:root {
  --bg-color: #ffffff;
  --text-color: #000000;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg-color: #121212;
    --text-color: #ffffff;
  }
}

body {
  background-color: var(--bg-color);
  color: var(--text-color);
}
```

## 5. GitHub Actions Workflow (.github/workflows/pages.yml)
```yaml
name: Deploy Jekyll to GitHub Pages

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true
      - name: Build site
        run: bundle exec jekyll build
      - name: Run HTML Proofer
        run: |
          bundle exec htmlproofer ./_site --disable-external
      - name: Deploy
        uses: actions/deploy-pages@v4
```
