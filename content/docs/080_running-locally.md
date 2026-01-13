---
title: Running the built site locally
layout: page
---

## Running the built site locally

After building your Markspresso site, you will usually want to preview the static output in a browser using a simple HTTP server.

### 1. Build your site

From your site root, run:

```bash
lucli markspresso build --clean
```

By default this will write the generated HTML into `public/`. In this project (the Markspresso docs itself), the output is configured to `docs/`, but the commands below work the same way regardless of the output directory.

### 2. Start a local server with LuCLI

Use LuCLI's `server start` command to serve the built output directory:

```bash
lucli server start --disable-lucee ./public
```

or, if your `markspresso.json` is configured to output into `docs/` (like this repository):

```bash
lucliserver start --disable-lucee ./docs
```

Then open the printed URL (usually `http://localhost:8888/` or similar) in your browser.

### Why `--disable-lucee`?

Passing `--disable-lucee` tells the Lucee server to treat the directory as a **pure static site**:

- Static assets and `.html` files are served directly by the web server.
- CFML processing is turned off, so CFML templates (`.cfm`, `.cfc`) are not executed.

For Markspresso output this is exactly what you want: the final HTML that Markspresso generated should take priority and be served as-is, without any Lucee/CFML processing getting in the way.

### 3. Iterating while you work

A common workflow when writing docs or posts is:

1. Run `lucli markspresso watch` in one terminal to rebuild on changes.
2. Run `lucli server start --disable-lucee ./public` (or `./docs`) in another terminal.
3. Edit Markdown/layouts and refresh your browser to see the latest build.
