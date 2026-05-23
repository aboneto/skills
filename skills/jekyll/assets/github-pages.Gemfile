source "https://rubygems.org"

# Use this Gemfile ONLY if you're letting GitHub Pages' classic builder
# build your site from source. It pins everything to whatever GitHub
# currently supports (Jekyll 3.10.x at time of writing).
#
# If you want current Jekyll + arbitrary plugins on GitHub Pages,
# use the regular Gemfile and deploy via GitHub Actions instead.
# See references/deployment.md.

gem "github-pages", group: :jekyll_plugins

# Ruby 3+ needs webrick explicitly.
gem "webrick", "~> 1.9"

# Windows / JRuby compatibility
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
