# Kramdown — Jekyll's Markdown engine

Jekyll's default `markdown: kramdown` processor is far more capable than vanilla Markdown. Most "how do I do X in Jekyll Markdown" questions are really kramdown questions. This file covers the features that actually matter day to day, plus the GFM compatibility layer most users want.

## Table of contents

1. [How to read this file](#how-to-read-this-file)
2. [Configuring kramdown in `_config.yml`](#configuring-kramdown-in-_configyml)
3. [GFM mode (most likely what you want)](#gfm-mode-most-likely-what-you-want)
4. [Attribute lists (IALs) — adding classes/ids/data](#attribute-lists-ials--adding-classesidsdata)
5. [Table of contents](#table-of-contents-1)
6. [Footnotes](#footnotes)
7. [Definition lists](#definition-lists)
8. [Abbreviations](#abbreviations)
9. [Math (LaTeX)](#math-latex)
10. [Tables](#tables)
11. [Code blocks and syntax highlighting](#code-blocks-and-syntax-highlighting)
12. [Smart punctuation](#smart-punctuation)
13. [Common gotchas](#common-gotchas)

---

## How to read this file

Kramdown's syntax extends CommonMark and GFM. Anything not described here works the same as on GitHub. Anything *unique to kramdown* is what trips people up — that's the focus below.

Reference: <https://kramdown.gettalong.org/syntax.html> (canonical, dense, comprehensive).

## Configuring kramdown in `_config.yml`

```yaml
markdown: kramdown            # already the default
kramdown:
  input: GFM                  # accept GitHub-flavored Markdown extensions
  hard_wrap: false            # true = a single newline becomes <br>
  auto_ids: true              # auto-generate id="" on headings (for anchor links)
  footnote_nr: 1              # footnote numbering start
  entity_output: as_char       # render &amp; as actual char where safe
  toc_levels: 2..4            # which heading levels appear in the TOC
  smart_quotes: lsquo,rsquo,ldquo,rdquo
  enable_coderay: false       # use rouge instead (see below)
  syntax_highlighter: rouge
  syntax_highlighter_opts:
    block:
      line_numbers: false
    span:
      line_numbers: false
```

Restart the server after editing.

## GFM mode (most likely what you want)

`input: GFM` lets you write the way you do on GitHub: fenced code blocks, autolinks, tables, strikethrough, task lists. Without it, kramdown defaults to a stricter dialect closer to original Markdown.

```yaml
kramdown:
  input: GFM
```

What `GFM` adds vs plain kramdown:

- Fenced code with backticks (kramdown's default uses tildes `~~~`)
- Autolinks for bare URLs
- `~~strikethrough~~`
- Task lists: `- [x] done` / `- [ ] todo`
- Slightly different line-break behavior

GFM mode is **opt-in**. Themes that ship without it will surprise you with broken code fences. If yours doesn't, fix it in `_config.yml`.

## Attribute lists (IALs) — adding classes/ids/data

This is kramdown's most-used "secret" feature. Attach HTML attributes to any block or span using `{:...}`:

```markdown
A standout paragraph.
{:.lead .text-center}

A heading with a custom id.
{:#my-anchor}

## Heading {#explicit-id .with-class}

A [link with class](https://example.com){:.btn .btn-primary}

Some *emphasis with attributes*{:.callout}.
```

Renders as:

```html
<p class="lead text-center">A standout paragraph.</p>
<p id="my-anchor">A heading with a custom id.</p>
<h2 id="explicit-id" class="with-class">Heading</h2>
<p><a href="https://example.com" class="btn btn-primary">link with class</a></p>
<p>Some <em class="callout">emphasis with attributes</em>.</p>
```

Span-level IALs (the inline ones) must come immediately after the closing delimiter, no space. Block-level IALs go on the line below.

You can also define reusable attribute sets:

```markdown
{:my-style: .lead .text-center}

A paragraph.
{:my-style}

Another paragraph.
{:my-style}
```

**Why this matters in Jekyll:** lets your Markdown pick up your theme's CSS components without dropping into raw HTML for every styled element.

## Table of contents

Generate an automatic TOC from headings:

```markdown
* This text is ignored — needed to start a UL
{:toc}
```

Output is a nested `<ul>` of every heading at the levels you configured (`toc_levels: 2..4` by default). Style it with a class via IAL:

```markdown
* TOC
{:toc .doc-toc}
```

Skip a heading from the TOC:

```markdown
## Don't list me
{:.no_toc}
```

This is simpler than installing `jekyll-toc` and works on GitHub Pages.

## Footnotes

```markdown
Here is a claim.[^1] And another.[^longnote]

[^1]: This is the explanation.
[^longnote]:
    Multi-paragraph footnotes work too, just indent
    each line with 4 spaces.

    Even multiple paragraphs.
```

Footnote definitions can live anywhere in the file — kramdown collects them. They render at the bottom of the post with back-references.

`footnote_nr:` in `_config.yml` lets you control the starting number across pages if you're using footnotes site-wide (rare).

## Definition lists

```markdown
Jekyll
: A Ruby-based static site generator.

Hugo
: A Go-based static site generator.
: Known for speed.
```

Renders as `<dl><dt>...</dt><dd>...</dd></dl>`. Useful for glossaries, FAQ entries, and term lists. Underused.

## Abbreviations

```markdown
The HTML spec is at the W3C.

*[HTML]: HyperText Markup Language
*[W3C]: World Wide Web Consortium
```

Anywhere `HTML` or `W3C` appears in the document, it gets wrapped in `<abbr title="...">`. Hover-tooltip glossary, no JS needed.

## Math (LaTeX)

Kramdown can pass LaTeX through to a math renderer:

```yaml
kramdown:
  math_engine: mathjax
```

Available engines:
- `mathjax` — best supported, requires loading the MathJax JS in your layout
- `katex` — faster client-side rendering, also requires the JS
- `mathjaxnode` — server-side render (no JS at runtime); needs Node available in CI

Inline math: `$$ E = mc^2 $$` (single dollar pair works too if `input: GFM` is off).

Block math:

```markdown
$$
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
$$
```

In your layout, include MathJax or KaTeX once per page that uses it:

```html
{% if page.math %}
  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
{% endif %}
```

Set `math: true` in the front matter of pages that use formulas to avoid loading the script everywhere.

## Tables

GFM tables work as you'd expect. Kramdown adds **alignment** and **column-spanning**:

```markdown
| Item     | Price | Stock |
|:---------|------:|:-----:|
| Widget   | 1.99  |  yes  |
| Gadget   | 9.99  |  no   |
```

- `:---` left-align
- `---:` right-align
- `:---:` center
- Plain `---` follows default

Tables can have an IAL block for class/id:

```markdown
| ... |
| ... |
{:.pricing-table}
```

## Code blocks and syntax highlighting

Three forms, all OK in GFM mode:

````markdown
```ruby
def hello = "hi"
```

~~~python
def hello(): pass
~~~
````

For options on a specific block (line numbers, highlight specific lines), prefer the Liquid `{% highlight %}` tag:

```liquid
{% highlight ruby linenos %}
def hello
  "hi"
end
{% endhighlight %}
```

Rouge (the highlighter) classes the spans; you supply the CSS. Generate a theme:

```bash
rougify style monokai > assets/css/syntax.css
```

Then `@import` it in your main stylesheet.

## Smart punctuation

Kramdown converts straight quotes to curly quotes by default. You can tune:

```yaml
kramdown:
  smart_quotes: lsquo,rsquo,ldquo,rdquo   # default
```

Other languages need different glyphs:

```yaml
kramdown:
  smart_quotes: sbquo,lsquo,bdquo,ldquo   # German "„…"  '‚…'"
```

Disable by setting all four to ASCII `apos,apos,quot,quot` or pre-escape in source.

## Common gotchas

1. **Empty line required before blocks.** A list directly under a paragraph without a blank line will be parsed as one paragraph.

2. **Indentation inside lists.** Continuing a list item's content needs 4-space indentation (or a tab) — fewer spaces drops you out of the item.

3. **IAL position is strict.** Span IALs `{:.class}` must touch the closing delimiter. `*hi* {:.x}` (with space) does NOT work; `*hi*{:.x}` does.

4. **`auto_ids` slugifies non-ASCII unevenly.** A heading "Café" becomes id="caf-" by default. Provide an explicit id when this matters: `## Café {#cafe}`.

5. **`toc_levels` excludes anything outside the range.** Default is `1..6` for kramdown, but Jekyll usually sets `2..4`. If your H1 is missing from the TOC, that's why.

6. **Footnotes inside lists are tricky.** The footnote definition's continuation indentation conflicts with list indentation. Move definitions outside the list.

7. **Math + `markdown: kramdown` + `input: GFM`** can conflict on `$` parsing. Test with `$$ … $$` block form first; switch to `\(...\)`/`\[...\]` if `$` gets escaped unexpectedly.

8. **GitHub renders your README differently than your Jekyll site.** GitHub uses its own GFM renderer; Jekyll uses kramdown. Same source, two outputs. Don't expect 100% parity — especially for raw HTML embedded in Markdown.

## When kramdown isn't enough

- **CommonMark strictness needed**: switch to `markdown: CommonMark` (you lose IALs, definition lists, math).
- **AsciiDoc**: better for technical docs with cross-references, includes, conditionals. Install `jekyll-asciidoc`.
- **MDX-style component embedding**: Jekyll doesn't have it natively. Use Liquid `{% include %}` instead, or migrate to a JSX-based generator if you really need React-in-Markdown.

## Further reading

- Kramdown syntax: <https://kramdown.gettalong.org/syntax.html>
- Kramdown options: <https://kramdown.gettalong.org/options.html>
- Jekyll's Markdown docs: <https://jekyllrb.com/docs/configuration/markdown/>
- Rouge supported lexers: <https://github.com/rouge-ruby/rouge/wiki/list-of-supported-languages-and-lexers>
