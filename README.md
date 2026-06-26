     
# markspresso
![MarkSprsso Logo](assets/markspresso-logo.png)


Brew up great static sites from Markdown.

Markspresso is a LuCLI module that turns a directory of Markdown files into a simple static HTML site using minimal layouts and front matter.

## Installation

Markspresso is distributed as a LuCLI module. Once it is available in your LuCLI environment, you run it via the `lucli` CLI; there is nothing to install in a project.

```bash
lucli install markspresso url=https://github.com/cybersonic/markspresso.git
```

## Quick start

From an empty or existing project directory:

```bash
# 1. Scaffold a new Markspresso site in the current directory
lucli markspresso create name="My Site" baseUrl=http://localhost:3456

# 2. Build Markdown content into HTML under public/
lucli markspresso build clean

# 3. Watch for changes and auto-rebuild
lucli markspresso watch

# 4. (Optional) Serve the built site over HTTP
lucli server start
```

After running `create`, you will have:

- `markspresso.json` – site configuration.
- `lucee.json` – LuCLI server configuration (points to `public/` webroot).
- `content/` – Markdown source files (with starter `index.md` and `posts/hello-world.md`).
- `layouts/` – HTML layouts (`page.html`, `post.html`).
- `assets/` – static files copied as-is.
- `public/` – build output directory.

## Configuration: `markspresso.json`

`markspresso.json` controls how Markspresso locates content, layouts, and assets, and how it builds URLs and output HTML. It is created for you by `lucli markspresso create` and then read by `lucli markspresso build`.

A typical config looks like:

```json
{
  "name": "My Site",
  "baseUrl": "http://localhost:3456",
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

Key fields:

- `name` – human-readable site name, used in starter content.
- `baseUrl` – the base URL for your site; useful for links or future features.
- `paths.content` – where Markdown files live (relative to the site root).
- `paths.layouts` – where HTML layout templates live.
- `paths.assets` – static files that will be copied into the output tree.
- `paths.output` – directory where built HTML is written.
- `build.defaultLayout` – layout used when a Markdown file does not specify `layout` in front matter.
- `build.prettyUrls` – when `true`, non-`index` pages are written as `.../slug/index.html`.
- `build.includeDrafts` – global default for including `draft: true` content (overridden by the `drafts` flag).
- `build.latestPostsCount` – number of recent posts to show in the `{{ latest_posts }}` token (default: 5).
- `collections.posts` – example collection for blog posts; defines a subdirectory (`path`), default layout, and permalink pattern.
- `globals` – optional key/value map of site-wide variables available in layouts.
- `socialImages` – optional per-page PNG generation (Java2D) that can be used for `og:image` and hero/header images.

### Globals

You can define global variables under a top-level `globals` object in `markspresso.json`. These values are injected into every layout using a simple namespaced token:

```json
{
  "globals": {
    "blogName": "My Blog",
    "tagline": "Thoughts on CFML and more"
  }
}
```

In your layout templates, reference them using `globals.*` tokens:

```html
<title>{{ globals.blogName }}</title>
<p>{{ globals.tagline }}</p>
```

### Navigation configuration

Markspresso automatically generates navigation from your content directory structure. You can configure navigation behavior in `markspresso.json`:

```json
{
  "navigation": {
    "rootPath": "docs",
    "pagination": true
  }
}
```

- `navigation.rootPath` – Only include files under this path in navigation (e.g., to exclude blog posts from the navigation tree).
- `navigation.pagination` – Controls docs prev/next pagination tokens (`prev_url`, `prev_title`, `next_url`, `next_title`) when `rootPath` is set. Enabled by default unless explicitly set to `false`.

Markspresso uses a numeric prefix convention to control ordering:

```
content/
  010_getting-started/
    010_introduction.md
    020_installation.md
  020_guides/
    010_basic-usage.md
    020_advanced-features.md
```

Files are ordered by their numeric prefix, and titles are automatically derived by removing the prefix and converting hyphens/underscores to title case. For complete details on organizing content for navigation, see [docs/navigation.md](docs/navigation.md).

If fields are missing, Markspresso applies sensible defaults in code so that a partial `markspresso.json` still works.

### Social image generation (fast local MVP)

Markspresso can generate one image per page during `build`, without Playwright/Chromium, using Java2D.

Example config:

```json
{
  "socialImages": {
    "enabled": true,
    "width": 1200,
    "height": 630,
    "outputDir": "social-images",
    "titleMaxLines": 3,
    "descriptionMaxLines": 3,
    "overrideOgImage": false,
    "backgroundStartColor": "#0f172a",
    "backgroundEndColor": "#1d4ed8",
    "accentColor": "#60a5fa"
  }
}
```

Behavior:
- Generates `public/social-images/...png` per page.
- Uses front matter/content in this order:
  - title: `social_title` → `og_title` → `title`
  - description: `social_description` → `og_description` → `description` → `subtitle` → first paragraph
- Injects generated path into:
  - `hero_image` (if missing)
  - `image` (if missing)
  - `og_image` / `twitter_image` (if missing, or always when `overrideOgImage: true`)
- Per-page opt-out: set `social_image: false` in front matter.

### PDF configuration

Markspresso can generate documentation PDFs through `lucli markspresso pdf`.

Example config:

```json
{
  "pdf": {
    "enabled": true,
    "output": "docs.pdf",
    "rootPath": "docs",
    "title": "My Documentation",
    "author": "Docs Team",
    "pageSize": "A4",
    "orientation": "portrait",
    "tocEnabled": true,
    "headerHtml": "<div>{{ title }} — {{ currentChapterTitle }}</div>",
    "footerHtml": "<div>Page {{ currentSectionPage }} of {{ totalSectionPages }}</div>"
  }
}
```

Token support in `headerHtml` / `footerHtml` includes:
- `{{ title }}`
- `{{ author }}`
- `{{ currentChapterTitle }}`
- `{{ currentPage }}`
- `{{ totalPages }}`
- `{{ currentSectionPage }}`
- `{{ totalSectionPages }}`

## CLI Reference

All commands are executed from the site root (where `markspresso.json` lives).

### `lucli markspresso` (no subcommand)

Prints a short description plus a summary of available subcommands.

### `lucli markspresso create`

Scaffolds a Markspresso site in the current working directory.

```bash
lucli markspresso create [name="My Site"] [baseUrl=http://localhost:3456] [force]
```

- `name` – human-readable site name used in starter content.
- `baseUrl` – base URL for the site.
- `force` – overwrite existing config and starter files if they already exist.

### `lucli markspresso build`

Builds the site by rendering Markdown under `content/` to HTML under `public/`.

```bash
lucli markspresso build [src=content] [outDir=public] [clean] [drafts] [dev]
```

- `src` – content directory (relative to site root). Defaults to `content` or `paths.content` in `markspresso.json`.
- `outDir` – output directory. Defaults to `public` or `paths.output`.
- `clean` – delete the output directory before building.
- `drafts` – include content marked `draft: true` in front matter.
- `dev` – enable dev-mode auto-reload script injection (`/js/markspresso-refresh.js`).

Notes on output paths:

- `content/index.md` → `public/index.html`.
- `content/blog/index.md` → `public/blog/index.html`.
- Other files (e.g. `content/about.md`) use "pretty" URLs: `public/about/index.html`.

### `lucli markspresso watch`

Watches for changes to content and layout files and automatically rebuilds the site.

```bash
lucli markspresso watch [numberOfSeconds=1] [dev]
```

- `numberOfSeconds` – interval in seconds to check for file changes (default is 1 second).
- `dev` – emit live-reload markers (`__markspresso_reload.json`) and inject the reload script.

This command monitors your `content/`, `layouts/`, and `assets/` directories and automatically runs a rebuild whenever changes are detected. Perfect for development workflows.

### `lucli markspresso serve`

Starts a local HTTP server via LuCLI.

```bash
lucli markspresso serve [port=3456]
```

- `port` – HTTP port to run the local server on.

### `lucli markspresso geturl`

Resolves the canonical URL for a content file relative to your configured content root.

```bash
lucli markspresso geturl content=posts/2025-12-30-my-post.md [pathOnly=true]
```

- `content` – relative path under `paths.content` to a markdown file.
- `pathOnly` – when `true`, returns just the canonical path (for example `/posts/my-post/`) instead of `baseUrl + path`.

### `lucli markspresso pdf`

Builds a PDF from docs content (excluding posts by default).

```bash
lucli markspresso pdf [rootPath=docs] [outFile=docs.pdf] [drafts] [toc=true]
```

- `rootPath` – subdirectory under `paths.content` to include (defaults to `pdf.rootPath` or `docs`).
- `outFile` – output PDF filename/path under the site root.
- `drafts` – include draft docs.
- `toc` – include table of contents.

### `lucli markspresso theme`

Lists or applies themes, and can generate preview comparisons.

```bash
lucli markspresso theme [--list] [--name=retro-wave] [--build=true|false] [--preview] [--previewOutDir=docs/_previews]
```

Examples:

```bash
# List themes
lucli markspresso theme --list

# Set active theme without building
lucli markspresso theme --name=retro-wave --build=false

# Build side-by-side previews for all themes
lucli markspresso theme --preview --previewOutDir=docs/_previews
```

Backward-compatible aliases:

```bash
lucli markspresso previewtheme theme=retro-wave build=false
lucli markspresso previewallthemes baseOutDir=docs/_previews
```

### `lucli markspresso new`

Creates new content files with front matter.

```bash
lucli markspresso new type=posts title="My Post Title"
lucli markspresso new type=page title="About Us" slug=about
```

- `type` – content type, typically `posts` for blog posts or `page` for pages. Must match a collection name in `markspresso.json` or be a generic type.
- `title` – human-readable title used in front matter and to generate the slug.
- `slug` – URL-friendly slug; if omitted, automatically generated from the title.

**Posts** are created with:
- Date-prefixed filename: `YYYY-MM-DD-slug.md`
- Front matter including `date` and `draft: true`
- Placed in `content/posts/` directory

**Pages** are created with:
- Simple filename: `slug.md`
- Basic front matter with title and layout
- Placed in `content/` directory

## Example workflow

From a fresh scaffolded site:

```bash
# Create the site structure and starter content
lucli markspresso create name="My Site"

# Edit the home page content in your editor
$EDITOR content/index.md

# Rebuild the site (clean ensures a fresh public/ tree)
lucli markspresso build clean

# Confirm the output exists at the expected location
ls public/index.html
```

You can then open `public/index.html` in a browser or point a simple HTTP server at the `public/` directory.

## Front matter and layouts

Each Markdown file may start with a YAML-like front matter block:

```markdown
---
title: My page
layout: page
draft: false
---

# Heading

Some content.
```

- `title` – used by the layout for the `<title>` tag and headings.
- `layout` – name of the layout file (e.g. `page` → `layouts/page.html`). Falls back to `build.defaultLayout`.
- `draft` – when `true`, the file is skipped unless `drafts` or `build.includeDrafts` is enabled.

Layouts are plain HTML files that use `{{ title }}` and `{{ content }}` placeholders; Markspresso performs a simple string replacement to inject values from front matter and the rendered HTML content.

## Organizing blog posts

Blog posts are typically organized in a `posts/` subdirectory under `content/`. Unlike documentation pages that use numeric prefixes for navigation ordering, blog posts are usually date-based:

```
content/
  posts/
    2024-01-15-hello-world.md
    2024-02-20-announcing-version-2.md
    2024-03-10-tips-and-tricks.md
```

Each post should include front matter with at least:

```markdown
---
title: Hello, World
layout: post
draft: false
date: 2024-01-15
---

Your post content here.
```

- `title` – the post title displayed on the page and in listings.
- `layout` – typically `post` to use the post layout template.
- `draft` – set to `true` to exclude from builds (unless `--drafts` flag is used).
- `date` – publication date (optional but useful for sorting).

Blog posts are part of the `collections.posts` configuration and use the `posts` collection layout and permalink pattern defined in `markspresso.json`.
