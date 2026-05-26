# GitHub Pages build fails with `Could not find gem 'jekyll-paginate-v2'`

## Root Cause

`jekyll-paginate-v2` is **not on the [GitHub Pages plugin allowlist](https://pages.github.com/versions/)**. The `github-pages` gem pins your site to Jekyll 3.10.x and only allows a fixed set of plugins. Even though the gem appears in your `Gemfile` under `:jekyll_plugins`, the GitHub Pages build environment ignores your `Gemfile.lock` and resolves dependencies against its own locked set — which doesn't include `jekyll-paginate-v2`.

The local `bundle exec jekyll serve` works because your local machine has the gem installed and can resolve it freely.

> Note: You mention "Actions build" — if you're using the official `actions/jekyll-build-pages` step, it also uses the `github-pages` gem under the hood and is subject to the same restrictions. Even a custom Actions workflow will fail if the `github-pages` gem is in your `Gemfile`, because it transitively depends on `jekyll-paginate` (the old one) and conflicts with `jekyll-paginate-v2`.

## Solutions (pick one)

### Recommended: Move to GitHub Actions with a modern Jekyll build

This is the standard fix in 2026. You keep free GitHub Pages hosting but escape all allowlist restrictions — current Jekyll (4.4.x) plus any plugin you want.

**1. Replace your Gemfile.**

Remove the `github-pages` gem and list individual gems. A working `Gemfile`:

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
```

Run `bundle install` and commit the new `Gemfile.lock`.

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

**3. Switch Pages source.** In your repo → **Settings → Pages → Build and deployment → Source:** select "GitHub Actions".

**4. Push to `main`.** The workflow runs, builds with Jekyll 4.4.x + `jekyll-paginate-v2`, and deploys `_site/` to Pages.

### Alternative: Drop `jekyll-paginate-v2` and stay on classic builder

If you don't want to change the build setup, remove `jekyll-paginate-v2` from your Gemfile and `_config.yml`. Replace it with the built-in (but limited) `jekyll-paginate` — which only works on `index.html`, paginates only `site.posts`, and doesn't support category/tag-based pagination.

```ruby
# Gemfile — remove jekyll-paginate-v2, keep github-pages
gem "github-pages", group: :jekyll_plugins
```

```yaml
# _config.yml — replace jekyll-paginate-v2 with jekyll-paginate
plugins:
  - jekyll-paginate

paginate: 10
paginate_path: "/page/:num/"
```

This is a downgrade in capability but requires no build pipeline changes.

## Why the `github-pages` gem and `jekyll-paginate-v2` can't coexist

- The `github-pages` gem ships with `jekyll-paginate` (the old one) as a dependency. It resolves to Jekyll 3.10.x.
- `jekyll-paginate-v2` is a separate gem that replaces the `jekyll-paginate` namespace. On GitHub Pages' builder, Bundler cannot resolve `jekyll-paginate-v2` because it's not in the builder's locked dependency set.
- Even in a custom GitHub Actions workflow, the `github-pages` gem's strict version pins cause `bundle install` to fail when `jekyll-paginate-v2` is also declared.
