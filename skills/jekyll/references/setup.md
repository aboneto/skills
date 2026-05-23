# Setup, Ruby, and Upgrades

The single biggest source of "I can't even start" problems with Jekyll isn't Jekyll — it's Ruby. This file walks through the install paths that actually work in 2026 and the upgrade traps to watch for.

## Installing Ruby (the right way)

Do **not** use the system Ruby on macOS or the default Ruby on Linux. They're too old, you'll need `sudo` for gems, and you'll fight permissions forever. Pick one of these:

### macOS / Linux: `rbenv`

```bash
brew install rbenv ruby-build           # macOS
# or: curl -fsSL https://rbenv.org/install.sh | bash

rbenv install 3.4.8                     # default in 2026 — earlier 3.x has plugin compat issues
rbenv global 3.4.8
ruby -v                                 # should print 3.4.8
gem install bundler
```

Add `eval "$(rbenv init - bash)"` (or `zsh`) to your shell rc file. Without that line, `rbenv` is installed but inert.

### Cross-platform: `mise` (modern alternative)

```bash
curl https://mise.run | sh
mise use --global ruby@3.4
```

`mise` also handles Node, Python, etc., so it's a good choice if you juggle stacks.

### Windows

Use [RubyInstaller](https://rubyinstaller.org/) with the **DevKit** option. Anything else (WSL aside) is pain. WSL2 + the Linux path above is usually smoother than native Windows Ruby.

## Installing Jekyll

Once Ruby is sane:

```bash
gem install jekyll bundler
jekyll new my-site
cd my-site
bundle install
bundle exec jekyll serve
```

`jekyll new` scaffolds a site using the Minima theme. The `bundle exec` prefix matters — without it you may pick up a different Jekyll version than your Gemfile specifies.

## The Gemfile that actually works

A reliable Gemfile for a self-hosted Jekyll 4.x site (Netlify, Cloudflare, GitHub Actions):

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"

group :jekyll_plugins do
  gem "jekyll-feed",          "~> 0.17"
  gem "jekyll-seo-tag",       "~> 2.8"
  gem "jekyll-sitemap",       "~> 1.4"
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-paginate-v2",   "~> 3.0"
end

# Ruby 3+ removed webrick from stdlib; Jekyll's dev server needs it.
gem "webrick", "~> 1.9"

# Lock Sass to avoid surprise deprecation breakage in old themes
gem "sass-embedded", "~> 1.77"

# Windows / JRuby goodies
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
gem "wdm", "~> 0.1", platforms: [:mingw, :x64_mingw, :mswin]
```

**Why pessimistic constraints (`~>`)?** They allow patch updates (`4.4.1 → 4.4.2`) but block surprise majors (`4.4 → 5.0`). For Jekyll specifically, majors have historically introduced template breakage.

**Commit `Gemfile.lock`.** Always. Without it, CI installs whatever's newest at build time and you get non-reproducible builds.

A version of this file lives in `assets/Gemfile` ready to copy in.

## The GitHub Pages Gemfile (different beast)

If you push your **source** to GitHub Pages and let GitHub build it, you're stuck on the [official allowlist](https://pages.github.com/versions/). Currently that means Jekyll 3.10.x and a small set of plugins. Use the `github-pages` meta-gem instead:

```ruby
source "https://rubygems.org"
gem "github-pages", group: :jekyll_plugins
gem "webrick", "~> 1.9"
```

This locks every transitive dependency to whatever GitHub's builder has. Trying to use Jekyll 4 features here will fail in production even if it works locally. See `references/deployment.md` for how to escape this with GitHub Actions instead.

A copy of this Gemfile is in `assets/github-pages.Gemfile`.

## Pinning your toolchain (reproducibility)

A site that builds today on your machine should build the same way next year in CI. Pin **every** layer:

1. **Ruby version**: commit a `.ruby-version` file at the repo root:

   ```
   3.4.8
   ```

   `rbenv`, `chruby`, `mise`, and `asdf` all honor it. RubyGems/Bundler will refuse to install if you're on the wrong Ruby.

2. **For multi-tool projects**: prefer `.tool-versions` (asdf/mise):

   ```
   ruby 3.4.8
   nodejs 20.11.1
   ```

3. **Bundler version**: pin it in `Gemfile.lock` (the `BUNDLED WITH` line — leave it alone, it auto-pins). If you want to enforce strict reproducibility:

   ```bash
   bundle config set frozen true
   ```

   This makes `bundle install` fail if the lockfile would change.

4. **Gemfile.lock** must be committed. Always.

5. **In CI**: `ruby/setup-ruby@v1` reads `.ruby-version` automatically when you omit `ruby-version:`. One source of truth.

## Local dev: host, port, and LAN preview

Default: `jekyll serve` listens on `127.0.0.1:4000`. To preview from another device on your network (a phone, an iPad), bind to all interfaces:

```bash
bundle exec jekyll serve --host 0.0.0.0 --port 4001
```

Then visit `http://<your-laptop-LAN-IP>:4001` from the phone. Your firewall may need to allow the port.

Port already in use:

```bash
lsof -ti:4000 | xargs kill            # nuke whatever owns 4000
bundle exec jekyll serve --port 4001  # or pick another port
```

`--detach` runs the server in the background — useful in CI for testing tools (Lighthouse, Pa11y, etc.) that need a live server.

## Safe mode

`safe: true` in `_config.yml` (or the `--safe` flag) makes Jekyll refuse to:

- Load any plugin not in the GitHub Pages allowlist.
- Execute custom `_plugins/` Ruby code.
- Follow symlinks outside the site root.

GitHub Pages' classic builder always runs in safe mode. This is why your custom plugin "works locally but not in production". For a self-hosted build you usually want `safe: false` (the default).

## Upgrade strategy

A few hard-won rules from running production Jekyll sites for years:

1. **Upgrade one thing at a time.** Bump Jekyll, run, fix breakage, commit. Then bump Sass, then plugins. If you bump everything at once you can't tell which change broke things.
2. **Sass is the most fragile layer.** Dart Sass deprecates and removes aggressively. If your theme is from 2019-2021, `@import` is on its way out — migrate to `@use`/`@forward`, or pin `sass-embedded` to a known-good version.
3. **Pin everything with `~>`.** As above.
4. **Read the Jekyll release notes**, not just the version number. `jekyll/jekyll` GitHub releases call out breaking changes.
5. **Test `JEKYLL_ENV=production bundle exec jekyll build` before deploying.** Some bugs only appear in production mode.
6. **Theme drift is permanent.** If your theme's upstream has been unmaintained for >1 year, fork it. Don't expect rescue. You'll do the maintenance yourself.

## Common install errors

| Error | Cause | Fix |
|---|---|---|
| `Your Ruby version is X, but your Gemfile specified Y` | Wrong Ruby in shell | `rbenv local 3.4.8`; check `which ruby` |
| `eventmachine ... could not be installed` | Missing build tools | macOS: `xcode-select --install`. Linux: `apt install build-essential` |
| `You don't have write permissions for /Library/Ruby/Gems/...` | Using system Ruby. Stop. | Install rbenv as above. Never `sudo gem install`. |
| `No such file or directory -- webrick (LoadError)` | Ruby 3 dropped webrick | `gem "webrick", "~> 1.9"` in Gemfile |
| `Bundler::GemNotFound: Could not find gem 'X' in any of the gem sources` | Stale lockfile | `bundle update X` or delete `Gemfile.lock` and `bundle install` |
| `Liquid Exception: undefined method 'to_liquid'` | Plugin incompatible with your Jekyll version | Check plugin's compatibility table on RubyGems |
