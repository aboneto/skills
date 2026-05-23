# Troubleshooting

Diagnostic guide for the failure modes that eat the most time. Errors are listed roughly by frequency.

## "My post doesn't show up"

The #1 Jekyll question. Check, in order:

1. **Filename**: must be `YYYY-MM-DD-title.md` (or `.markdown`, `.html`). `2026-5-1-hello.md` (single-digit month/day) won't work on some setups — pad with zeros.
2. **Date in front matter is in the future.** `jekyll serve` excludes future posts by default. Run with `--future` or check today's date.
3. **`published: false`** in front matter. Remove it or use `--unpublished`.
4. **File is in `_drafts/`** (no date prefix). Use `--drafts` to preview.
5. **Front matter is malformed.** Missing `---`, tabs instead of spaces in YAML, or a stray colon in a title without quotes. Wrap titles with `:` in them: `title: "Why: a deep dive"`.
6. **File extension isn't recognized.** Markdown files need `.md` or `.markdown`. HTML posts need `.html`.
7. **File is in `exclude:`** in `_config.yml`.
8. **`encoding`** is wrong (BOM in the file). Re-save as UTF-8 without BOM, especially on Windows.

To verify the post is being processed:

```bash
bundle exec jekyll build --verbose 2>&1 | grep your-post
```

## Build errors

### `Liquid Exception: undefined method 'X' for nil`

Usually means a variable you're reading is nil — e.g. `{{ page.author.name }}` where `page.author` is unset. Defend with `default`:

```liquid
{{ page.author.name | default: site.author }}
```

Or check first:

```liquid
{% if page.author %}{{ page.author.name }}{% endif %}
```

Turn on `liquid.error_mode: strict` in `_config.yml` to make these errors more visible.

### `Liquid Warning: Liquid syntax error: Unknown tag 'X'`

You're using a plugin tag without the plugin loaded. Check:

1. The plugin is in `Gemfile` under `:jekyll_plugins`.
2. The plugin is in `_config.yml` under `plugins:`.
3. You ran `bundle install`.
4. You restarted `jekyll serve`.

### `Conversion error: Jekyll::Converters::Scss encountered an error while converting`

Sass is failing. Common causes:

- **`@import` deprecated**: Dart Sass is removing `@import` in favor of `@use`/`@forward`. Either migrate or pin: `gem "sass-embedded", "< 1.80"` in Gemfile.
- **Missing partial**: Sass looks in `_sass/` and the theme. The error message tells you which file. Run `bundle info MY_THEME --path` to inspect the theme's Sass.
- **Division warning treated as error**: `width: 100% / 3` no longer works. Use `width: math.div(100%, 3)` with `@use "sass:math";`.

### `Could not locate Gemfile or .bundle/ directory`

You're in the wrong directory, or `bundle` is looking globally. `cd` to the project root.

### `Your bundle is locked to X (=Y), but that version could not be found`

The lockfile references a version that's no longer on RubyGems (yanked, or never published).

```bash
bundle update GEM_NAME
# or, nuclear:
rm Gemfile.lock && bundle install
```

### `No such file or directory -- webrick (LoadError)`

Ruby 3 removed webrick from the standard library. Jekyll's dev server needs it.

```ruby
# Gemfile
gem "webrick", "~> 1.9"
```

Then `bundle install`.

### Build succeeds locally but fails on GitHub Pages

Allowlist issue. You're using a plugin or feature GitHub's classic builder doesn't support. Two paths:

1. Remove the offending plugin and stick with the allowlist.
2. Switch to GitHub Actions builds (see `references/deployment.md`). This is usually the right answer.

The build log in the Actions tab tells you exactly what failed.

## Style and content issues

### Page renders but layout is plain HTML

Front matter probably missing. Even an empty `---\n---` block triggers Liquid processing; without it, the file is copied verbatim.

For SCSS files, the front matter must be present (even empty) for Jekyll to compile them. `assets/css/main.scss` should start with:

```
---
---
@use "main";
```

### CSS works locally but is 404 in production

`baseurl` mismatch. If your site lives at `username.github.io/repo`, hardcoded `/css/main.css` will 404 — the real URL is `/repo/css/main.css`. Fix with `relative_url`:

```html
<link rel="stylesheet" href="{{ "/css/main.css" | relative_url }}">
```

### Markdown isn't rendering — I see literal `**bold**`

The file has wrong front matter or wrong extension. Markdown is only rendered in `.md` files with front matter. If you have a Markdown snippet in a `.html` file, force conversion:

```liquid
{{ "**hello**" | markdownify }}
```

### Code blocks have no syntax highlighting

Check:
- `highlighter: rouge` in `_config.yml`.
- Theme includes a Rouge stylesheet — Rouge generates classed HTML, you provide the colors. Run `rougify style monokai > assets/css/syntax.css` to generate one, then `@import` it.
- For fenced code blocks (` ```ruby `), the language tag must be on the same line as the opening backticks.

### Images broken in dev but fine in production (or vice versa)

Same `baseurl` story. Always `{{ "/path/to/image.png" | relative_url }}` for in-site images, never hardcoded `<img src="/path/to/image.png">`.

## Performance issues

### `jekyll serve` is slow to reload

- Use `--incremental`.
- Cache static includes with `include_cached`.
- Reduce image processing — pre-optimize images instead of generating responsive variants on every build.
- Profile with `--profile` and attack the slowest renderers first.

### Live reload doesn't fire

- `--livereload` flag set?
- Browser allows mixed content? Live reload uses a separate WebSocket connection.
- Firewall blocking port 35729?

## Environment quirks

### Windows: encoding issues, file watcher problems

- Set `chcp 65001` in the terminal before running Jekyll, to force UTF-8.
- Add `gem "wdm", "~> 0.1"` to Gemfile for native file watching.
- Or run Jekyll inside WSL2 — it's smoother for almost everything.

### macOS: `bundle install` fails on `nokogiri`

```bash
brew install libxml2 libxslt
bundle config build.nokogiri --use-system-libraries
bundle install
```

Recent nokogiri versions ship native binaries and avoid this — make sure you're on a current version.

### CI: jekyll-last-modified-at returns wrong dates

You're doing a shallow clone. Set `fetch-depth: 0` in the checkout step so the full git history is available.

## Diagnostic commands

```bash
# Show what plugins are loaded
bundle exec jekyll doctor

# Verbose build
bundle exec jekyll build --verbose

# Show timing per template
bundle exec jekyll build --profile

# Check which version of a gem is actually loaded
bundle info jekyll
bundle info jekyll-seo-tag

# Where's a gem installed?
bundle info jekyll --path

# Clean caches and rebuild
bundle exec jekyll clean && bundle exec jekyll build

# Strict Liquid: turn typos into errors
# in _config.yml:
#   liquid:
#     error_mode: strict
#     strict_filters: true
```

## When stuck: minimal reproduction

If you've spent more than 30 minutes on something, build a minimal repro:

1. `jekyll new isolate-bug && cd isolate-bug`
2. Add only the plugin / config / template you suspect.
3. If the bug reproduces, you've isolated it — file an issue with this minimal case.
4. If it doesn't, the bug is in interaction with something else in your real site; bisect by removing pieces.

This sounds heavy but is faster than reading through GitHub issues hoping one matches your situation.

## Where to ask

- <https://talk.jekyllrb.com/> — official forum, actively answered
- <https://stackoverflow.com/questions/tagged/jekyll>
- GitHub issues on the specific plugin or theme repo — for plugin-specific bugs only, not general questions
