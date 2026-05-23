# Jekyll Docs Site Setup Guide

## Files Created

### 1. Gemfile
```ruby
source "https://rubygems.org"
ruby ">= 3.4.0"

gem "jekyll", "~> 4.4"
gem "jekyll-sitemap"
gem "jekyll-seo-tag"
gem "jekyll-remote-theme"
gem "github-pages", "~> 232"

group :test do
  gem "html-proofer", "~> 5.0"
end
```

### 2. _config.yml
Uses **minimal-mistakes** theme (GitHub's recommended theme for Pages) with:
- Auto light/dark mode skin switching
- Sidebar navigation defined in `navigation:` key
- Proper defaults for `_docs` collection (single layout with sidebar)

### 3. .github/workflows/jekyll.yml
Three-job pipeline:
1. **build** - Builds Jekyll site, uploads Pages artifact
2. **html-proofer** - Downloads artifact, runs broken link checks, fails build on errors
3. **deploy** - Runs only on main push, depends on html-proofer passing

**Critical html-proofer flags:**
- `--disable-external` - Only checks internal links
- `--internal-domains` - Allows internal URLs on 127.0.0.1/localhost
- `--allow-hash-href` - Allows fragment-only links like `#anchor`

## Setup Commands
```bash
bundle install
bundle exec jekyll serve --livereload
```

## Notes
- About 40 pages: organize in `_docs/` collection with `permalink: /docs/:slug/` in front matter
- Light/dark toggle: minima skin set to `auto` with dark mode override via `dark_mode_skin: dark`
- html-proofer runs in CI **before** deploy, ensuring no broken links reach production