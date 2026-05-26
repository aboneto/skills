# Setting up a Jekyll Docs Site (macOS)

This guide walks you through setting up a Jekyll docs site with 40+ pages, sidebar navigation, and light/dark mode support, using GitHub Actions for deployment and `html-proofer` for link validation.

## 1. Environment & Setup

Ensure you are using Ruby 3.4.x. Use `rbenv` or `mise` to manage Ruby versions on macOS.

```bash
# Example with rbenv
rbenv install 3.4.8
rbenv global 3.4.8
gem install bundler
```

## 2. Gemfile

Create a `Gemfile` in your project root. We include `html-proofer` in a `:test` group for CI.

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-include-cache", "~> 0.2"
end

group :test do
  gem "html-proofer", "~> 5.0"
end

gem "webrick", "~> 1.9"
gem "sass-embedded", "~> 1.77"
```

## 3. Configuration (`_config.yml`)

Configure your site. For docs, consider using a collection (e.g., `_docs/`).

```yaml
title: "Docs Site"
url: "https://example.com"
baseurl: ""
markdown: kramdown

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-include-cache

collections:
  docs:
    output: true
    permalink: /docs/:path/

defaults:
  - scope: { path: "", type: "docs" }
    values: { layout: doc }
```

## 4. Sidebar Navigation & Dark Mode

For 40+ pages, use a `_data/navigation.yml` file to define your sidebar structure and iterate over it in your `_includes/sidebar.html`.

For Light/Dark mode, a simple approach is to use a theme that supports it (e.g., [Just the Docs](https://just-the-docs.github.io/)) or toggle a class on the `<body>` element using JavaScript and switch CSS variables.

## 5. Deployment with GitHub Actions & `html-proofer`

Create `.github/workflows/jekyll.yml`. This workflow builds the site, runs `html-proofer` to fail on broken internal links, and deploys to GitHub Pages.

```yaml
name: Build and deploy

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4'
          bundler-cache: true
      - name: Build
        run: bundle exec jekyll build
        env:
          JEKYLL_ENV: production
      - name: HTML proofer
        run: bundle exec htmlproofer ./_site --disable-external --check-html
      - uses: actions/upload-pages-artifact@v3
        with:
          path: _site/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
        id: deployment
```
