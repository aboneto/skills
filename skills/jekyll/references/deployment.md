# Deployment

The output of a Jekyll build is just static HTML in `_site/`. You can host that anywhere. This file covers the main routes and the specific traps each one has.

## The big choice up front

| Route | Best for | Limits |
|---|---|---|
| **GitHub Pages classic** (push source, GitHub builds) | Personal blogs, beginners | Stuck on Jekyll 3.10.x; plugin allowlist; no custom build steps |
| **GitHub Pages via GitHub Actions** | Anyone outgrowing the above | Current Jekyll, any plugin, custom build, all free on public repos |
| **Netlify / Cloudflare Pages / Vercel** | Want previews, custom build commands, edge functions | None for static Jekyll. All have free tiers. |
| **Self-host on S3/CDN/your VPS** | Full control | You operate it |

In 2026 the default recommendation is **GitHub Actions building to GitHub Pages**. You keep the free hosting and stop fighting the classic builder's restrictions.

---

## Option 1: GitHub Pages classic (the easy mode)

For sites that fit inside the allowlist:

1. Use the `github-pages` gem in your Gemfile:

   ```ruby
   source "https://rubygems.org"
   gem "github-pages", group: :jekyll_plugins
   gem "webrick", "~> 1.9"
   ```

2. In your repo: **Settings → Pages → Build and deployment → Source: Deploy from a branch → `main` / `/(root)`**.

3. Push. GitHub builds and deploys.

That's it. Caveats:

- You're on Jekyll 3.10.x. Several Jekyll 4 features (e.g. `find` filter, `where_exp` improvements) don't exist.
- Plugins are limited to the [allowlist](https://pages.github.com/versions/).
- You cannot run pre- or post-build scripts. No Pagefind, no Tailwind compile step, no nothing.
- Custom `_plugins/` directories are ignored.

If any of these bite, jump to Option 2.

## Option 2: GitHub Pages via GitHub Actions (the modern default)

You build the site yourself in CI and upload the result to Pages. No allowlist, current Jekyll, custom steps.

1. In your repo: **Settings → Pages → Build and deployment → Source: GitHub Actions**.

2. Create `.github/workflows/jekyll.yml`:

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
             fetch-depth: 0       # needed for jekyll-last-modified-at

         - uses: ruby/setup-ruby@v1
           with:
             ruby-version: '3.4'
             bundler-cache: true   # caches gems between runs

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

3. Use the modern Gemfile (`assets/Gemfile`), not the `github-pages` gem.

4. Push. The first deploy takes a couple of minutes; subsequent ones cache gems and are fast.

This unlocks:
- Current Jekyll (4.4.x)
- Any plugin
- Pre- and post-build steps (Tailwind, Pagefind, image optimization)
- Custom `_plugins/` Ruby code
- Different builds per branch (preview deploys with extra workflow steps)

`JEKYLL_ENV: production` is essential. Without it, jekyll-seo-tag and many themes emit dev placeholders instead of real analytics IDs.

## Option 3: Netlify

Netlify gives you previews per PR, easy custom build commands, form handling, and a CLI.

1. Create `netlify.toml`:

   ```toml
   [build]
     command = "bundle exec jekyll build"
     publish = "_site"

   [build.environment]
     JEKYLL_ENV = "production"
     RUBY_VERSION = "3.4.8"
   ```

2. Connect the repo in Netlify's dashboard.

3. Done. Every push builds, every PR gets a preview URL.

Netlify-specific niceties:
- `_redirects` file (in your repo root or `assets/`) handles redirects without a plugin.
- `_headers` file sets HTTP headers per path (CSP, caching).
- `[[redirects]]` in `netlify.toml` for more complex rules.

Cloudflare Pages and Vercel work essentially the same way with their own config file.

## Custom domains

The same idea everywhere: point DNS at the host, configure the host to expect that hostname.

### GitHub Pages

1. In your repo, create a `CNAME` file at the root containing just the bare domain:

   ```
   blog.example.com
   ```

2. DNS:
   - For an apex (`example.com`): four A records pointing at GitHub's IPs (currently 185.199.108.153, .109.153, .110.153, .111.153 — check [docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)).
   - For a subdomain: a CNAME record pointing to `USER.github.io`.

3. In **Settings → Pages → Custom domain**, enter the same value. Enable HTTPS once DNS propagates.

4. Set `url:` in `_config.yml` to `https://blog.example.com` and leave `baseurl: ""`.

### Netlify / Cloudflare Pages

DNS: CNAME the subdomain (or use Netlify DNS for apex). The dashboard walks you through it. HTTPS is automatic via Let's Encrypt.

## `url` and `baseurl` — the source of half the link bugs

These two keys in `_config.yml` are misunderstood constantly.

- **`url`**: full origin including scheme, no trailing slash. `https://example.com`. Used in feeds, sitemaps, and `absolute_url` filter.
- **`baseurl`**: subpath, with leading slash, no trailing slash. `""` if the site is at the domain root. `/blog` if it lives at `example.com/blog`.

Project sites on GitHub Pages live at `username.github.io/repo-name`, so `baseurl: /repo-name`. User/org sites at `username.github.io` have `baseurl: ""`.

In templates, always do:

```liquid
<a href="{{ "/about/" | relative_url }}">About</a>
<img src="{{ "/logo.png" | relative_url }}">
```

`relative_url` prepends `baseurl`. Hardcoded `/about/` works locally but breaks on `username.github.io/repo-name/`.

For absolute URLs (feeds, OG tags, canonical):

```liquid
<link rel="canonical" href="{{ page.url | absolute_url }}">
```

## Dev vs prod environment differences

You almost always want different behavior locally vs in production. Patterns:

### 1. `JEKYLL_ENV` check in templates

```liquid
{% if jekyll.environment == "production" %}
  <!-- Google Analytics -->
  <script async src="https://www.googletagmanager.com/gtag/js?id={{ site.google_analytics }}"></script>
{% endif %}
```

### 2. Layered config files

```yaml
# _config.yml (production)
url: https://example.com
google_analytics: G-XXXXXXX
```

```yaml
# _config.dev.yml
url: http://localhost:4000
google_analytics:
```

Run locally with `bundle exec jekyll serve --config _config.yml,_config.dev.yml`. CI uses just `_config.yml`.

### 3. Build flags

```bash
# dev
bundle exec jekyll serve --drafts --future --unpublished --livereload

# prod
JEKYLL_ENV=production bundle exec jekyll build
```

## Performance: when builds get slow

Symptoms: `jekyll build` takes >30 seconds on a small site, or `jekyll serve` lags between edits and reloads.

Things to try, in order of impact:

1. **`include_cached` for static includes.** Header, footer, sidebar — anything that doesn't depend on per-page variables. Often a 3-5x speedup on big sites.
2. **`--incremental` flag.** Rebuilds only changed files. Experimental, may produce stale output in some cases — fine for dev, not for production builds.
3. **Reduce image processing.** If you're using `jekyll-responsive-image` or similar, it's almost certainly the bottleneck. Cache its output (`_site/assets/cache/`) between builds.
4. **Profile with `--profile`.** Prints a per-file render time table. Tells you exactly which template is slow.

   ```bash
   bundle exec jekyll build --profile
   ```

5. **Disable Sass on every build during dev.** If you have a complex Sass pipeline, consider compiling CSS separately and treating it as a static asset.

6. **Drop unused plugins.** Every plugin adds load time even if you don't use its features.

For sites >2000 pages, Jekyll genuinely struggles. Either move to Hugo or split the site.

## Migrating away from GitHub Pages classic to Actions

The cleanest path:

1. Update `_config.yml` to remove the `github-pages` gem reference; switch `plugins:` to list each one explicitly.
2. Replace your Gemfile with the modern one (`assets/Gemfile`).
3. Add the workflow above.
4. Settings → Pages → switch source to "GitHub Actions".
5. Push to main. Watch the workflow run.

If something breaks, your fallback is reverting these changes and the site rebuilds from source as before.
