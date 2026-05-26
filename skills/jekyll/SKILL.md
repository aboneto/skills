---
name: jekyll
description: Technical cheatsheet for Jekyll static site generator. Use when working with Liquid templates (`{% if %}`, `{% for %}`, `{{ }}`), kramdown Markdown, `_config.yml`, collections, themes (Minima, Just the Docs, Chirpy), any `jekyll-*` plugin, GitHub Pages/Actions deployment, `Gemfile`/Ruby setup, responsive images, html-proofer, or custom plugins/filters. Trigger when user mentions `_posts/`, `_layouts/`, `_includes/`, `bundle exec jekyll`, GitHub Pages build failing, Liquid syntax errors, or kramdown `{:.class}` syntax — even without saying "Jekyll" explicitly.
license: MIT
metadata:
  author: aboneto
  version: "1.0.1"
---

# jekyll

A compact reference for working productively with Jekyll. The body below is the high-frequency stuff you need every day. For deeper dives, read the matching file under `references/` — pointers are given in each section.

---

## When to reach for which reference file

| If the user is doing this... | Read this file |
|---|---|
| Installing, picking a Ruby version, fixing `bundle install` errors, `.ruby-version`, safe mode, host/port, upgrading Jekyll | `references/setup.md` |
| Anything inside `{% %}` or `{{ }}` — filters, tags, loops, conditionals | `references/liquid.md` |
| Configuring `_config.yml`, defaults, permalinks, collections, data files | `references/configuration.md` |
| Markdown syntax: IALs `{:.class}`, footnotes, definition lists, TOC, kramdown vs GFM, math notation | `references/kramdown.md` |
| Choosing or installing a plugin, configuring `jekyll-seo-tag`, paginating, redirects | `references/plugins.md` |
| Installing a theme, ejecting/overriding theme files, `remote_theme`, building your own theme gem | `references/themes.md` |
| Responsive images, WebP/AVIF, lazy loading, asset fingerprinting / cache busting, math (MathJax/KaTeX), diagrams (Mermaid) | `references/images.md` |
| Adding comments to a static site (giscus, utterances, Cusdis, Staticman, webmentions) | `references/comments.md` |
| html-proofer, Lighthouse CI, pa11y, markdownlint, spell-check, CI workflows for static-site sanity | `references/testing.md` |
| Deploying to GitHub Pages, Netlify, custom domains, GitHub Actions builds | `references/deployment.md` |
| Build errors, "post not showing", future-dated posts, encoding issues | `references/troubleshooting.md` |
| Writing a custom plugin/filter/tag/generator/hook, building a distributable theme, i18n with polyglot, Tailwind/esbuild pipelines, JSON/PDF/AMP outputs, profiling slow builds | `references/advanced.md` |

Ready-to-use starter files live in `assets/`:
- `assets/Gemfile` — pinned versions known to work together (Jekyll 4.4.x)
- `assets/_config.yml` — sensible defaults with the standard plugin set
- `assets/github-pages.Gemfile` — for sites that must build on GitHub Pages' allowlist (stuck on Jekyll 3.10.x)

---

## Versions you should know (as of 2026)

- **Jekyll 4.4.x** is current. Use it for any new site you deploy yourself (Netlify, Cloudflare Pages, GitHub Actions).
- **Jekyll 3.10.x** is what GitHub Pages' classic build still uses. If you push your source and let GitHub Pages build it, you are pinned here and limited to the [plugin allowlist](https://pages.github.com/versions/).
- **Ruby 3.4.x is the default** in 2026. Earlier 3.x lines (3.1–3.3) have known incompatibilities with several maintained plugins, so use 3.4 unless something forces you lower. Jekyll 4.4 technically supports 3.1+, but don't pick the floor on purpose. macOS system Ruby is too old — use `rbenv`, `asdf`, or `mise`.
- **Bundler 2.x** for Gemfile management. Always commit `Gemfile.lock`.

If the user is on GitHub Pages and frustrated by version limits, the modern answer is to build with **GitHub Actions** and deploy the `_site` output to Pages — that unlocks current Jekyll plus arbitrary plugins. See `references/deployment.md`.

---

## The mental model in one minute

Jekyll takes a folder of Markdown + HTML + Liquid templates and produces a folder of static HTML (`_site/`). The pipeline is:

1. Read `_config.yml` → site-wide settings + `site.*` variables.
2. Read every file. If it starts with YAML front matter (`---\n...\n---`), Jekyll processes it; otherwise it copies it verbatim.
3. Convert Markdown → HTML, run Liquid (`{{ }}` for output, `{% %}` for logic), wrap in the layout named in front matter.
4. Posts in `_posts/` get auto-discovered if filename matches `YYYY-MM-DD-title.md`.
5. Write everything to `_site/`. That folder is your deployable artifact.

Common mental traps:
- `_config.yml` changes are **not** picked up by `jekyll serve` automatically. Restart the server.
- A post dated in the future will silently not appear. Use `jekyll serve --future` to preview.
- A post in draft (`_drafts/`) needs `jekyll serve --drafts`.
- Files starting with `_`, `.`, or `#` are excluded by default unless declared as a collection or whitelisted.

---

## Standard directory layout

```
my-site/
├── _config.yml          # site-wide config
├── Gemfile              # Ruby dependencies
├── Gemfile.lock         # commit this
├── _posts/              # blog posts: YYYY-MM-DD-title.md
│   └── 2026-05-01-hello.md
├── _drafts/             # unpublished posts (no date in filename)
├── _layouts/            # HTML wrappers (default.html, post.html, ...)
├── _includes/           # reusable partials, used via {% include header.html %}
├── _data/               # YAML/JSON/CSV → site.data.*
│   └── navigation.yml
├── _sass/               # Sass partials, imported from assets/css/main.scss
├── assets/              # CSS, JS, images — copied as-is
│   └── css/main.scss
├── _site/               # build output (gitignore this)
└── index.md             # homepage
```

Everything starting with `_` is "internal" to Jekyll. Custom collections (`_projects/`, `_docs/`) require a `collections:` block in `_config.yml`.

---

## The 80% you'll write every day

### Front matter on a post

```yaml
---
layout: post
title: "Why Jekyll still wins"
date: 2026-05-01 09:00:00 +0100
categories: [meta]
tags: [jekyll, static-sites]
excerpt: "A short summary used in the listing page."
---
```

`date` overrides the filename date. Timezone offset matters for "future post" issues.

### A minimal `_config.yml`

```yaml
title: My Site
description: A short description used by jekyll-seo-tag
url: "https://example.com"
baseurl: ""                  # subpath if hosted at example.com/blog
markdown: kramdown
permalink: /:year/:month/:slug/

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-sitemap

# Don't repeat layout: post in every file
defaults:
  - scope: { path: "", type: "posts" }
    values:
      layout: post
      author: "Site Author"
```

### The Liquid you reach for constantly

```liquid
{%- comment -%} loop posts {%- endcomment -%}
{% for post in site.posts limit:5 %}
  <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
  <time>{{ post.date | date: "%B %-d, %Y" }}</time>
{% endfor %}

{%- comment -%} conditional {%- endcomment -%}
{% if page.tags contains "featured" %}<span>★</span>{% endif %}

{%- comment -%} include a partial with parameters {%- endcomment -%}
{% include button.html label="Subscribe" url="/feed.xml" %}

{%- comment -%} absolute URL (use this in feeds, OG tags) {%- endcomment -%}
{{ "/about/" | absolute_url }}

{%- comment -%} relative URL (use this in normal links) — respects baseurl {%- endcomment -%}
{{ "/about/" | relative_url }}
```

> Liquid has no `{# … #}` syntax — only `{% comment %}…{% endcomment %}` blocks (or `{%- # short -%}` on Liquid 5.4+). Copy-pasting `{# … #}` will either render literally or fail the build.

Pitfall: never hardcode `<a href="/about/">`. Always pipe through `relative_url` so the site works under a `baseurl`.

### Local dev commands

```bash
bundle exec jekyll serve              # http://localhost:4000, auto-rebuild
bundle exec jekyll serve --livereload # also refresh the browser
bundle exec jekyll serve --drafts --future --unpublished  # show everything
bundle exec jekyll build              # one-shot, writes _site/
bundle exec jekyll clean              # nuke _site/ and caches
JEKYLL_ENV=production bundle exec jekyll build  # production mode (enables analytics, etc.)
```

`JEKYLL_ENV=production` is what flips themes from "dev" to "live" — e.g. it's what makes `jekyll-seo-tag` emit the production analytics ID. Always set it in CI.

---

## The plugins almost every site should have

The six below pull their weight on almost every site. The first four are on GitHub Pages' allowlist; `jekyll-paginate-v2` and `jekyll-include-cache` are not, so they require a self-controlled build (GitHub Actions, Netlify, etc.).

| Plugin | What it does |
|---|---|
| `jekyll-feed` | Generates `/feed.xml` Atom feed |
| `jekyll-seo-tag` | Adds `<title>`, OpenGraph, Twitter Card, JSON-LD meta tags. Just put `{% seo %}` in `<head>` |
| `jekyll-sitemap` | Generates `/sitemap.xml` automatically |
| `jekyll-redirect-from` | Add `redirect_from: ["/old-path/"]` in front matter to keep old URLs alive |
| `jekyll-paginate-v2` | Real pagination across categories/tags (the old `jekyll-paginate` is anemic — but `-v2` is **not** on the GitHub Pages allowlist) |
| `jekyll-include-cache` | Enables `{% include_cached %}` — 3-5× build speedup once you have many posts. Not on the GH Pages allowlist. |

Add them to **both** `Gemfile` (under the `:jekyll_plugins` group) **and** `_config.yml` under `plugins:`. Many bugs start with adding to only one place.

See `references/plugins.md` for full configuration snippets and the difference between official and third-party plugins. To **write** a plugin of your own (custom filter, tag, generator, hook, converter, or full gem) or to **package a distributable theme**, see `references/advanced.md`.

---

## Quick troubleshooting decision tree

- **"My post doesn't show up"** → Check date (future?), filename (`YYYY-MM-DD-title.md`?), `published: false` in front matter?, run with `--future --drafts`.
- **`bundle install` fails on macOS** → System Ruby is too old. Install rbenv: `brew install rbenv && rbenv install 3.4.8`.
- **`No such file or directory -- webrick`** → Ruby 3+ dropped webrick. Add `gem "webrick", "~> 1.9"` to Gemfile.
- **GitHub Pages build fails after working locally** → You're using a plugin not on the [allowlist](https://pages.github.com/versions/). Switch to GitHub Actions deployment (see `references/deployment.md`).
- **Sass deprecation warnings flood the console** → Theme is old. Either upgrade the theme, pin Sass: `gem "sass-embedded", "< 1.80"`, or migrate `@import` → `@use` per the theme's migration guide.

Full list in `references/troubleshooting.md`.

---

## How to use this skill

When the user asks a Jekyll question:

1. Look at the table at the top and open the matching `references/*.md` for depth. Most user questions live in one of those seven files.
2. If the user is starting fresh, point them at `assets/Gemfile` and `assets/_config.yml` — copying these saves 20 minutes of trial and error.
3. Prefer giving them the working code snippet over abstract explanation. Jekyll is a "show, don't tell" tool.
4. Always check: are they on GitHub Pages' classic builder or building themselves? It changes which plugins they can use and which Jekyll version applies.
5. Mention `JEKYLL_ENV=production` whenever the answer involves analytics, SEO tags, or anything that should differ between dev and prod.

---

## Useful external links (verified live as of 2026)

- Official docs: <https://jekyllrb.com/docs/>
- Liquid reference (Shopify): <https://shopify.github.io/liquid/>
- GitHub Pages dependency versions: <https://pages.github.com/versions/>
- CloudCannon's cheatsheet (good complement): <https://cloudcannon.com/cheat-sheets/jekyll/>
- Awesome Jekyll plugins: <https://github.com/planetjekyll/awesome-jekyll-plugins>
- Jekyll Talk (community Q&A): <https://talk.jekyllrb.com/>
