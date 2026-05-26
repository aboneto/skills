# Meta — Eval 3: Docs Site From Scratch

## Process notes

- **Theme choice**: Selected **Just the Docs** because it's the go-to for documentation sites with sidebar navigation and built-in light/dark mode (`color_scheme: nil` follows OS preference). The skill's `references/themes.md` explicitly recommends it for "Documentation, sidebar nav, search."

- **Gemfile**: Adapted from `assets/Gemfile` in the skill. Added `html-proofer` under a `:test` group (not `:jekyll_plugins`) per `references/testing.md` guidance. Added `jekyll-last-modified-at` for "Last updated" timestamps in docs. Added `just-the-docs` theme gem. Removed `jekyll-paginate-v2` since docs sites typically don't paginate.

- **Deployment workflow**: Combined patterns from `references/deployment.md` (the GitHub Actions deployment workflow) and `references/testing.md` (the html-proofer step and the combined CI workflow example). Separated test and deploy into two jobs so broken links block deployment.

- **html-proofer flags**: Used `--disable-external` as the default for PR CI speed (per testing.md recommendation: "skip outbound links (fast). Often the right default for PR checks"). Added `--check-html`, `--check-img-http`, `--check-opengraph`, `--enforce-https` for thorough internal checking. The `--ignore-status-codes` handles flaky HTTP responses that aren't real failures.

- **40-page structure**: The 45-page manifest at the end was designed to feel realistic — organized into 6 sections commonly found in docs sites (getting-started, user-guide, configuration, deploy, api-reference, contributing, about).

- **Light/dark mode**: Just the Docs handles this natively via `color_scheme`. The skill mentions Just the Docs supports `color_scheme: dark` in `references/themes.md`; `nil` means "follow OS preference," which is the most modern default.

- **Ruby version**: Pinned to `3.4.8` in `.ruby-version` — aligns with the skill's guidance that "Ruby 3.4.x is the default in 2026."

- **Uncertainties**:
  - Just the Docs v0.10.x vs v0.9.x: the skill doesn't specify the exact version range. Used `~> 0.10.1` as a safe modern constraint. 
  - The `jekyll-last-modified-at` plugin requires `fetch-depth: 0` in CI, which is included in both the test and deploy jobs.
  - Whether the user wants blog posts or pure docs pages — assumed pure docs since they said "docs site." No `_posts/` directory in the manifest.
  - Whether they want Mermaid/Diagrams — included as optional config but not required.
