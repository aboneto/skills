# Testing, Link Checking, and CI Sanity

Static sites are deceptively easy to ship broken. Build succeeds → file uploads → some link is 404 / image is missing alt text / page bundles a megabyte of JS, and you don't find out until a reader emails you. This file covers the automated checks that catch these in CI.

## Table of contents

1. [The minimum viable check](#the-minimum-viable-check)
2. [html-proofer (link, HTML, image, anchor checks)](#html-proofer-link-html-image-anchor-checks)
3. [Pa11y / axe — accessibility](#pa11y--axe--accessibility)
4. [Lighthouse CI — performance, SEO, best practices](#lighthouse-ci--performance-seo-best-practices)
5. [Markdown linting](#markdown-linting)
6. [Spell checking](#spell-checking)
7. [Putting it together: one GH Actions workflow](#putting-it-together-one-gh-actions-workflow)
8. [Things you don't need to test](#things-you-dont-need-to-test)

---

## The minimum viable check

Even on a small personal blog, run **html-proofer** in CI. It catches roughly 80% of "site is broken" problems for ~30 seconds of CI time. Everything else below is incremental polish.

## html-proofer (link, HTML, image, anchor checks)

The most-used Jekyll testing tool. Scans `_site/` after a build for:

- Broken internal and external links (404s)
- Missing referenced images / scripts / stylesheets
- Anchors that point to nonexistent `#ids` on the same page
- Malformed HTML
- Images without `alt` attributes
- Mixed-content links (HTTP referenced from HTTPS)

```ruby
# Gemfile (under :development or :test, not :jekyll_plugins)
group :test do
  gem "html-proofer", "~> 5.0"
end
```

Run it locally:

```bash
bundle exec jekyll build
bundle exec htmlproofer ./_site \
  --disable-external \
  --ignore-urls "/^http:\/\/localhost/" \
  --ignore-files "/api/" \
  --check-html
```

Common flags:

- `--disable-external`: skip outbound links (fast). Often the right default for PR checks; run external checks weekly via a scheduled job.
- `--check-html`: full HTML validation.
- `--check-favicon`: ensure each page references a favicon.
- `--enforce-https`: insist all external links use HTTPS.
- `--ignore-urls "PATTERN"`: regex of URLs to skip (LinkedIn, X, etc. tend to flake).
- `--ignore-files "PATTERN"`: skip whole files.
- `--allow-hash-href`: don't complain about `href="#"` (used by some JS triggers).

### GitHub Actions step

```yaml
- name: HTML proofer
  run: |
    bundle exec jekyll build
    bundle exec htmlproofer ./_site --disable-external --check-html
```

### Weekly external-link check

A scheduled run catches link rot without slowing down PRs:

```yaml
on:
  schedule:
    - cron: "0 9 * * 1"   # 09:00 UTC every Monday
  workflow_dispatch:

jobs:
  link-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.4', bundler-cache: true }
      - run: bundle exec jekyll build
      - run: bundle exec htmlproofer ./_site --enforce-https
```

Have it post failures to a Slack channel or open a GitHub issue automatically.

## Pa11y / axe — accessibility

Static-analysis accessibility checkers. Both run a headless browser, load each page, and assert against WCAG rules.

### Pa11y (single-page CLI)

```bash
npm install -g pa11y
pa11y http://localhost:4000/about/
```

For a whole site, **pa11y-ci** crawls a sitemap:

```bash
npm install -D pa11y-ci
```

```json
// .pa11yci
{
  "defaults": { "standard": "WCAG2AA", "timeout": 30000 },
  "urls": ["http://localhost:4000/sitemap.xml"]
}
```

In GH Actions:

```yaml
- run: bundle exec jekyll build
- run: bundle exec jekyll serve --detach
- run: npx pa11y-ci --sitemap http://localhost:4000/sitemap.xml
```

### axe-core

More accurate, used by browser devtools and by Lighthouse. For Jekyll: include it via lighthouse-ci (below) rather than running it standalone.

## Lighthouse CI — performance, SEO, best practices

Lighthouse runs a headless browser, measures Core Web Vitals (LCP, CLS, INP), and scores Performance / Accessibility / Best Practices / SEO. CI variant runs in GH Actions on every PR.

```yaml
- name: Build
  run: bundle exec jekyll build
- name: Serve
  run: |
    bundle exec jekyll serve --detach --skip-initial-build
    sleep 3
- name: Lighthouse
  uses: treosh/lighthouse-ci-action@v12
  with:
    urls: |
      http://localhost:4000/
      http://localhost:4000/about/
      http://localhost:4000/posts/latest/
    uploadArtifacts: true
    temporaryPublicStorage: true
```

Set budgets in `lighthouserc.json` to fail the build on regressions:

```json
{
  "ci": {
    "collect": { "numberOfRuns": 3 },
    "assert": {
      "assertions": {
        "categories:performance":   ["error", {"minScore": 0.9}],
        "categories:accessibility": ["error", {"minScore": 0.95}],
        "categories:seo":           ["error", {"minScore": 0.9}],
        "categories:best-practices":["warn",  {"minScore": 0.85}]
      }
    }
  }
}
```

Use a few-page sample. Lighthouse takes ~30s per run; testing every page is overkill.

## Markdown linting

Catch inconsistent style (heading hierarchy, list spacing, trailing whitespace) before they ship.

```bash
npm install -D markdownlint-cli2
```

`.markdownlint.json`:

```json
{
  "default": true,
  "MD013": false,   // line length
  "MD033": false,   // inline HTML (we use IALs and Liquid)
  "MD041": false    // first line must be H1 (we use front matter)
}
```

In CI:

```yaml
- run: npx markdownlint-cli2 "**/*.md" "#node_modules"
```

`.markdownlint-ignore`:

```
_site/
vendor/
```

## Spell checking

`cspell` is the practical choice — single binary, dictionaries per project.

```bash
npm install -D cspell
```

`cspell.json`:

```json
{
  "version": "0.2",
  "language": "en",
  "words": ["jekyll", "liquid", "kramdown", "rouge", "yourname"],
  "ignorePaths": ["_site/**", "vendor/**", "node_modules/**"]
}
```

In CI:

```yaml
- run: npx cspell '**/*.md'
```

Build up the project word list over time. Most "errors" the first run are technical terms and proper names — add them once.

## Putting it together: one GH Actions workflow

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: ruby/setup-ruby@v1
        with: { ruby-version: '3.4', bundler-cache: true }

      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci

      - name: Build
        run: bundle exec jekyll build
        env: { JEKYLL_ENV: production }

      - name: HTML proofer
        run: bundle exec htmlproofer ./_site --disable-external --check-html

      - name: Markdown lint
        run: npx markdownlint-cli2 "**/*.md" "#_site" "#node_modules"

      - name: Spell check
        run: npx cspell '**/*.md' --no-progress

      - name: Lighthouse
        if: github.event_name == 'pull_request'
        uses: treosh/lighthouse-ci-action@v12
        with:
          configPath: ./lighthouserc.json
          uploadArtifacts: true
```

External link checks run on a separate scheduled workflow (above).

## Things you don't need to test

- **Visual regressions on every PR.** Tools like Percy/Chromatic are useful but heavy. Add them only after you've been burned by a styling regression.
- **Cross-browser screenshots.** Browser parity for static HTML is generally fine in 2026.
- **Unit-testing Liquid templates.** Jekyll's build is the test. If `bundle exec jekyll build` produces the right HTML, the templates work.
- **Load testing static files.** Your CDN handles it.

## Local pre-commit hook

A lightweight `lefthook` or `pre-commit` setup that runs markdownlint + cspell on staged Markdown saves PR-time embarrassment.

```yaml
# lefthook.yml
pre-commit:
  parallel: true
  commands:
    markdown:
      glob: "**/*.md"
      run: npx markdownlint-cli2 {staged_files}
    spell:
      glob: "**/*.md"
      run: npx cspell {staged_files}
```

## Further reading

- html-proofer: <https://github.com/gjtorikian/html-proofer>
- pa11y-ci: <https://github.com/pa11y/pa11y-ci>
- Lighthouse CI: <https://github.com/GoogleChrome/lighthouse-ci>
- markdownlint rules: <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>
- cspell: <https://cspell.org/>
