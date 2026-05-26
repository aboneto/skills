# `jekyll-paginate-v2` Fails on GitHub Pages

## Root Cause

The `github-pages` gem includes `jekyll-paginate` (v1) as a dependency. When you also add `jekyll-paginate-v2` to your Gemfile, the build fails because **GitHub Pages uses a whitelist of allowed gems** for dependency resolution — and it only resolves dependencies through the `github-pages` gem's own constraints, not your full Gemfile. The Actions runner installs gems from GitHub's own dependency server, which builds a resolution graph from the `github-pages` gem's gemspec. Since `jekyll-paginate-v2` is not an allowed dependency of `github-pages`, Bundler can't resolve it in the Actions environment, even though `bundle install` works fine locally (where your full Gemfile is honored).

## Why It Works Locally but Not on CI

| Environment | Resolution |
|---|---|
| `bundle exec jekyll serve` (local) | Bundler resolves your full Gemfile — both `github-pages` and `jekyll-paginate-v2` coexist via `:jekyll_plugins` group |
| GitHub Pages Actions build | GitHub resolves gems from its own dependency manifest, which only knows about `github-pages`'s declared dependencies |

## Solutions

### Option A — Switch to `jekyll-paginate` (Recommended)

Replace `jekyll-paginate-v2` with the official `jekyll-paginate` (v1), which is already included by `github-pages`:

```ruby
# Gemfile
gem "github-pages", group: :jekyll_plugins
```

Then in `_config.yml`:

```yaml
paginate: 5
paginate_path: "/blog/page:num/"
```

This requires adapting any `jekyll-paginate-v2`-specific features (e.g., `pagination.enabled`, autopages) to the v1 API.

### Option B — Build with Raw Jekyll via GitHub Actions

Stop using the `github-pages` gem and build with Jekyll directly, which lets you use any gem:

```ruby
# Gemfile (no github-pages)
gem "jekyll"
gem "jekyll-paginate-v2"
```

Create `.github/workflows/jekyll.yml`:

```yaml
name: Build and deploy Jekyll site
on:
  push:
    branches: [master]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true
      - run: bundle exec jekyll build
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./_site
```

Then enable **GitHub Actions** as the source under Settings → Pages (instead of "Deploy from a branch").

### Option C — Use a Custom Fork of `github-pages`

Fork the `github-pages` gem, add `jekyll-paginate-v2` to its dependency list, point your Gemfile at your fork:

```ruby
gem "github-pages", git: "https://github.com/me/github-pages.git"
```

This is brittle and not recommended.

## Summary

| Approach | Complexity | Paginate v2 features | Official GitHub Pages support |
|---|---|---|---|
| Switch to `jekyll-paginate` | Low | Lost | Yes |
| Raw Jekyll + Actions workflow | Medium | Kept | No (but deploys fine) |
| Fork `github-pages` | High | Kept | No |

The quickest fix is **Option A**. If you need `jekyll-paginate-v2` features (e.g., multiple pagination, autopages), go with **Option B**.
