# Comments and Webmentions

> **Security note:** All comment systems described here involve ingesting third-party or user-generated content into your site. This carries indirect prompt injection and XSS risks. Apply `strip_html`, URL validation, and content length limits on all external data before rendering. Treat remote content as untrusted input.

Adding comments to a static site is a choice between accepting third-party JS, accepting infrastructure, or building a sync workflow that pulls comments at build time. This file covers what actually works in 2026.

## Table of contents

1. [The decision tree](#the-decision-tree)
2. [giscus — GitHub Discussions](#giscus--github-discussions)
3. [utterances — GitHub Issues](#utterances--github-issues)
4. [Cusdis — privacy-focused embed](#cusdis--privacy-focused-embed)
5. [Webmentions](#webmentions)
6. [Staticman — comments committed back to your repo](#staticman--comments-committed-back-to-your-repo)
7. [Disqus — and why people are leaving it](#disqus--and-why-people-are-leaving-it)
8. [Quick comparison table](#quick-comparison-table)

---

## The decision tree

- **Audience is technical and has GitHub accounts?** Use **giscus** (or utterances). Zero infrastructure, threads stored in your repo, fully ownable.
- **Audience is general and privacy-sensitive?** Use **Cusdis** (self-hosted or hosted free tier).
- **You're part of IndieWeb / want comments-as-links?** Use **webmentions** via `webmention.io` + display via `jekyll-webmention_io` or your own includes.
- **You want full ownership and zero JS at runtime?** **Staticman** — comments commit themselves into your repo as data files; re-render the site.
- **You're tempted by Disqus?** Don't, in 2026. See below.

## giscus — GitHub Discussions

**What it is**: Comments stored as GitHub Discussions, embedded via a small JS snippet. Replaces utterances for most use cases (utterances writes Issues, which clutters bug trackers; Discussions is the right home).

**Setup**:

1. Enable Discussions on your repo (Settings → General → Discussions).
2. Install the [giscus GitHub App](https://github.com/apps/giscus) and grant access to that repo.
3. Go to <https://giscus.app>, fill in your repo and pick a mapping (recommended: "Discussion title contains page pathname").
4. Copy the snippet it generates:

```html
<script src="https://giscus.app/client.js"
        data-repo="user/repo"
        data-repo-id="R_xxxx"
        data-category="Comments"
        data-category-id="DIC_xxxx"
        data-mapping="pathname"
        data-strict="0"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="bottom"
        data-theme="preferred_color_scheme"
        data-lang="en"
        crossorigin="anonymous"
        async>
</script>
```

5. Add it to `_layouts/post.html` (or wherever you want comments), gated on `page.comments == true`:

```liquid
{% if page.comments %}
<section id="comments">
  <h2>Comments</h2>
  <script src="https://giscus.app/client.js"
          data-repo="user/repo"
          ...
          async></script>
</section>
{% endif %}
```

6. Set `comments: true` in front matter on posts that should have comments. Or via defaults:

```yaml
defaults:
  - scope: { type: "posts" }
    values:
      comments: true
```

**Pros**: No infrastructure, comments are real Discussions you can moderate via GitHub's UI, free, no ads, no tracking.
**Cons**: Commenters need GitHub accounts, no email notification for new replies (you'd subscribe to the Discussion).

## utterances — GitHub Issues

Same concept as giscus, older sibling. Writes one Issue per blog post. Still works fine for personal blogs but use giscus if you're starting fresh.

```html
<script src="https://utteranc.es/client.js"
        repo="user/repo"
        issue-term="pathname"
        theme="preferred-color-scheme"
        crossorigin="anonymous"
        async>
</script>
```

Migration giscus ← utterances: easy if mapping was "pathname" in both; the Discussion title matches the Issue title.

## Cusdis — privacy-focused embed

Lightweight (5KB), no third-party trackers, free hosted tier or self-host.

```html
<div id="cusdis_thread"
     data-host="https://cusdis.com"
     data-app-id="YOUR_APP_ID"
     data-page-id="{{ page.url }}"
     data-page-url="{{ page.url | absolute_url }}"
     data-page-title="{{ page.title }}">
</div>
<script async defer src="https://cusdis.com/js/cusdis.es.js"></script>
```

Pros: works for general audience (no GitHub account required), small payload, GDPR-friendly.
Cons: moderation UI is basic, fewer features than Discussions.

## Webmentions

> **Security warning:** Webmentions are user-generated content from external sources. Fetched mention data (author names, URLs, content text) could contain malicious HTML or scripts. Always apply `strip_html` and URL validation when rendering webmentions. Never trust `w.content.text` or `w.author.name` without sanitization.

A web-standard for "site A linked to site B". You receive webmentions when others link to you, and render them as a sort of comment thread of inbound mentions, replies, and bookmarks (e.g., from Mastodon, Bluesky bridges).

### Receiving

1. Sign up at <https://webmention.io>.
2. Add to your `<head>`:

```html
<link rel="webmention" href="https://webmention.io/yourname/webmention">
<link rel="pingback"   href="https://webmention.io/yourname/xmlrpc">
```

3. At build time, fetch your mentions JSON and render:

```html
{% if page.webmentions %}
  <h2>Mentions</h2>
  <ul>
    {% for w in site.data.webmentions[page.url] %}
      <li>
        <a href="{{ w.url }}">{{ w.author.name }}</a>:
        {{ w.content.text | strip_html | truncate: 200 }}
      </li>
    {% endfor %}
  </ul>
{% endif %}
```

Fetch webmentions in your build script (or use the `jekyll-webmention_io` plugin, which caches and renders for you).

### Sending

When you publish a post that links out, send webmentions to the sites you linked. The `jekyll-webmention_io` plugin handles this in `:post_write` hooks.

Webmentions are best when integrated into the IndieWeb stack — your own site sends and receives them, replacing some of what social media does. For pure comments, prefer giscus.

## Staticman — comments committed back to your repo

> **Security warning:** Staticman commits user-generated content directly into your repository. Malicious comment submissions could contain crafted YAML that exploits your build pipeline, or inject content that manipulates template rendering. Always validate and sanitize Staticman YAML files before merging. Consider requiring moderation (manual merge) rather than auto-merge for untrusted submissions.

The most ambitious option. Visitors submit a form; Staticman pushes the comment as a YAML file into `_data/comments/<post-slug>/<comment-id>.yml` via a pull request (or directly). On merge/auto-merge, your site rebuilds with the new comments rendered server-side — no client JS at runtime.

Pros: zero JS, comments owned in your repo, fully portable.
Cons: setup is fiddly (you self-host the Staticman bridge or use a community instance), rebuild latency, spam filtering depends on Akismet integration.

If you're already invested in this kind of workflow it's great; for new sites it's usually overkill vs giscus.

Project: <https://staticman.net/>

## Disqus — and why people are leaving it

Disqus was the default for a decade. Reasons to skip in 2026:

- Tracking & ad-tech embedded. Slow to load. ~1MB of JS.
- Privacy regulations (GDPR/CCPA) make it a liability for many sites.
- Comments aren't yours — they live on Disqus's servers.
- Free tier shows ads, paid tier costs.

If you have an existing Disqus install and want to migrate, Disqus offers comment XML export. giscus and Cusdis both have import scripts that consume that XML.

## Quick comparison table

| System | Hosting | Commenters need... | JS payload | Comments owned by |
|---|---|---|---|---|
| giscus | None (GitHub) | GitHub account | ~25KB | You (in GH Discussions) |
| utterances | None (GitHub) | GitHub account | ~20KB | You (in GH Issues) |
| Cusdis | Free hosted / self | Nothing | ~5KB | You (Cusdis DB) |
| Webmentions | webmention.io | An IndieWeb site or bridge | ~0 (server-rendered) | You (cached in site) |
| Staticman | Self-host bridge | Nothing | ~0 | You (in repo) |
| Disqus | Disqus | Account or anon | ~1MB | Disqus |

## Further reading

- giscus: <https://giscus.app/>
- utterances: <https://utteranc.es/>
- Cusdis: <https://cusdis.com/>
- webmention.io: <https://webmention.io/>
- IndieWeb wiki: <https://indieweb.org/Webmention>
- Staticman: <https://staticman.net/>
- `jekyll-webmention_io`: <https://github.com/aarongustafson/jekyll-webmention_io>
