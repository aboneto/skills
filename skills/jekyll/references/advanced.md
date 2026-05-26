# Advanced: Custom Plugins, Themes, and Power Features

This file is the next step beyond `references/plugins.md` (which lists plugins to *use*) and `references/configuration.md` (which covers stock features). Here we build our own plugins, publish themes as gems, and lean on Jekyll's lesser-known machinery.

## Table of contents

1. [The plugin taxonomy — pick the right kind](#the-plugin-taxonomy--pick-the-right-kind)
2. [Custom Liquid filters](#custom-liquid-filters)
3. [Custom Liquid tags](#custom-liquid-tags)
4. [Generators (create pages programmatically)](#generators-create-pages-programmatically)
5. [Hooks (fine-grained build lifecycle)](#hooks-fine-grained-build-lifecycle)
6. [Converters (support new markup languages)](#converters-support-new-markup-languages)
7. [Custom commands (extend the jekyll CLI)](#custom-commands-extend-the-jekyll-cli)
8. [Packaging a plugin as a gem](#packaging-a-plugin-as-a-gem)
9. [Internationalization (i18n) without external plugins](#internationalization-i18n-without-external-plugins)
10. [Asset pipelines: Tailwind, esbuild, image optimization](#asset-pipelines-tailwind-esbuild-image-optimization)
11. [Multi-output: PDFs, JSON APIs, AMP, RSS variants](#multi-output-pdfs-json-apis-amp-rss-variants)
12. [Remote data at build time](#remote-data-at-build-time)
13. [Profiling and large-site performance](#profiling-and-large-site-performance)

> For building and distributing a Jekyll **theme** as a gem (scaffold, gemspec, Sass packaging, `remote_theme:`), see [`themes.md`](themes.md). This file covers plugin gems only.

---

## The plugin taxonomy — pick the right kind

Before writing code, identify which of the six plugin types fits your task. Picking wrong leads to fighting the framework.

| You want to... | Use a... |
|---|---|
| Transform a value inside `{{ }}` | **Filter** |
| Add a new `{% something %}` tag | **Tag** |
| Generate one or many pages at build time (e.g. one page per author from `_data/authors.yml`) | **Generator** |
| Run code at specific moments in the build (modify content before/after render, write extra files, run external scripts) | **Hook** |
| Accept files in a new markup language (AsciiDoc, Org-mode, your own format) | **Converter** |
| Add a `jekyll mycommand` to the CLI | **Command** |

If you're tempted to use a hook for something that's "one page per data item", that's a generator job. If you're using a generator for "modify all posts on read", that's a hook job.

## Custom Liquid filters

The simplest plugin. A module of Ruby methods that Liquid can call after `|`.

Drop in `_plugins/reading_time.rb`:

```ruby
module Jekyll
  module ReadingTimeFilter
    def reading_time(input)
      words = input.to_s.split.length
      minutes = (words / 200.0).ceil
      minutes < 1 ? "less than a minute" : "#{minutes} min read"
    end

    def reading_time_minutes(input)
      ((input.to_s.split.length) / 200.0).ceil
    end
  end
end
Liquid::Template.register_filter(Jekyll::ReadingTimeFilter)
```

Use anywhere a Liquid expression is allowed:

```liquid
{{ page.content | reading_time }}              → 4 min read
{{ page.content | reading_time_minutes }}      → 4
```

Filters can take arguments after the input:

```ruby
def truncate_words(input, limit = 30, ellipsis = "…")
  words = input.to_s.split
  return input if words.length <= limit
  "#{words[0...limit].join(' ')}#{ellipsis}"
end
```

```liquid
{{ post.excerpt | strip_html | truncate_words: 40 }}
{{ post.excerpt | strip_html | truncate_words: 40, " (read more)" }}
```

**Accessing the site context inside a filter.** Filters don't have direct access to `site`, but you can reach it through `@context`:

```ruby
def absolute_with_cdn(input)
  site = @context.registers[:site]
  cdn = site.config["cdn_url"] || site.config["url"]
  "#{cdn}#{input}"
end
```

## Custom Liquid tags

Tags are richer than filters: they're a full block of Ruby that runs when Liquid hits `{% mytag %}`. Use them when the syntax `value | filter` doesn't fit (no input pipe, or you want a block form).

### A simple inline tag

`_plugins/youtube_tag.rb`:

```ruby
module Jekyll
  class YouTubeTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @video_id = text.strip
    end

    def render(context)
      <<~HTML
        <div class="youtube-embed">
          <iframe src="https://www.youtube-nocookie.com/embed/#{@video_id}"
                  loading="lazy"
                  allowfullscreen></iframe>
        </div>
      HTML
    end
  end
end
Liquid::Template.register_tag("youtube", Jekyll::YouTubeTag)
```

```liquid
{% youtube dQw4w9WgXcQ %}
```

### A block tag (with content inside)

```ruby
module Jekyll
  class CalloutBlock < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      @type = markup.strip.empty? ? "info" : markup.strip
    end

    def render(context)
      content = super  # the rendered inner content
      "<aside class=\"callout callout-#{@type}\">#{content}</aside>"
    end
  end
end
Liquid::Template.register_tag("callout", Jekyll::CalloutBlock)
```

```liquid
{% callout warning %}
This is **important** — markdown still renders inside.
{% endcallout %}
```

Pattern note: a block tag inherits from `Liquid::Block` (not `Liquid::Tag`), and `super` inside `render` gives you the already-rendered children.

## Generators (create pages programmatically)

Use case: turn `_data/authors.yml` into one `/authors/jane/` page per author. Or scan posts and generate `/topics/<topic>/` index pages. Anything where you need N pages from a non-file source.

`_plugins/author_pages.rb`:

```ruby
module Jekyll
  class AuthorPageGenerator < Generator
    safe true               # mark plugin safe for GitHub Pages (does nothing for custom plugins, but a good habit)
    priority :normal        # :lowest, :low, :normal, :high, :highest

    def generate(site)
      authors = site.data["authors"] || {}
      authors.each do |username, data|
        site.pages << AuthorPage.new(site, site.source, username, data)
      end
    end
  end

  class AuthorPage < Page
    def initialize(site, base, username, data)
      @site = site
      @base = base
      @dir  = File.join("authors", username)
      @name = "index.html"

      process(@name)
      read_yaml(File.join(base, "_layouts"), "author.html")  # uses _layouts/author.html

      self.data["title"]    = data["name"]
      self.data["username"] = username
      self.data["bio"]      = data["bio"]
      self.data["posts"]    = site.posts.docs.select { |p| p.data["author"] == username }
    end
  end
end
```

Now `_data/authors.yml`:

```yaml
jane:
  name: Jane Doe
  bio: Writes about distributed systems.
john:
  name: John Smith
  bio: Loves Liquid.
```

…produces `/authors/jane/` and `/authors/john/` at build time, each rendered through `_layouts/author.html` with `page.title`, `page.username`, `page.bio`, `page.posts` available.

**When to prefer a generator over a collection.** A collection requires one file per item; a generator works from any source (YAML, JSON, an API response, a database export). If your data is structured but file-less, generator is the right tool.

## Hooks (fine-grained build lifecycle)

Hooks let you run code at specific moments. The full taxonomy:

| Owner | Event | When it fires |
|---|---|---|
| `:site` | `:after_init` | Right after site object initializes (good for config tweaks) |
| `:site` | `:after_reset` | After `--watch` triggers a rebuild |
| `:site` | `:post_read` | After all posts/pages/data have been read from disk, before generators |
| `:site` | `:pre_render` | Before any page renders |
| `:site` | `:post_render` | After all pages render, before write |
| `:site` | `:post_write` | After the site is fully written to disk |
| `:pages` | `:post_init`, `:pre_render`, `:post_convert`, `:post_render`, `:post_write` | Per page |
| `:posts` | (same events) | Per post |
| `:documents` | (same events) | Per document in any collection (including posts) |
| `:clean` | `:on_obsolete` | When `jekyll clean` runs |

`:pre_render` runs *before* Markdown/Liquid conversion. `:post_convert` runs *after* Markdown conversion but before the layout wraps it. `:post_render` runs *after* the layout wraps. Picking the right point matters.

### Example: prepend a banner to all draft posts

```ruby
Jekyll::Hooks.register :posts, :pre_render do |post|
  if post.data["draft"]
    post.content = "🚧 **Draft — not published yet.**\n\n" + post.content
  end
end
```

### Example: inject computed front matter

```ruby
Jekyll::Hooks.register :posts, :post_init do |post|
  word_count = post.content.split.size
  post.data["word_count"] = word_count
  post.data["reading_minutes"] = (word_count / 200.0).ceil
end
```

Then anywhere: `{{ page.word_count }} words, {{ page.reading_minutes }} min`.

### Example: write an additional file after the build

```ruby
Jekyll::Hooks.register :site, :post_write do |site|
  posts_json = site.posts.docs.map { |p|
    { title: p.data["title"], url: p.url, date: p.date.iso8601 }
  }
  File.write(File.join(site.dest, "search-index.json"), JSON.dump(posts_json))
end
```

This runs after `_site/` is written, perfect for adding a JSON search index, generating a sitemap variant, or kicking off an external script.

### Priorities

If two hooks register for the same event, order is `:highest` → `:high` → `:normal` (default) → `:low` → `:lowest`. Within the same priority, registration order is reversed (LIFO). Don't depend on order unless you've set explicit priorities — it's fragile.

```ruby
Jekyll::Hooks.register :posts, :pre_render, priority: :high do |post|
  # runs before any :normal priority hooks
end
```

## Converters (support new markup languages)

If you want files written in some format X to render as HTML, write a Converter. This is how Markdown, Textile, etc., are integrated.

`_plugins/upcase_converter.rb` (demonstrative — converts `.up` files to uppercase HTML):

```ruby
module Jekyll
  class UpcaseConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext =~ /^\.up$/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      content.upcase
    end
  end
end
```

Now `mypage.up` containing `hello world` is rendered as `HELLO WORLD` at `/mypage.html`.

Real-world converters exist for AsciiDoc, Org-mode, ReStructuredText, Pandoc, Slim, and HAML. Search `jekyll-converter-X` on RubyGems before writing your own.

## Custom commands (extend the jekyll CLI)

Add subcommands like `bundle exec jekyll mycmd`. Less common, but useful for theme scaffolders or repetitive content creation.

`_plugins/new_review_command.rb` (creates a templated review post):

```ruby
module Jekyll
  module Commands
    class NewReview < Command
      class << self
        def init_with_program(prog)
          prog.command(:"new-review") do |c|
            c.syntax "new-review TITLE"
            c.description "Create a new product review post"
            c.action do |args, _options|
              title = args.join(" ")
              date  = Time.now.strftime("%Y-%m-%d")
              slug  = title.downcase.gsub(/[^a-z0-9]+/, "-")
              file  = "_posts/#{date}-#{slug}.md"
              File.write(file, <<~MD)
                ---
                layout: review
                title: "#{title}"
                date: #{date}
                rating: 0
                ---

                Write the review here.
              MD
              puts "Created #{file}"
            end
          end
        end
      end
    end
  end
end
```

Note: custom commands only load when defined in a gem, not in `_plugins/`. This is a Jekyll limitation. To use them you need to extract the plugin to a real gem (see next section).

## Packaging a plugin as a gem

Going from `_plugins/foo.rb` to a published `jekyll-foo` gem turns your local trick into something installable by anyone.

### Step 1: scaffold

```bash
bundle gem jekyll-foo
cd jekyll-foo
```

### Step 2: lay out the files

```
jekyll-foo/
├── jekyll-foo.gemspec
├── Gemfile
├── lib/
│   └── jekyll-foo.rb         # entry point, requires the rest
│   └── jekyll-foo/
│       ├── version.rb
│       └── filter.rb         # the actual code
└── README.md
```

`lib/jekyll-foo.rb`:

```ruby
require "jekyll"
require_relative "jekyll-foo/version"
require_relative "jekyll-foo/filter"
```

### Step 3: edit the gemspec

```ruby
# jekyll-foo.gemspec
Gem::Specification.new do |spec|
  spec.name          = "jekyll-foo"
  spec.version       = Jekyll::Foo::VERSION
  spec.authors       = ["You"]
  spec.email         = ["you@example.com"]
  spec.summary       = "Does foo for Jekyll sites."
  spec.homepage      = "https://github.com/you/jekyll-foo"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 4.0", "< 5.0"
  spec.required_ruby_version = ">= 3.1"
end
```

### Step 4: test locally before publishing

Point your test site's Gemfile at the local path:

```ruby
gem "jekyll-foo", path: "../jekyll-foo"
```

Run the test site. Iterate without re-publishing.

### Step 5: publish to RubyGems

```bash
gem build jekyll-foo.gemspec
gem push jekyll-foo-0.1.0.gem    # requires `gem signin` first
```

Mark it as `safe` (`safe true` in the plugin class) so it's eligible for the GitHub Pages allowlist — though acceptance into the allowlist requires a separate request and is rarely granted these days. Most users will install your plugin themselves with their own builds.

## Internationalization (i18n) without external plugins

A surprising amount of i18n can be done with stock Jekyll. The two main approaches:

### Approach 1: per-language strings table

`_data/i18n/en.yml`:

```yaml
nav:
  home: Home
  blog: Blog
  about: About
buttons:
  subscribe: Subscribe
  read_more: Read more
```

`_data/i18n/es.yml`:

```yaml
nav:
  home: Inicio
  blog: Blog
  about: Acerca
buttons:
  subscribe: Suscribirse
  read_more: Leer más
```

In layouts:

```liquid
{% assign lang = page.lang | default: site.lang | default: "en" %}
{% assign t = site.data.i18n[lang] %}

<a href="/">{{ t.nav.home }}</a>
<button>{{ t.buttons.subscribe }}</button>
```

Set `lang:` in each page's front matter, or via defaults scoped to a folder (`scope: { path: "es" }`).

### Approach 2: per-language collections

```yaml
# _config.yml
collections:
  posts_en:
    output: true
    permalink: /en/:slug/
  posts_es:
    output: true
    permalink: /es/:slug/

defaults:
  - scope: { type: "posts_en" }
    values: { layout: post, lang: en }
  - scope: { type: "posts_es" }
    values: { layout: post, lang: es }
```

Content goes in `_posts_en/` and `_posts_es/`. The URL prefix tells search engines what language each page is in. Add `<link rel="alternate" hreflang="es" href="...">` tags in your layout.

### Approach 3: dedicated plugins

For complex sites, [`jekyll-polyglot`](https://github.com/untra/polyglot) is the most-used option. It runs the build once per locale, prefixes URLs with the language code, emits proper `hreflang` tags, and handles fallback to a default language when a translation is missing.

```ruby
# Gemfile
gem "jekyll-polyglot"
```

```yaml
# _config.yml
languages:        ["en", "es", "fr"]
default_lang:     "en"
exclude_from_localization: ["assets", "images", "javascript", "css"]
parallel_localization: true     # build languages in parallel (Jekyll 4+)
```

Posts are written in any language and tagged with `lang:` in front matter:

```yaml
---
title: "Hola"
lang: es
ref: hello-post           # links translations of the same article
---
```

`ref:` is how polyglot knows `_posts/2026-05-22-hola.md` (lang: es) and `_posts/2026-05-22-hello.md` (lang: en) are the same article — it emits `<link rel="alternate" hreflang="...">` between them automatically.

Liquid helpers polyglot adds:

```liquid
{{ site.active_lang }}        {%- comment -%} current page's lang {%- endcomment -%}
{{ site.default_lang }}
{% for lang in site.languages %}
  <a href="/{{ lang }}{{ page.permalink }}">{{ lang | upcase }}</a>
{% endfor %}
```

Not on the GitHub Pages allowlist — needs a self-controlled build.

For sites that need richer locale handling (date formats, pluralization, RTL support), pair polyglot with `_data/i18n/<lang>.yml` strings tables for UI labels.

## Asset pipelines: Tailwind, esbuild, image optimization

Jekyll's built-in asset handling is Sass and "copy files verbatim". For modern frontend tooling, you run a separate pipeline alongside Jekyll.

### Tailwind CSS

`package.json`:

```json
{
  "scripts": {
    "build:css": "tailwindcss -i ./assets/css/input.css -o ./assets/css/main.css --minify",
    "watch:css": "tailwindcss -i ./assets/css/input.css -o ./assets/css/main.css --watch"
  },
  "devDependencies": {
    "tailwindcss": "^3.4.0"
  }
}
```

`tailwind.config.js`:

```js
module.exports = {
  content: [
    "./_layouts/**/*.html",
    "./_includes/**/*.html",
    "./_posts/**/*.md",
    "./_pages/**/*.{html,md}",
    "./index.html",
    "./*.md",
  ],
  theme: { extend: {} },
};
```

Add `assets/css/main.css` to `.gitignore` — it's generated. For dev, run Tailwind in watch mode in one terminal and Jekyll in another:

```bash
npm run watch:css &
bundle exec jekyll serve --livereload
```

In CI, the build command becomes:

```bash
npm ci && npm run build:css && JEKYLL_ENV=production bundle exec jekyll build
```

### esbuild for JavaScript

Similar pattern: an `esbuild` config that bundles `assets/js/main.js` from sources, run before `jekyll build`. Output is `assets/js/main.bundle.js`, referenced normally in your layout.

### Image optimization

Build-time options:
- [`jekyll-picture-tag`](https://github.com/rbuchberger/jekyll_picture_tag) — generates `<picture>` with responsive WebP/AVIF variants.
- Custom hook + `image_processing` gem (libvips) — write your own optimization step.
- External step: `sharp-cli` or `squoosh` in npm, run before `jekyll build`.

For most sites, pre-optimize images once with a CLI (`squoosh-cli` or `cwebp`) and commit the results. Build-time processing is slow and worth it only when image counts grow into the hundreds.

## Multi-output: PDFs, JSON APIs, AMP, RSS variants

Jekyll can emit anything, not just HTML. A single source can produce multiple outputs.

### JSON API alongside HTML

Create `api/posts.json`:

```liquid
---
layout: null
permalink: /api/posts.json
---
[
{% for post in site.posts %}
  {
    "title": {{ post.title | jsonify }},
    "url":   {{ post.url | absolute_url | jsonify }},
    "date":  {{ post.date | date_to_xmlschema | jsonify }},
    "tags":  {{ post.tags | jsonify }}
  }{% unless forloop.last %},{% endunless %}
{% endfor %}
]
```

`jsonify` handles escaping. `layout: null` means no HTML wrapper. The result is a real JSON endpoint your frontend can fetch.

### PDF generation

Two approaches:

1. **Per-post PDFs at build time**: run `weasyprint` or `chromium --headless --print-to-pdf` against each rendered post URL. Wire it in via a `:site, :post_write` hook.
2. **A site-wide PDF book**: assemble all posts into a single HTML file, then convert to PDF.

Example hook calling weasyprint after the site builds:

```ruby
Jekyll::Hooks.register :site, :post_write do |site|
  next unless ENV["GENERATE_PDFS"]   # don't slow down normal builds
  site.posts.docs.each do |post|
    src = File.join(site.dest, post.url, "index.html")
    dst = File.join(site.dest, post.url, "index.pdf")
    system("weasyprint", src, dst)
  end
end
```

### AMP variants

Generate `post.amp.html` for each post via a generator + a separate AMP layout. The post URL stays the same; the AMP variant lives at `<post-url>amp/` with `<link rel="amphtml">` in the HTML.

### Multiple RSS feeds

`jekyll-feed` already supports per-category feeds. For more exotic shapes (last 5 posts by tag, JSON Feed format, etc.), write a template file with `permalink: /feeds/X.xml` and Liquid the contents directly.

## Remote data at build time

> **Security warning:** Fetching external data at build time means untrusted content enters your build pipeline. Malicious API responses could inject arbitrary HTML/JS into your site or manipulate Liquid template logic. Always sanitize fetched data: strip HTML tags, validate expected structure, and never render raw remote values without escaping. Prefer Path 1 (pre-build script with manual review) over Path 2 (automatic fetching) for untrusted sources.

You can fetch external data and treat it as `site.data`. Two paths:

### Path 1: a pre-build script

Fetch and save to `_data/external.json` before `jekyll build` runs:

```bash
curl https://api.example.com/data > _data/external.json
bundle exec jekyll build
```

In CI, this is one extra workflow step. Reliable and obvious.

### Path 2: a generator that fetches inside Jekyll

```ruby
require "net/http"
require "json"

module Jekyll
  class RemoteDataLoader < Generator
    safe true
    priority :high

    def generate(site)
      uri = URI("https://api.example.com/data")
      response = Net::HTTP.get(uri)
      site.data["external"] = JSON.parse(response)
    end
  end
end
```

Now `{{ site.data.external }}` works as if it were a YAML file. Caveat: every build hits the API. Cache aggressively, or stick with Path 1.

## Profiling and large-site performance

Sites with thousands of posts run into Jekyll's limits. The diagnostic tools:

### Profile renderer time

```bash
bundle exec jekyll build --profile
```

Prints a table of templates by render time. Attack the slowest ones first. Common culprits:

- An include called inside a loop over `site.posts` — every iteration re-evaluates the include. Switch to `include_cached`.
- A `where_exp` filter that runs a complex expression on every post — precompute it in a generator hook.
- A custom Liquid tag that does heavy work — memoize.

### Memoization in custom Liquid

```ruby
module Jekyll
  class ExpensiveTag < Liquid::Tag
    @@cache = {}

    def render(context)
      key = context["page"]["path"]
      @@cache[key] ||= compute_expensive_thing(context)
    end
  end
end
```

`||=` caches per-key. Just make sure your key truly identifies what changes between calls.

### Incremental builds for dev

```bash
bundle exec jekyll serve --incremental
```

Only rebuilds changed files. Sometimes produces stale output (especially with includes), so keep it for dev only — never CI.

### Drop the things you don't need

Each plugin loads on every build, whether you use it or not. Audit plugins yearly. The fastest plugin is one you removed.

### When Jekyll truly isn't fast enough

Sites with 5,000+ posts where build time exceeds a few minutes have a few escape hatches:

- **Build only changed sections**: split into multiple Jekyll sites with shared layouts/data.
- **Move to Hugo**: same model, much faster.
- **Add a CDN layer**: builds slowly but serves fast. Often the real bottleneck is "I want to deploy in <10s" — fix with CI caching, not Jekyll itself.

The Jekyll team has been clear that performance for extreme-scale sites isn't a priority. If you're hitting walls, the framework choice may be wrong, not the optimization.

---

## Further reading

- Official plugin docs: <https://jekyllrb.com/docs/plugins/>
- Hooks reference: <https://jekyllrb.com/docs/plugins/hooks/>
- Themes guide: <https://jekyllrb.com/docs/themes/>
- Jekyll's own source (best learning resource for advanced internals): <https://github.com/jekyll/jekyll>
- "Explanations and Examples of Jekyll Plugins" — Michael Slinn's deep-dive series at <https://www.mslinn.com/jekyll/>
