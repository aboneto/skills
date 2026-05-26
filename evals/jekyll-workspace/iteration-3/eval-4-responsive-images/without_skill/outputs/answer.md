# Jekyll Image Optimization Guide

## Gemfile
Add the `jekyll-picture-tag` plugin.
```ruby
gem 'jekyll-picture-tag'
```

## _config.yml
Configure the plugin. This creates responsive images in various sizes and formats (WebP fallback).
```yaml
picture:
  source: assets/images
  output: assets/generated
  formats: [webp, jpg]
  widths: [400, 800, 1200]
```

## Layout (`_layouts/post.html`)
Replace the standard `<img>` tag with the `{% picture %}` liquid tag.
```liquid
{% picture {{ page.hero_image }} --alt "{{ page.title }}" --img lazy %}
```

## Build Pipeline
Netlify automatically runs `bundle install` and `jekyll build`. No additional configuration is required. The plugin processes all images defined in the layout during the build, generating the required WebP files and responsive image sets automatically.
