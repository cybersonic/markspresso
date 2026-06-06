---
title: Themes and previews
layout: page
---

## Themes and previews

Markspresso supports theme-based rendering so you can switch complete visual systems without changing content.

### Enable a theme

Set `theme` in `markspresso.json`:

```json
{
  "theme": "tailwind"
}
```

Then build:

```bash
lucli markspresso build
```

### Theme resolution order

For a selected theme name (for example `retro-wave`), Markspresso resolves files in this order:

1. Site override paths (`paths.layouts`, `paths.assets`)
2. `themes/<theme-name>/` in your site root
3. `themes/<theme-name>/` in the Markspresso module
4. Final fallback behavior (inline content layout)

For layouts, site-local files win over theme files when both exist.

### Theme package structure

A theme typically contains:

- `theme.json`
- `layouts/home.html`
- `layouts/page.html`
- `layouts/post.html`
- `partials/header.html`
- `partials/footer.html`
- optional `assets/` (for theme-specific CSS/JS/images)

Example:

```text
themes/
  tailwind/
    theme.json
    layouts/
      home.html
      page.html
      post.html
    partials/
      header.html
      footer.html
    assets/
      css/
```

### Built-in themes

Current built-in theme set includes:

- `default`
- `bootstrap`
- `bulma`
- `tailwind`
- `pico`
- `sakura`
- `simple-css`
- `terminal`
- `css-98`
- `retro-wave`

List available themes at any time:

```bash
lucli markspresso previewtheme build=false
```

### Previewing a single theme quickly

Use `previewtheme`:

```bash
lucli markspresso previewtheme theme=retro-wave
```

This updates `markspresso.json` and (by default) builds.

To switch without building:

```bash
lucli markspresso previewtheme theme=retro-wave build=false
```

### Generating side-by-side previews for all themes

Use `previewallthemes`:

```bash
lucli markspresso previewallthemes
```

This will:

- build each theme into `docs/_previews/<theme-name>/`
- generate `docs/_previews/index.html` with iframe cards for comparison
- restore your original `markspresso.json` after the run

Open:

- `/_previews/index.html` from your static server

You can change the output base directory:

```bash
lucli markspresso previewallthemes baseOutDir=docs/_theme-previews
```

### Notes for preview mode

- Preview builds rewrite root-absolute links (`/...`) to preview-relative URLs so assets and internal links work inside each `/_previews/<theme>/` subdirectory.
- `previewallthemes` also disables site layout overrides during preview generation so each card reflects the selected theme’s own layouts.
