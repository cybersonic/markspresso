---
title: Building and CI
layout: page
---

## Building and CI

This page shows how to automate Markspresso builds, with a concrete example using GitHub Actions and GitHub Pages.

### Basic build recap

Locally, you build your site from the project root with:

```bash
lucli markspresso build --clean
```

By default this renders Markdown from `content/` into HTML under `public/`, and copies any assets from `assets/`.

For CI you typically want to:

- Run the same `build` command on every push (often only on `main`)
- Publish the `public/` directory as your site output

### GitHub Pages with GitHub Actions

The typical pattern is:

1. Commit your Markspresso site into a GitHub repository
2. Configure GitHub Pages to serve from a branch or from the GitHub Actions build output
3. Add a GitHub Actions workflow that runs `lucli markspresso build` and uploads `public/`

#### 1. Choose a Pages "source"

In your repository settings under **Pages**, choose a source. Two common options are:

- **Deploy from a branch** – e.g. branch `gh-pages`, folder `/`.
- **GitHub Actions** – recommended when you want a dedicated workflow to control the build.

The examples below assume you select **GitHub Actions** and let the workflow publish your site.

#### 2. Example GitHub Actions workflow (using the LuCLI Docker image)

This repository ships with a ready-to-use workflow at `.github/workflows/markspresso-pages.yml` that runs everything inside a LuCLI Docker image. A simplified version looks like:

```yaml
name: Build and deploy Markspresso site

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    name: Build static site
    runs-on: ubuntu-latest

    # Run all steps inside a LuCLI Docker image
    container:
      image: markdrew/lucli:latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4

      - name: Install Markspresso
        run: lucli module install markspresso

      - name: Build Markspresso site
        run: |
          # If your site lives in a subdirectory, cd into it first
          # cd path/to/site-root
          lucli markspresso build clean

      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          # Point this at your Markspresso output directory.
          # In this docs site we build into `docs/`.
          path: docs

  deploy:
    name: Deploy to GitHub Pages
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - name: Deploy
        id: deployment
        uses: actions/deploy-pages@v4
```

Key points:

- The whole job runs inside the `markdrew/lucli:latest` container, so you don’t have to install Java or LuCLI manually.
- Markspresso itself is installed with `lucli module install markspresso` inside the container.
- `lucli markspresso build clean` performs the site build; adjust the command or add flags as needed.
- The `path` passed to `upload-pages-artifact` must match your configured output directory (for many sites this will be `public/`, for this docs site it is `docs/`).

Once this workflow is committed and GitHub Pages is configured to use **GitHub Actions**, every push to `main` will rebuild and redeploy your Markspresso site.

### Customizing for your project

You can adapt the example to your needs:

- Change the trigger (e.g. run only on tags, or on pushes to a `docs` branch).
- Add a matrix build if you want to test multiple Java/Lucee versions.
- Run extra checks before deploy, such as link checking or custom scripts.

The important part is that CI runs `lucli markspresso build` from the site root and publishes the resulting `public/` directory.