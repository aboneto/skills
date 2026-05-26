# Fix: `jekyll-paginate-v2` not found on GitHub Pages

## The Problem

The `github-pages` gem is a meta-gem that pins specific versions of Jekyll and a curated whitelist of plugins supported on GitHub Pages. **`jekyll-paginate-v2` is not on that whitelist.** When the GitHub Actions workflow runs `bundle install`, Bundler cannot resolve `jekyll-paginate-v2` because `github-pages` constrains the dependency graph and excludes it.

It works locally because your local Bundler resolves gems freely from RubyGems without the `github-pages` constraint overriding things (or your local `Gemfile.lock` has a resolution that the CI environment can't reproduce under the `github-pages` gem's constraints).

## Two Options

### Option A: Drop `jekyll-paginate-v2`, use `jekyll-paginate` (recommended if you want simple GitHub Pages support)

`jekyll-paginate` (v1) **is** supported by `github-pages`. If your pagination needs are simple (single index page, no filtering/categories), just swap the gem:

```ruby
# Gemfile
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins
gem "jekyll-paginate", group: :jekyll_plugins
```

Update `_config.yml`:

```yaml
plugins:
  - jekyll-paginate

paginate: 5
paginate_path: "/page:num/"
```

Remove any `jekyll-paginate-v2`-specific config keys like `autopages`, `paginate_categories`, etc. Commit the updated `Gemfile.lock` after running `bundle install` locally.

### Option B: Keep `jekyll-paginate-v2`, drop `github-pages`

If you need v2 features (multiple pagination, category/tag filtering), remove `github-pages` and use plain `jekyll`:

```ruby
# Gemfile
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "jekyll-paginate-v2", group: :jekyll_plugins
# add any other plugins you need explicitly
```

Then update your GitHub Actions workflow to use a custom build instead of the default Pages action. The workflow in `.github/workflows/pages.yml` should look something like:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: ["main"]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Build with Jekyll
        run: bundle exec jekyll build --baseurl "/blog"
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site

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

In `_config.yml`, set:

```yaml
url: "https://me.github.io"
baseurl: "/blog"
```

Also ensure your repository's GitHub Pages source is set to **"GitHub Actions"** (not "Deploy from a branch") under **Settings > Pages > Build and deployment**.

## TL;DR

- `github-pages` gem blocks gems not on its whitelist — `jekyll-paginate-v2` is not whitelisted.
- **Option A:** Replace `jekyll-paginate-v2` with `jekyll-paginate` (supported, simple).
- **Option B:** Remove `github-pages`, use plain `jekyll` + custom Actions workflow (full v2 features).
