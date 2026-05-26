# Fix: `jekyll-paginate-v2` on GitHub Pages

## The problem

`jekyll-paginate-v2` is **not on the [GitHub Pages plugin allowlist](https://pages.github.com/versions/)**. The classic builder (which builds when you push source to a branch) uses Jekyll 3.10.x and only permits a fixed set of gems. That's why it fails in Actions but works locally — locally you run `bundle exec jekyll build` with your own gems.

## Two paths forward

### Option A — Switch to GitHub Actions deployment (recommended)

This unlocks current Jekyll (4.4.x), `jekyll-paginate-v2`, and any other plugin.

**1. Replace your Gemfile** with the modern one (remove the `github-pages` gem):

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

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
```

**2. Create `.github/workflows/jekyll.yml`:**

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

**3. In your repo: Settings → Pages → Build and deployment → Source: GitHub Actions.**

**4. Set `_config.yml`:**

```yaml
url: "https://me.github.io"
baseurl: "/blog"
```

**5. Push.** The workflow will build and deploy.

### Option B — Stay on classic builder, drop `jekyll-paginate-v2`

If you don't want to switch to Actions, remove `jekyll-paginate-v2` from both your `Gemfile` and `_config.yml` plugins list, and use the limited `jekyll-paginate` instead (only paginates `site.posts` on `index.html`, no category/tag pagination):

```ruby
# Gemfile
source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "webrick", "~> 1.9"
```

```yaml
# _config.yml
plugins:
  - jekyll-paginate

paginate: 10
paginate_path: "/page:num/"
```

## Why it works locally

`bundle exec jekyll build` uses whatever gems your `Gemfile.lock` resolves. Locally you have `jekyll-paginate-v2` installed. The GitHub Pages classic builder ignores your Gemfile entirely and uses its own internal dependency set — which doesn't include `jekyll-paginate-v2`.

## Bottom line

Go with **Option A**. It takes 5 minutes to set up and gives you Jekyll 4.4, arbitrary plugins, and custom build steps. The classic builder is a legacy path at this point.
