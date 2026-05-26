# Themes — installing, overriding, and building your own

Jekyll's theme system is one of its strongest selling points and one of its most confusing. This file walks through it end to end: installing a gem-based theme, overriding parts you don't like, switching to `remote_theme:`, and building a distributable theme of your own.

## Table of contents

1. [How Jekyll themes actually work](#how-jekyll-themes-actually-work)
2. [Installing a gem-based theme](#installing-a-gem-based-theme)
3. [Overriding theme files (ejecting)](#overriding-theme-files-ejecting)
4. [`remote_theme:` — GitHub Pages workaround](#remote_theme--github-pages-workaround)
5. [Customizing CSS without forking](#customizing-css-without-forking)
6. [Switching themes (without breaking everything)](#switching-themes-without-breaking-everything)
7. [Theme-specific config keys](#theme-specific-config-keys)
8. [Building a distributable theme gem](#building-a-distributable-theme-gem)
9. [Publishing your theme](#publishing-your-theme)
10. [Picking a theme in 2026](#picking-a-theme-in-2026)

---

## How Jekyll themes actually work

A Jekyll theme is just a **Ruby gem** that ships these directories:

```
my-theme-1.0.0/
├── _layouts/      # default.html, post.html, page.html
├── _includes/     # head.html, header.html, footer.html
├── _sass/         # SASS partials, imported from assets/css/...
├── assets/        # CSS/JS/images
├── _data/         # optional default data
└── my-theme.gemspec
```

At build time, Jekyll loads the gem and treats its files as if they lived in your site, **but with one rule**: any file you put in your own site overrides the matching theme file. That's it. That's the whole mechanism.

This means:

- You inherit everything by default.
- You can replace any single file by creating it in your site at the same relative path.
- You never edit the gem's files directly. (Your edits would be lost on every `bundle update`.)

## Installing a gem-based theme

1. Pick a theme. Examples: `minima`, `just-the-docs`, `jekyll-theme-chirpy`.

2. Add to `Gemfile`:

   ```ruby
   gem "minima", "~> 2.5"
   ```

3. Reference in `_config.yml`:

   ```yaml
   theme: minima
   ```

4. `bundle install`.

5. Many themes need their plugins enabled. Check the theme's README — Minima needs:

   ```yaml
   plugins:
     - jekyll-feed
     - jekyll-seo-tag
   ```

6. `bundle exec jekyll serve`.

If the theme doesn't appear to be loading, do `bundle exec jekyll doctor` — it lists which theme is detected and what's missing.

## Overriding theme files (ejecting)

To customize, find the theme's file on disk and copy it into your site:

```bash
bundle info --path minima            # prints e.g. /Users/me/.gem/.../minima-2.5.1
ls $(bundle info --path minima)
# _includes/  _layouts/  _sass/  assets/  LICENSE.txt  README.md
```

Copy the file you want to change:

```bash
cp $(bundle info --path minima)/_includes/header.html _includes/header.html
```

Now edit `_includes/header.html` in your site. Jekyll picks your copy ahead of the gem's.

**Rules of override:**

- **Path must match exactly.** `_includes/header.html` overrides `_includes/header.html`. Not `_includes/site-header.html`.
- **Whole-file override only.** No "merge". If you want to change one line, you copy the entire file.
- **Includes don't inherit through.** If you override `_includes/header.html` and it references `{% include nav.html %}`, that still picks up the theme's `nav.html` unless you override that too.
- **SASS partials live in `_sass/`.** Override one, the rest still come from the theme.
- **`assets/`** files override too: drop `assets/css/main.scss` in your site to fully replace the theme's stylesheet.

### Discovering what to override

```bash
# List every file the theme exposes
ls -la $(bundle info --path minima)
ls -la $(bundle info --path minima)/_includes/
ls -la $(bundle info --path minima)/_layouts/
ls -la $(bundle info --path minima)/_sass/
```

Then pick what you want to change and copy it locally.

### Common overrides

- `_includes/head.html` — add custom `<meta>`, fonts, scripts
- `_includes/header.html` or `navigation.html` — change the nav
- `_includes/footer.html` — change copyright, links
- `_layouts/post.html` — change post structure (add author byline, read time, share buttons)
- `_sass/minima.scss` (or the theme's main partial) — adjust variables before imports

## `remote_theme:` — GitHub Pages workaround

> **Security warning:** `remote_theme` pulls and executes theme code (layouts, includes, plugins) from a remote GitHub repo at build time. A compromised or malicious theme repo could inject arbitrary content into your site. Always pin to a specific tag or commit hash, and audit the theme's source before using it. Avoid unpinned `remote_theme` references in production.

If you're on GitHub Pages' classic builder and want a theme that *isn't* in the supported themes list (the classic builder only supports a small list: Minima, Cayman, Architect, etc.), the escape hatch is `remote_theme`.

```yaml
# _config.yml
remote_theme: pmarsceill/just-the-docs

plugins:
  - jekyll-remote-theme
```

```ruby
# Gemfile
gem "jekyll-remote-theme"
```

This pulls the theme directly from GitHub at build time. It's how Just the Docs, Hydejack, al-folio, and many others get used on GitHub Pages classic.

Caveats:
- Requires a public GitHub repo (or PAT for private — fiddly).
- Pinning is `user/repo@branch` or `user/repo@tag`. Without a pin you get the latest commit on the default branch and can break unpredictably.
- Slow first build (clones the theme).

Example pinned:

```yaml
remote_theme: pmarsceill/just-the-docs@v0.10.1
```

## Customizing CSS without forking

Many themes have a SASS pattern where their main file imports a partial — you can override the partial with a thin wrapper that sets variables and then re-imports the theme's actual SCSS.

Example for Minima:

```scss
// _sass/minima/_variables.scss (your override)
$brand-color:     #0a84ff;
$brand-color-light: #66b3ff;
$text-color:      #1a1a1a;
$background-color: #ffffff;
```

```scss
// assets/css/main.scss (your file, full override of theme's)
---
---
@import "minima";
```

Front matter `---\n---` is mandatory — without it Jekyll won't compile SCSS.

Read the theme's `_sass/<theme>/_variables.scss` to learn which knobs it exposes.

## Switching themes (without breaking everything)

Themes don't share conventions. Switching means:

1. Change `theme:` in `_config.yml`.
2. Update `plugins:` to match the new theme's required plugins.
3. Delete or update your overridden `_includes/`, `_layouts/`, `_sass/`, and `assets/css/main.scss` — old overrides will reference the *old* theme's includes/sass and break.
4. Update your front matter to match the new theme's expected keys (e.g., `layout: post` vs `layout: single`).
5. Audit your posts for theme-specific Liquid (`{% picture %}`, `{% include theme-tag.html %}`, etc.).
6. Rebuild from clean: `bundle exec jekyll clean && bundle exec jekyll build`.

If you maintain a side branch with the new theme during the migration, the switch is much less painful.

## Theme-specific config keys

Each theme reads its own keys from `_config.yml`. There's no universal list — check the README. A few common patterns:

```yaml
# Minimal Mistakes
minimal_mistakes_skin: "dark"
search: true
breadcrumbs: true

# Just the Docs
color_scheme: dark
search_enabled: true
aux_links:
  "GitHub":
    - "https://github.com/user/repo"

# Chirpy
theme_mode:                    # follow OS / "light" / "dark"
img_cdn:                       # asset CDN base URL
avatar:                        # path to author avatar

# al-folio
profile:
  align: right
  image: prof_pic.jpg
news: true
selected_papers: true
```

The theme's docs are the source of truth — bookmark them.

## Building a distributable theme gem

If you want others to install your theme via `gem "my-theme"`, follow this layout:

```bash
jekyll new-theme my-jekyll-theme
cd my-jekyll-theme
```

This scaffolds:

```
my-jekyll-theme/
├── _layouts/
├── _includes/
├── _sass/
├── assets/
├── LICENSE.txt
├── README.md
├── Gemfile
├── my-jekyll-theme.gemspec
└── _config.yml          # for local theme development
```

Key gemspec fields:

```ruby
# my-jekyll-theme.gemspec
Gem::Specification.new do |spec|
  spec.name          = "my-jekyll-theme"
  spec.version       = "0.1.0"
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "A clean blog theme for Jekyll."
  spec.homepage      = "https://github.com/you/my-jekyll-theme"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").select do |f|
    f.match(%r!^(assets|_layouts|_includes|_sass|LICENSE|README|_config\.yml)!i)
  end

  spec.add_runtime_dependency "jekyll", "~> 4.4"
  spec.add_runtime_dependency "jekyll-seo-tag", "~> 2.8"
end
```

The `spec.files` selector is what excludes `_site/`, demo posts, etc. from your published gem.

### Testing your theme locally

Inside the theme directory, the `_config.yml` and a demo `index.md` let you run `bundle exec jekyll serve` against the theme as if it were a site. Iterate on layouts and includes there.

To test consumption from another project:

```ruby
# in the consumer site's Gemfile
gem "my-jekyll-theme", path: "../my-jekyll-theme"
```

## Publishing your theme

```bash
gem build my-jekyll-theme.gemspec
gem push my-jekyll-theme-0.1.0.gem
```

You need an account on <https://rubygems.org>. After this:

```bash
gem search my-jekyll-theme
```

Users install with `gem "my-jekyll-theme"` and `theme: my-jekyll-theme`.

## Picking a theme in 2026

| Theme | Best for | Maintenance |
|---|---|---|
| [Minima](https://github.com/jekyll/minima) | Personal blog, default starting point | Official, slow updates |
| [Just the Docs](https://just-the-docs.com/) | Documentation, sidebar nav, search | Actively maintained |
| [Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) | Modern blog (TOC, dark mode, search) | Actively maintained, opinionated |
| [Hydejack](https://hydejack.com/) | Personal/portfolio, polished | Active |
| [Minimal Mistakes](https://github.com/mmistakes/minimal-mistakes) | Configurable, heavy | Active |
| [al-folio](https://github.com/alshedivat/al-folio) | Academic profile (publications, CV) | Active |
| [Jekyll Now](https://github.com/barryclark/jekyll-now) | Beginner-friendly fork-and-edit | Largely unmaintained — avoid for new sites |

**Picking criteria:**

1. **Has commits in the last 6 months.** Otherwise expect Sass/Ruby breakage soon.
2. **Issues are answered.** Lurking for a day in the issue tracker tells you the maintainer's pace.
3. **Documentation matches your site type.** Don't pick a docs theme for a blog.
4. **Looks the way you want by default.** Heavy customization of someone else's theme is usually slower than starting from Minima and adding what you need.

## Troubleshooting

- **"Theme not found"**: gem isn't installed (`bundle install`) or `theme:` value doesn't match gem name exactly.
- **CSS missing in production**: probably hardcoded path. Pass through `relative_url`.
- **Override "not working"**: check the exact path — `_includes/footer.html` vs `_includes/site-footer.html`. Themes use different filenames.
- **Sass errors after `bundle update`**: theme bumped its Sass version. Pin `sass-embedded` or migrate `@import` → `@use`.
- **`remote_theme:` builds locally but fails on CI**: missing `gem "jekyll-remote-theme"` in your CI Gemfile, or theme repo went private.

## Further reading

- Official theme docs: <https://jekyllrb.com/docs/themes/>
- Building a theme (Jekyll docs): <https://jekyllrb.com/docs/themes/#creating-a-gem-based-theme>
- `jekyll-remote-theme`: <https://github.com/benbalter/jekyll-remote-theme>
- Browse themes: <https://jekyll-themes.com/> and <https://github.com/topics/jekyll-theme>
