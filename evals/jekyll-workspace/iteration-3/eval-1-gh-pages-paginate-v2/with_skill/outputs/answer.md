# Fix for "Could not find gem 'jekyll-paginate-v2'"

The `jekyll-paginate-v2` plugin is **not supported** by the GitHub Pages built-in builder because it is not on their restricted [plugin allowlist](https://pages.github.com/versions/). Your site works locally because your local environment has no such restriction.

## The Solution: GitHub Actions

To use `jekyll-paginate-v2` on GitHub Pages, you must move from the classic built-in build to a **GitHub Actions-based build**. This allows you to build the site in a container you control, supporting any plugin you need.

### Steps to implement

1.  **Configure GitHub Actions:** Create a new workflow file at `.github/workflows/pages.yml`. Use the standard Jekyll Action, which builds your site and uploads the `_site` directory as an artifact.
2.  **Update Repository Settings:** Go to your GitHub repository **Settings > Pages**. Change the **Build and deployment > Source** setting from "Deploy from a branch" to **"GitHub Actions"**.
3.  **Push Changes:** Commit and push your workflow file. GitHub will automatically trigger a build using your `Gemfile` and `_config.yml`, successfully installing `jekyll-paginate-v2` in the action environment.

For detailed templates and configuration, see the `references/deployment.md` file in the Jekyll skill documentation.

---
*Reference: `references/troubleshooting.md` and `references/deployment.md` in the Jekyll skill repository.*
