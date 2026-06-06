---
title: Getting started
layout: page
---

## Getting started with Markspresso

This guide shows how to scaffold a new site, run a build, and iterate on your content.

### Prerequisites

- LuCLI installed and on your `PATH`.
- A directory where you want your static site to live (your "site root").


## Installing Markspresso

```bash
lucli install markspresso
```

From your site root, you will run commands via LuCLI:

```bash
lucli markspresso --help
```

### 1. Scaffold a new site

From an empty directory:

```bash
lucli markspresso create --name "My Site" --baseUrl "http://localhost:8080"
```

This will create:

- `markspresso.json` – site configuration
- `content/` – Markdown content (including `index.md` and `posts/hello-world.md`)
- `layouts/` – HTML layouts (`page.html`, `post.html`) and `layouts/partials/`
- `assets/` – static files to be copied as-is
- `public/` – build output directory (initially empty)
- `lucee.json` – convenience config for serving the `public/` directory from LuCLI

You can re-run `create` with `--force` to overwrite existing starter files.

### 2. Build Markdown into HTML

From the same directory:

```bash
lucli markspresso build
```

By default this will:

- Read `markspresso.json` and apply sensible defaults
- Treat `content/` as your source and `public/` as your output
- Render all `*.md` files to HTML using the configured layouts
- Copy any files under `assets/` into `public/`

Useful flags:

- `--src=content` – override the content directory
- `--out=public` – override the output directory
- `--clean` – delete the output directory before building
- `--drafts` – include content marked as `draft: true` in front matter

### 3. Serve the built site

Markspresso builds a static site into `public/`. You can serve it with any static HTTP server you like.

Because `create` also writes a `lucee.json` that points at the output directory, you can use LuCLI's own tooling or your preferred static server to host `public/`.

### 4. Watch for changes

For an efficient local workflow, use the watch command from your site root:

```bash
lucli markspresso watch
```

Markspresso will:

- Run an initial full build
- Watch `content/`, `layouts/`, and `assets/`
- On content changes, trigger incremental rebuilds of the changed files (plus home page when needed)
- On layout changes, trigger a full rebuild
- On asset changes, copy changed assets to `public/`

### 5. Next steps

Once you have your first build working, continue with:

- **Site structure & configuration** – how `markspresso.json` controls paths and collections
- **Content & front matter** – how to attach metadata to documents
- **Layouts & partials** – customizing HTML output
- **Posts & pages** – using Markspresso as a lightweight blog engine
