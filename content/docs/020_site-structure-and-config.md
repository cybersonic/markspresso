---
title: Site structure and configuration
layout: page
---

## Site structure and configuration

Markspresso expects a simple, conventional directory layout. You can customize it via `markspresso.json`.

### Default layout

When you run `lucli markspresso create`, your site root is populated with:

- `markspresso.json` – main configuration file
- `content/` – Markdown content
  - `index.md` – home page
  - `posts/hello-world.md` – starter post
- `layouts/` – HTML layout templates
  - `page.html` – default page layout
  - `post.html` – default post layout
  - `partials/` – shared partial templates for header, footer, etc.
- `assets/` – static files (CSS, images, JS) copied as-is into the build output
- `public/` – output directory for generated HTML

You can move these around by editing `markspresso.json`.

### `markspresso.json` schema

A minimal config looks like this:

```json
{
  "name": "My Site",
  "baseUrl": "http://localhost:8080",
  "paths": {
    "content": "content",
    "layouts": "layouts",
    "assets": "assets",
    "output": "public"
  },
  "build": {
    "defaultLayout": "page",
    "prettyUrls": true,
    "includeDrafts": false,
    "latestPostsCount": 5
  },
  "collections": {
    "posts": {
      "path": "posts",
      "layout": "post",
      "permalink": "/posts/:slug/"
    }
  }
}
```

#### `paths`

- `content` – where Markspresso looks for Markdown files
- `layouts` – where it looks for layout templates
- `assets` – copied recursively into the output directory
- `output` – where generated HTML is written

#### `build`

- `defaultLayout` – name of the layout used when a document does not specify `layout` in front matter
- `prettyUrls` – if `true`, non-index pages are written to `path/to/page/index.html` instead of `path/to/page.html`
- `includeDrafts` – if `true`, include `draft: true` docs even without the `--drafts` flag
- `latestPostsCount` – how many latest posts to inject into the home page as `{{ latest_posts }}`

#### `collections`

Collections group related content under a subdirectory and layout.

Each collection entry has:

- `path` – subdirectory under `content/`
- `layout` – layout name to use by default
- `permalink` – pattern for canonical URLs; `:slug` is replaced with the document slug

The default `posts` collection maps to `content/posts/` and uses the `post` layout.

### Optional navigation config

If you want your navigation to only include a subset of content (for example, everything under `content/docs`), you can add a `navigation` block:

```json
{
  "navigation": {
    "rootPath": "docs"
  }
}
```

When `rootPath` is set, navigation will only be built from documents whose relative paths start with `docs/`.

### Overriding paths with CLI flags

CLI flags can temporarily override configuration values:

- `lucli markspresso build --src=docs` – treat `docs/` as the content root
- `lucli markspresso build --out=dist` – write HTML into `dist/`

These do not modify `markspresso.json`; they just affect the current build.
