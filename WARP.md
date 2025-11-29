# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Overview

This repository is a single LuCLI module named `markspresso`. It provides a small static-site generator that "brews" HTML sites from Markdown content when invoked via the `lucli` CLI.

All executable logic lives in `Module.cfc`, which extends the LuCLI `modules.BaseModule` class. The module is intended to be run through LuCLI, not directly as a standalone CFML app.

## Common commands

### Running the module

Use LuCLI to invoke the module:

```bash
lucli markspresso
```

or explicitly via the modules runner:

```bash
lucli modules run markspresso
```

Both forms execute the `main()` method in `Module.cfc`.

### Core subcommands

The module exposes the following subcommands, all rooted at the current working directory (the "site root"):

- **Scaffold a new site**

  ```bash
  lucli markspresso create [--name="My Site"] [--baseUrl=http://localhost:8080] [--force]
  ```

  Creates a `markspresso.json` config plus starter `content/`, `layouts/`, `assets/`, and `public/` directories in the current directory. `--force` allows overwriting existing files like `markspresso.json` and starter content.

- **Build Markdown into HTML**

  ```bash
  lucli markspresso build [--src=content] [--out=public] [--clean] [--drafts]
  ```

  Reads `markspresso.json` if present, merges defaults, then renders Markdown files under the content directory to HTML files under the output directory. `--clean` deletes the output directory before building; `--drafts` includes content marked as `draft: true` in front matter.

- **Serve the built site**

  ```bash
  lucli markspresso serve [--port=8080] [--watch]
  ```

  Intended to serve the `public/` directory over HTTP on the given port, optionally watching for changes. The current implementation is a stub; add the actual HTTP server and file-watching logic inside `serve()`.

- **Create new content**

  ```bash
  lucli markspresso new <type> [--title="My post"] [--slug=my-post]
  ```

  Planned entry point for creating new posts or pages (currently a scaffold with TODO-style comments). Implement the file creation logic in `new()` when extending the module.

### Build, lint, and tests

This module directory does not define standalone build, lint, or test tooling (no `package.json`, test files, or linter configs are present). Development is done by editing `Module.cfc` and exercising behavior through the LuCLI commands above against a sample site.

If you introduce automated tests or linting for this module in the future, prefer to:

- Document the exact commands here (e.g., how to run the full test suite and a single test case).
- Keep test and lint entrypoints at the CLI level so they can be invoked easily from this directory.

## High-level architecture

### Module entrypoints

`Module.cfc` is a single CFML component that serves as the module's entire implementation:

- `init(...)` wires in runtime flags (`verboseEnabled`, `timingEnabled`) and the current working directory (`cwd`), and stores them in `variables`.
- `main()` is the top-level entrypoint when you run `lucli markspresso`. It prints a short description and a usage summary for the subcommands but does not perform work itself.
- Public methods `create`, `build`, `serve`, and `new` correspond directly to LuCLI subcommands:
  - `lucli markspresso create`
  - `lucli markspresso build`
  - `lucli markspresso serve`
  - `lucli markspresso new ...`

LuCLI is responsible for instantiating `Module.cfc` and routing CLI invocations to these methods.

### Site configuration (`markspresso.json`)

The `create()` command both establishes directory structure and writes a `markspresso.json` configuration file. The config schema (as written in `create()` and consumed by `build()`) is:

- Top-level fields:
  - `name`: Human-readable site name.
  - `baseUrl`: Base URL for the site (used for links or future features).
- `paths` object:
  - `content`: Relative path to the Markdown content directory (default `content`).
  - `layouts`: Relative path to HTML layout templates (default `layouts`).
  - `assets`: Relative path to static assets (default `assets`).
  - `output`: Relative path to the build output directory (default `public`).
- `build` object:
  - `defaultLayout`: Fallback layout name when a Markdown file does not specify one (default `page`).
  - `prettyUrls`: Whether to emit `.../index.html` URLs instead of flat `.html` files.
  - `includeDrafts`: Whether to include content marked as drafts by default.
- `collections` object (initially only `posts`):
  - `path`: Subdirectory under `content` for that collection.
  - `layout`: Layout name for that collection.
  - `permalink`: Permalink pattern (e.g., `/posts/:slug/`).

`build()` reads `markspresso.json` if present and passes it through `applyConfigDefaults()`, which fills in any missing sections or fields so the rest of the pipeline can assume a complete config object.

### Build pipeline (Markdown → HTML)

The `build()` method orchestrates the static-site build process:

1. **Determine directories**
   - Computes absolute paths for `content`, `layouts`, `assets`, and `output` by combining `siteRoot()` with the config (overridden by CLI flags for content/output).
2. **Prepare output**
   - Optionally deletes the output directory when `--clean` is passed, then recreates it.
   - Copies all files from `assets` to the output tree using `copyAssets()`.
3. **Discover and parse Markdown**
   - Recursively lists `*.md` files under the content directory.
   - For each file, `parseMarkdownFile()`:
     - Reads the file, splits off a front-matter block if present via `parseFrontMatter()`.
     - Coerces simple scalar types in front matter (booleans, numbers) into native CFML types.
     - Skips drafts unless `includeDrafts` is true.
     - Feeds the Markdown body into `renderMarkdown()` to produce very simple HTML.
4. **Layout and output**
   - For each parsed document, `build()`:
     - Selects a layout name from `meta.layout` or `config.build.defaultLayout`.
     - Loads the corresponding HTML from the layouts directory (or falls back to `{{ content }}` if missing).
     - Calls `applyLayout()` to perform token replacement for `{{ key }}` and `{{key}}` using the merged metadata plus an injected `content` field.
     - Computes the final output path via `computeOutputPath()`, which applies `prettyUrls` rules to decide whether to write to `.../index.html` or `.../<slug>.html`.
     - Ensures the output directory for the file exists and writes the final HTML.

This pipeline is deliberately simple: file system traversal and IO are kept inside `build()`, while parsing, transformation, and templating are factored into small helper functions.

### Markdown and layout helpers

Key private helpers in `Module.cfc` define the rendering and templating behavior:

- `parseFrontMatter(contents)`
  - Detects a leading `---` block, extracts key/value lines until the closing `---`, and returns `{ meta, body }`.
  - Treats lines starting with `##` inside front matter as comments.
  - Coerces `true`/`false` and numeric values.

- `renderMarkdown(src)`
  - Very minimal Markdown support focused on headings and paragraphs.
  - Splits the body into lines and converts them into `<h1>`, `<h2>`, `<h3>`, and `<p>` tags, buffering paragraph text until a blank line.

- `applyLayout(layoutHtml, meta, contentHtml)`
  - Builds a data struct from front-matter metadata plus a `content` field containing the rendered HTML.
  - Performs naive string replacement of `{{ key }}` / `{{key}}` tokens with corresponding values.

- `computeOutputPath(outputDir, relPath, prettyUrls)`
  - Normalizes path separators, strips the original file extension, and returns either `outputDir/<path>/index.html` (pretty URLs) or `outputDir/<path>.html`.

These helpers are the main extension points if you need to:

- Support richer Markdown syntax or additional front-matter types.
- Add more advanced templating capabilities.
- Change URL structure or output layout behavior.

### Utility helpers and conventions

- `siteRoot()`
  - Resolves the effective root directory for commands, preferring the `cwd` passed into `init()` (from LuCLI) and falling back to the directory of `Module.cfc`.
- `out()` and `verbose()`
  - Centralized output helpers; `verbose()` respects the `verboseEnabled` flag, and `out()` pretty-prints complex values as JSON.
- `ensureDir()`, `writeFileIfMissing()`, `copyAssets()`
  - Encapsulate file system operations for directory creation, safe file writes, and recursive asset copying.

When extending this module, prefer to reuse these helpers rather than duplicating raw file IO and string handling in new functions.
