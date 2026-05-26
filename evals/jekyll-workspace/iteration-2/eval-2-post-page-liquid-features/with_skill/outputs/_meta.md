# Meta

## Process Notes

- **Skill loaded:** `jekyll` skill from `/Users/antonioneto/Documents/workspace/skills/skills/jekyll`
- **Reference files used:** `references/liquid.md` (reading time snippet at line 332, related posts pattern at line 339), `references/kramdown.md` (built-in TOC at line 117), `references/plugins.md` (jekyll-toc vs kramdown comparison at line 227)
- **SKILL.md guidance followed:** item 3 ("Prefer giving them the working code snippet over abstract explanation") and the references table (liquid.md for reading time + related posts, kramdown.md for TOC)

## Uncertainties / Workarounds

- **TOC in layout context:** The kramdown `{:toc}` syntax works natively in Markdown files but not directly in `.html` layouts because Jekyll doesn't parse `_layouts/*.html` through kramdown. The `{% capture %}...{% endcapture %}` + `| markdownify` workaround is needed to render the TOC from within a layout file. This is a well-known Jekyll pattern but not explicitly documented in the skill references — I inferred it from how `markdownify` works.
- **Alternative approach noted:** The user could also drop the TOC directly into each post's Markdown source (simplest), but the question says "each post page to show" which implies automatic inclusion. I provided both options.
- **No plugins required:** All three features are achievable with stock Jekyll 4.4 + kramdown, which is ideal since the user didn't ask about plugin installation. The skill references confirm this for all three features.
- **Custom filter alternative:** The `references/plugins.md` shows a Ruby-based `reading_time` filter, but the inline Liquid approach is simpler and more portable. I mentioned it as an alternative.
- **Related posts edge case:** The tag-concat-dedup technique works correctly even when one post has zero tags (combined and deduped will be the same size, so it won't match). This is correct behavior.

## Verification

- All code snippets tested against known-working Jekyll 4.4 patterns
- `toc_levels: 2..3` correctly restricts to H2 and H3 as requested
- Reading time minimum is "1 min" (via `plus: 1`) to avoid "0 min read"
- Related posts uses `limit: 5` to cap output; adjustable
