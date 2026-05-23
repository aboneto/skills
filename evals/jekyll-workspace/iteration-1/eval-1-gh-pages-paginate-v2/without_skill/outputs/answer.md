# El problema

GitHub Pages no soporta `jekyll-paginate-v2`. El gem `github-pages` solo permite una whitelist fija de plugins (la "Dependency versions" list que mantiene GitHub), y `jekyll-paginate-v2` no está en ella. Solo `jekyll-paginate` (v1) está soportado, y ese es muy limitado.

Por eso falla en Actions pero te funciona en local: localmente `bundle exec jekyll serve` corre Jekyll directamente con el plugin que tienes instalado, mientras que el workflow oficial de GitHub Pages corre dentro del sandbox de `github-pages` que ignora gems fuera de la whitelist.

Tienes tres caminos. El segundo es el que recomiendo.

---

## Opción 1: Bajar a `jekyll-paginate` v1 (soportado por GitHub Pages)

Si la paginación que necesitas es básica (solo paginar el blog principal en `/`):

**Gemfile**
```ruby
source "https://rubygems.org"

gem "github-pages", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-paginate"
end
```

**_config.yml**
```yaml
plugins:
  - jekyll-paginate

paginate: 10
paginate_path: "/page:num/"
```

Limitaciones: solo pagina un feed, no soporta paginación por categoría/tag, no autopaging, sin `sort_field`. Si solo paginas posts en el index, sirve.

Después: `bundle update`, commit del `Gemfile.lock`, push.

---

## Opción 2 (recomendada): Cambiar al workflow de GitHub Actions y dejar de usar el gem `github-pages`

GitHub recomienda esto desde hace años. Te deshaces de la whitelist y puedes usar **cualquier** plugin de Jekyll, incluyendo `jekyll-paginate-v2`, y además usar una versión de Jekyll más nueva (el gem `github-pages` está congelado en Jekyll 3.9).

### Paso 1: Cambiar la fuente del deploy

En GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions** (no "Deploy from a branch").

### Paso 2: Reemplaza el `github-pages` gem en tu Gemfile

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"

group :jekyll_plugins do
  gem "jekyll-paginate-v2"
  # otros plugins que uses, ej:
  # gem "jekyll-seo-tag"
  # gem "jekyll-feed"
  # gem "jekyll-sitemap"
end

# Windows / JRuby compat (opcional)
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "webrick", "~> 1.8"
```

Luego:
```
bundle update
```
y commitea el nuevo `Gemfile.lock`.

### Paso 3: Crea `.github/workflows/pages.yml`

```yaml
name: Deploy Jekyll site to Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"
          bundler-cache: true
      - uses: actions/configure-pages@v5
      - name: Build with Jekyll
        run: bundle exec jekyll build --baseurl "${{ steps.pages.outputs.base_path }}"
        env:
          JEKYLL_ENV: production
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### Paso 4: Verifica `_config.yml`

Como tu sitio vive en `me.github.io/blog`, asegúrate de tener:

```yaml
url: "https://me.github.io"
baseurl: "/blog"

plugins:
  - jekyll-paginate-v2
  # los demás que uses

pagination:
  enabled: true
  per_page: 10
  permalink: "/page/:num/"
  title: ":title - page :num"
  sort_field: "date"
  sort_reverse: true
```

E importante con paginate-v2: en tu `index.html` (o `index.md`) necesitas el front matter de paginación:

```yaml
---
layout: home
pagination:
  enabled: true
---
```

Sin ese bloque, paginate-v2 no genera las páginas (es uno de los gotchas clásicos al migrar desde v1).

Haz push y mira la pestaña Actions. El job "build" debería instalar `jekyll-paginate-v2` desde tu Gemfile sin reclamar.

---

## Opción 3: Generar el sitio localmente y commitear `_site/`

Funciona pero es feo: tendrías que recordar correr `JEKYLL_ENV=production bundle exec jekyll build` antes de cada push y publicar desde una rama `gh-pages`. No lo recomiendo, la Opción 2 es estrictamente mejor.

---

# TL;DR

`github-pages` (el gem) tiene una whitelist y `jekyll-paginate-v2` no está en ella, por eso falla solo en CI. Migra al workflow oficial de GitHub Actions (Settings → Pages → Source: GitHub Actions), quita `github-pages` del Gemfile, usa `jekyll ~> 4.3` directo, y añade el workflow `pages.yml` de arriba. Con eso `jekyll-paginate-v2` funcionará igual que en local, y de paso te subes a Jekyll 4.
