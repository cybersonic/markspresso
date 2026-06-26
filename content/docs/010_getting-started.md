---
title: Getting started
layout: page
---
## Getting started with Markspresso

This guide shows how to scaffold a new site, run a build, and iterate on your content.

### Prerequisites

- A Markspresso CLI available in your shell:
  - standalone `markspresso` binary, or
  - `lucli` with Markspresso installed as a module.
- If you plan to use `serve` through LuCLI, ensure Java 21+ is installed and `JAVA_HOME` is set.
- A directory where you want your static site to live (your "site root").

## Install / verify the CLI

If you are using the standalone binary:

```bash
markspresso --help
```

If you are using LuCLI:

```bash
lucli install markspresso
lucli markspresso --help
```

### 1. Scaffold a new site

From an empty directory:

```bash
markspresso create --name "My Site" --baseUrl "http://localhost:8080"

# or via LuCLI
lucli markspresso create --name "My Site" --baseUrl "http://localhost:8080"
```

This will create:

- `markspresso.json` – site configuration
- `content/` – Markdown content (including `index.md` and starter posts)
- `layouts/` – HTML layouts (`page.html`, `post.html`) and `layouts/partials/`
- `assets/` – static files to be copied as-is
- `public/` – build output directory (initially empty)
- `lucee.json` – optional server config used when serving through LuCLI

You can re-run `create` with `--force` to overwrite existing starter files.

### 2. Build Markdown into HTML

From the same directory:

```bash
markspresso build

# or via LuCLI
lucli markspresso build
```

By default this will:

- Read `markspresso.json` and apply sensible defaults
- Treat `content/` as your source and `public/` as your output
- Render all `*.md` files to HTML using the configured layouts
- Copy any files under `assets/` into `public/`

Useful flags:

- `--src=content` – override the content directory
- `--outDir=public` – override the output directory
- `--clean` – delete the output directory before building
- `--drafts` – include content marked as `draft: true` in front matter
- `--dev` – inject dev auto-reload script support

### 3. Serve the built site

Markspresso builds a static site into `public/` (or your configured output path). You can serve it with any static HTTP server.

```bash
markspresso serve

# or via LuCLI
lucli markspresso serve
```

### 4. Watch for changes

For an efficient local workflow, use watch mode from your site root:

```bash
markspresso watch

# or via LuCLI
lucli markspresso watch
```

Markspresso will:

- Run an initial full build
- Watch `content/`, `layouts/`, and `assets/`
- On content changes, trigger incremental rebuilds of changed files
- On layout changes, trigger a full rebuild
- On asset changes, copy changed assets to the output directory

### 5. Next steps

Once you have your first build working, continue with:

- **Site structure & configuration** – how `markspresso.json` controls paths and collections
- **Themes and previews** – configuring themes and generating side-by-side preview builds
- **Content & front matter** – how to attach metadata to documents
- **Layouts & partials** – customizing HTML output
- **Posts & pages** – using Markspresso as a lightweight blog engine
- **PDF and URL utilities** – generating documentation PDFs and resolving canonical URLs from content files
