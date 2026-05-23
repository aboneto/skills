{
  "eval_id": 4,
  "eval_name": "responsive-images-jekyll",
  "prompt": "My Jekyll travel blog has ~150 posts each with a 3MB hero photo. PageSpeed scores are terrible — LCP is 5+ seconds. I want responsive images with WebP fallback and lazy loading. I host on Netlify so I'm not stuck on the GH Pages allowlist. Walk me through the changes — Gemfile, _config.yml, layout changes, and the build pipeline.",
  "skill_path": "skills/jekyll/SKILL.md",
  "outputs_expected": [
    "Gemfile changes (add jekyll-picture-tag)",
    "_config.yml plugin config and picture preset",
    "Layout/post.html hero image changes (with picture tag or hand-rolled srcset)",
    "Build pipeline (netlify.toml, sharp pre-processing)",
    "Netlify cache headers for generated assets"
  ],
  "domain": "jekyll",
  "created": "2026-05-23"
}