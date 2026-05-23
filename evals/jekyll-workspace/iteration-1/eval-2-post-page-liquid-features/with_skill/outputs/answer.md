# Reading time + TOC + related posts on every post page

You can do all three with pure Liquid — no extra plugins required, which keeps things simple on Jekyll 4.4 with kramdown. Here is exactly where each piece lives and the code that goes in it.

## Where this stuff lives

Your posts use `layout: post`, so the place to edit is the `post` layout file:

```
_layouts/post.html
```

If you don't have one yet (because you're using a theme that ships its own), create it. Jekyll will use your local `_layouts/post.html` and fall back to the theme for anything you don't override. If you want to keep the changes isolated, break each feature into its own include under `_includes/` and reference them from the layout — that's the pattern I'll use below.

Final shape:

```
_layouts/post.html
_includes/reading-time.html
_includes/post-toc.html
_includes/related-posts.html
```

## (a) Estimated reading time

This one is a one-liner. Put it in `_includes/reading-time.html`:

```liquid
{%- assign words = page.content | number_of_words -%}
{%- assign minutes = words | divided_by: 200 | plus: 1 -%}
<span class="reading-time">{{ minutes }} min read</span>
```

`number_of_words` is a Jekyll filter that strips HTML and counts words in the rendered content. 200 wpm is the conventional average; `| plus: 1` avoids "0 min read" on very short posts and gives a ceiling-ish round.

If you want it more accurate for code-heavy posts, lower the divisor (e.g. `divided_by: 180`).

## (b) Table of contents from H2 and H3

You have two real options. Pick one — I'd pick option 1.

### Option 1 (recommended): kramdown's built-in `{:toc}`

kramdown already builds the TOC for you and respects heading levels via `_config.yml`. Add this to `_config.yml`:

```yaml
kramdown:
  input: GFM
  toc_levels: 2..3       # H2 and H3 only
  auto_ids: true         # default true, but be explicit — needed for anchor links
```

Restart `jekyll serve` after editing `_config.yml` — it doesn't hot-reload.

Then in each post (or in the layout, see below) put a UL marker followed by the `{:toc}` IAL:

```markdown
* TOC placeholder — this line is replaced
{:toc}
```

Pros: built into kramdown, zero JS, anchor IDs match what kramdown already generates for your headings, you can mark headings to skip with `{:.no_toc}`.

Cons: it has to be inside the post body, not the layout. So either:
- Drop the two-line marker at the top of every post (annoying), OR
- Make a small layout trick: render the TOC marker in the layout *before* `{{ content }}` and rely on the fact that Liquid runs before kramdown — but kramdown only processes `{:toc}` inside the markdown file itself, not in HTML layouts. So this trick doesn't actually work. Stick to putting `* TOC\n{:toc}` at the top of each post.

If sprinkling that snippet in every post bothers you, use Option 2.

### Option 2: Build the TOC in the layout from `page.content`

This scans the rendered post HTML for `<h2>` and `<h3>` tags and writes anchor links. Put this in `_includes/post-toc.html`:

```liquid
{%- comment -%}
  Build a TOC from H2/H3 in the rendered post.
  kramdown auto-generates id="..." on headings, so we can link to them.
{%- endcomment -%}

{%- assign html = page.content -%}
{%- assign chunks = html | split: "<h" -%}

{%- assign headings = "" | split: "" -%}
{%- for chunk in chunks -%}
  {%- assign level = chunk | slice: 0, 1 -%}
  {%- if level == "2" or level == "3" -%}
    {%- assign id_part = chunk | split: 'id="' -%}
    {%- if id_part.size > 1 -%}
      {%- assign id = id_part[1] | split: '"' | first -%}
      {%- assign after_gt = chunk | split: ">" -%}
      {%- assign text_with_close = after_gt | shift | join: ">" -%}
      {%- assign text = text_with_close | split: "</h" | first | strip_html | strip -%}
      {%- capture entry -%}{{ level }}|{{ id }}|{{ text }}{%- endcapture -%}
      {%- assign headings = headings | push: entry -%}
    {%- endif -%}
  {%- endif -%}
{%- endfor -%}

{%- if headings.size > 0 -%}
<nav class="post-toc" aria-label="Table of contents">
  <p class="post-toc__title">On this page</p>
  <ul class="post-toc__list">
    {%- assign in_h3 = false -%}
    {%- for h in headings -%}
      {%- assign parts = h | split: "|" -%}
      {%- assign level = parts[0] -%}
      {%- assign id = parts[1] -%}
      {%- assign text = parts[2] -%}
      {%- if level == "2" -%}
        {%- if in_h3 %}</ul></li>{% endif -%}
        {%- assign in_h3 = false -%}
        <li><a href="#{{ id }}">{{ text }}</a>
      {%- elsif level == "3" -%}
        {%- unless in_h3 %}<ul>{% assign in_h3 = true %}{% endunless -%}
          <li><a href="#{{ id }}">{{ text }}</a></li>
      {%- endif -%}
    {%- endfor -%}
    {%- if in_h3 %}</ul></li>{% endif -%}
  </ul>
</nav>
{%- endif -%}
```

Notes:
- kramdown gives every heading an `id` automatically (`auto_ids: true`, which is the default). So the `#fragment` links will resolve.
- It works on the rendered HTML of the post, which Liquid sees via `page.content` inside a layout.
- It nests H3s under their parent H2 as `<ul>` inside `<li>`.
- If a post has no H2/H3, the whole TOC block is skipped.

The split-and-parse is a little ugly, but Liquid has no regex; this is the standard idiom. Anything fancier and you'd write a Jekyll plugin (`_plugins/toc.rb`) — only worth it if you have hundreds of posts and care about build time.

## (c) Related posts via shared tags

Jekyll has a built-in `site.related_posts`, but it uses LSI (latent semantic indexing), which (i) requires the `classifier-reborn` gem plus the `--lsi` flag, and (ii) is slow. For tag-overlap, do it yourself in Liquid — fast, no extra dependency.

`_includes/related-posts.html`:

```liquid
{%- comment -%}
  Related posts = other posts that share at least one tag with this one.
  Trick: concat the two tag arrays; if uniq shrinks it, there was overlap.
{%- endcomment -%}

{%- assign my_tags = page.tags -%}
{%- assign related = "" | split: "" -%}

{%- if my_tags.size > 0 -%}
  {%- for p in site.posts -%}
    {%- if p.url == page.url -%}{%- continue -%}{%- endif -%}
    {%- if p.tags.size == 0 -%}{%- continue -%}{%- endif -%}
    {%- assign combined = p.tags | concat: my_tags -%}
    {%- assign deduped = combined | uniq -%}
    {%- if deduped.size < combined.size -%}
      {%- assign related = related | push: p -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{%- if related.size > 0 -%}
<aside class="related-posts">
  <h2>Related posts</h2>
  <ul>
    {%- for p in related limit: 3 -%}
      <li>
        <a href="{{ p.url | relative_url }}">{{ p.title }}</a>
        <time datetime="{{ p.date | date_to_xmlschema }}">
          {{ p.date | date: "%B %-d, %Y" }}
        </time>
      </li>
    {%- endfor -%}
  </ul>
</aside>
{%- endif -%}
```

Why the `concat | uniq` trick: Liquid has no set-intersection filter. If `my_tags = [a,b]` and `p.tags = [b,c]`, then `combined = [a,b,b,c]` (size 4) and `deduped = [a,b,c]` (size 3) — `deduped.size < combined.size` is true exactly when there's at least one shared tag. Cheap and works.

If you want to **rank by overlap count** (most shared tags first) you can extend this, but it gets noticeably more verbose in pure Liquid. For the "share at least one tag" requirement, the snippet above is enough. Notice the `limit: 3` to cap the list — adjust to taste.

Note: this iterates `site.posts` for every post on every build. On a small blog (< 200 posts) it's fine. If you grow past a few hundred posts and builds slow down, wrap the include with `{% include_cached related-posts.html %}` — that requires the `jekyll-include-cache` plugin and a self-hosted build (Netlify, Cloudflare Pages, or GitHub Actions; the plugin is not on the GitHub Pages allowlist).

## Wiring it all together in `_layouts/post.html`

```html
---
layout: default
---
<article class="post">
  <header class="post-header">
    <h1>{{ page.title }}</h1>
    <p class="post-meta">
      <time datetime="{{ page.date | date_to_xmlschema }}">
        {{ page.date | date: "%B %-d, %Y" }}
      </time>
      &middot;
      {% include reading-time.html %}
    </p>
    {% if page.tags.size > 0 %}
      <ul class="post-tags">
        {% for tag in page.tags %}
          <li>
            <a href="{{ '/tags/' | append: tag | slugify | append: '/' | relative_url }}">
              #{{ tag }}
            </a>
          </li>
        {% endfor %}
      </ul>
    {% endif %}
  </header>

  {% include post-toc.html %}

  <div class="post-content">
    {{ content }}
  </div>

  {% include related-posts.html %}
</article>
```

The layout itself extends `default` (your site-wide chrome), then renders header + reading time + TOC + content + related posts. Each include is self-contained, so you can move or restyle any of them without touching the others.

## A few small things worth flagging

- **Restart the server** after editing `_config.yml`. `jekyll serve` does not pick up config changes on its own.
- **kramdown auto-IDs**: if you ever turned `auto_ids: false`, the in-layout TOC links won't resolve. Default is on, but worth checking.
- If you want headings hidden from the TOC, with **Option 1** use `{:.no_toc}` after the heading in markdown. With **Option 2**, you'd need to extend the parser — easier to just give those headings a class and filter them out, or stay on Option 1.
- The reading-time and related-posts snippets are also documented as "common patterns" in the Liquid reference under this skill if you ever want to tweak them.
- Tag slugify: posts tagged `Web Dev` and `web dev` will be treated as different tags by Liquid's array equality, so be consistent in front matter (lowercase, kebab-case is the safe default).
