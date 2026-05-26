# Meta

## Process notes

- Used the Jekyll skill (`SKILL.md`) as the primary guide. The skill's plugin table on line 185 explicitly lists `jekyll-paginate-v2` as **not** on the GitHub Pages allowlist, and the troubleshooting tree on line 199 directly addresses the "builds locally but fails on GitHub Pages" pattern.
- Referenced `references/deployment.md` for the GitHub Actions migration workflow (the recommended solution) and `references/plugins.md` for the allowlist explanation and `jekyll-paginate-v2` configuration details.
- Referenced `assets/Gemfile` and `assets/github-pages.Gemfile` to provide accurate Gemfile alternatives for both paths.
- Referenced `references/troubleshooting.md` line 84-89 which directly addresses "Build succeeds locally but fails on GitHub Pages — Allowlist issue."

## Key insight

The user says "Actions build" which is ambiguous — it could mean the classic GitHub Pages builder (which GitHub labels as "Actions" in the UI) or a custom GitHub Actions workflow. The answer handles both cases by explaining the `github-pages` gem incompatibility in either scenario.

## Uncertainties

- Without seeing the actual workflow file the user has, it's impossible to know if they're using `actions/jekyll-build-pages` (which has the same restrictions) or a custom workflow. The answer covers both cases.
- The exact baseurl in the workflow (`${{ steps.pages.outputs.base_path }}`) is specific to `actions/configure-pages@v5` — but since the site lives at `me.github.io/blog`, it would derive correctly (`/blog`).
