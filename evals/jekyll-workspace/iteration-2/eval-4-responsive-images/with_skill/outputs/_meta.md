# Meta

## Process notes

- Loaded the `skill-creator` skill per the skill activation instructions, then read the Jekyll skill at `skills/jekyll/SKILL.md`.
- The SKILL.md table of contents pointed me to `references/images.md` for responsive images. I also read `references/deployment.md` (for Netlify config), `references/configuration.md` (for `_config.yml` structure), `references/plugins.md` (for plugin installation patterns), and the `assets/Gemfile` / `assets/_config.yml` templates.
- The user's task matched exactly the domain covered by `references/images.md` — particularly the "Jekyll Picture Tag" section and the "four-step image plan."

## Key decisions

- Recommended `jekyll-picture-tag` over hand-rolled `srcset` because 150 posts × manual resizing is impractical. The plugin caches outputs between builds, which is critical at this scale.
- Used `formats: [webp, original]` rather than adding AVIF. AVIF encoders are slow and would kill build times on 150 images. The user can add AVIF later by adding it to the formats array.
- Chose four widths (480/768/1200/1600) covering phones through retina desktops. Could go with 3 or 5 — 4 is a good balance.
- Did not add the pre-build `sharp` step as a hard requirement — batch-compressing once locally and committing is simpler and avoids CI time. Presented both options.
- Used the Netlify plugin cache to persist `_site/generated` so images aren't reprocessed every deploy. This is important for a 150-image site.

## Uncertainties

- The exact `netlify.toml` `[[plugins]]` syntax for `@netlify/plugin-cache` may vary slightly — the core point is caching `_site/generated`. If the plugin cache approach doesn't work, a `cache: paths` key in `[build]` may be needed depending on Netlify's current caching API.
- `jekyll-picture-tag` v2.1 may have minor API differences from the snippet shown. The preset `attributes` hash format is based on the skill's reference docs.

## Files read

- `skills/jekyll/SKILL.md` — full skill body
- `skills/jekyll/references/images.md` — responsive image pipeline
- `skills/jekyll/references/deployment.md` — Netlify config
- `skills/jekyll/references/configuration.md` — `_config.yml` reference
- `skills/jekyll/references/plugins.md` — plugin install patterns
- `skills/jekyll/assets/Gemfile` — starter Gemfile
- `skills/jekyll/assets/_config.yml` — starter config
