# Why it builds locally but fails on GitHub Pages

Short version: `jekyll-paginate-v2` is **not** on GitHub Pages' plugin allowlist. The classic GitHub Pages builder only loads the plugins listed at <https://pages.github.com/versions/>, regardless of what your `Gemfile` says. Locally `bundle exec jekyll serve` happily loads anything in your `:jekyll_plugins` group — that's why it works on your machine. On Pages, the builder sandbox refuses to install or load `jekyll-paginate-v2`, so the resolver can't find the gem and the build dies with `Could not find gem 'jekyll-paginate-v2'`.

This is also why mixing the `github-pages` meta-gem with extra plugins is misleading: the gem itself resolves fine in Bundler, but the runtime on Pages won't actually load anything beyond the allowlist.

You have two clean paths. Pick based on whether you need `paginate-v2`.

---

## Option A (recommended): build with GitHub Actions and deploy to Pages

This is the modern default. You keep free Pages hosting, drop the allowlist entirely, and get current Jekyll (4.4.x) plus any plugin you want — including `jekyll-paginate-v2`.

### 1. Switch the Pages source

In your repo: **Settings → Pages → Build and deployment → Source: GitHub Actions**.

### 2. Replace `github-pages` in your `Gemfile`

Drop the `github-pages` gem (it pins you to Jekyll 3.10.x and pulls in a pile of unneeded transitive deps). Use a modern Gemfile instead:

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

Then locally:

```bash
rm Gemfile.lock
bundle install
```

Commit the new `Gemfile` and `Gemfile.lock`.

### 3. List every plugin explicitly in `_config.yml`

When you used `github-pages`, you could rely on it auto-registering allowlisted plugins. Now you need to be explicit:

```yaml
plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
  - jekyll-redirect-from
  - jekyll-paginate-v2
```

Plugins must be in **both** the `Gemfile` (under `:jekyll_plugins`) **and** `_config.yml` — the most common cause of "it doesn't run" bugs is forgetting one of the two.

### 4. Fix `baseurl` for a project site

Your site lives at `me.github.io/blog`, so it's a **project page**, not a user page. That means:

```yaml
# _config.yml
url: "https://me.github.io"
baseurl: "/blog"
```

And in templates, always pipe through `relative_url`:

```liquid
<a href="{{ "/about/" | relative_url }}">About</a>
<img src="{{ "/logo.png" | relative_url }}">
```

Hardcoded `/about/` works locally but 404s under `/blog/`.

The workflow below also passes `--baseurl` from `actions/configure-pages`, which is the safety belt for this.

### 5. Add `.github/workflows/jekyll.yml`

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

`JEKYLL_ENV: production` matters — without it, `jekyll-seo-tag` and many themes emit dev placeholders instead of your real analytics ID, canonical URL, etc.

### 6. Push to `main`

First build takes ~2 minutes; subsequent runs cache gems via `bundler-cache: true` and finish in ~30s. You can watch it under **Actions** in your repo.

---

## Option B: stay on the classic builder and drop paginate-v2

If you don't want to maintain a workflow, you have to live within the allowlist:

1. Remove `jekyll-paginate-v2` from `Gemfile` and `_config.yml`.
2. Use the original `jekyll-paginate` (which **is** on the allowlist) — but it only works on `index.html` and only paginates `site.posts`. No per-category/tag pagination, no custom permalinks. If that's enough for your blog, this is fine.
3. Anything else you add later must also be on <https://pages.github.com/versions/>.

`Gemfile`:

```ruby
source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "webrick", "~> 1.9"
```

`_config.yml`:

```yaml
paginate: 10
paginate_path: "/page:num/"
plugins:
  - jekyll-paginate
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap
```

---

## My call

Go with Option A. The classic builder is a dead end the moment you want per-tag pagination, Tailwind, Pagefind, image processing, a newer Jekyll feature like the `find` filter, or any custom `_plugins/` Ruby. Once you've done it once, you never go back, and the workflow above is the same one I'd give for any new Jekyll site in 2026.

After you push the workflow, sanity-check three things in the Actions log:

- The `Build` step prints `Configuration file: _config.yml` and lists `jekyll-paginate-v2` among loaded plugins.
- `JEKYLL_ENV` shows `production`.
- `--baseurl /blog` is actually being passed (it'll be in the command line echo).

If the build still fails after the switch, the next-most-likely culprit is a hardcoded `/path/` somewhere in your layouts that worked at `localhost:4000/` but 404s under `/blog/`. Grep for `href="/` and `src="/` and pipe each through `relative_url`.
