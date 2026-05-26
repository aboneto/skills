# Skill Benchmark: jekyll

**Model**: mimo-v2.5-pro
**Date**: 2026-05-26
**Evals**: 1, 2, 3, 4 (1 run each)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 70% ± 23% | +0.31 |

## Per-eval breakdown

| Eval | With Skill | Without Skill |
|------|------------|---------------|
| 1. gh-pages-paginate-v2 | 6/6 (100%) | 6/6 (100%) |
| 2. post-page-liquid | 7/7 (100%) | 4/7 (57%) |
| 3. docs-site-from-scratch | 12/12 (100%) | 6/12 (50%) |
| 4. responsive-images | 7/7 (100%) | 5/7 (71%) |

## Key observations

- **Eval 1**: Both configurations score perfectly. The without_skill model also knows about the GH Pages allowlist.
- **Eval 2**: Skill advantage is clear — without skill uses custom plugins for reading time and manual TOC parsing instead of built-in `number_of_words` and kramdown `{:toc}`.
- **Eval 3**: Biggest gap. Without skill misses `.ruby-version`, rbenv, theme gem, `id: pages` in workflow. The skill ensures all critical workflow steps are included.
- **Eval 4**: Both perform well. Without skill uses Netlify Image CDN (valid alternative) but misses version pinning.
