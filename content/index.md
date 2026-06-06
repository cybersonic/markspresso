---
title: Brew beautiful static sites with Markspresso
layout: home
description: Markspresso helps you build polished docs, launch pages, and blogs from Markdown with a fast CLI workflow.
cta_primary_label: Read the quick start
cta_primary_url: /docs/getting-started/
cta_secondary_label: Explore on GitHub
cta_secondary_url: https://github.com/cybersonic/markspresso
nav_hidden: true
---
## What you get out of the box

Markspresso is designed for developers who want clean output, simple authoring, and no frontend build-tool overhead. Write Markdown, apply a layout, and ship.

<div class="feature-grid">
  <article class="feature-card">
    <h3>Markdown-first publishing</h3>
    <p>Create docs and pages quickly with front matter for metadata, layouts, and draft control.</p>
  </article>
  <article class="feature-card">
    <h3>Flexible layouts and partials</h3>
    <p>Use HTML or CFML templates, reusable partials, and built-in tokens to shape every page.</p>
  </article>
  <article class="feature-card">
    <h3>Collection-aware URLs</h3>
    <p>Define collections with permalink patterns and ship pretty URLs by default.</p>
  </article>
  <article class="feature-card">
    <h3>Built-in docs navigation</h3>
    <p>Generate side navigation from directory structure and numeric filename ordering.</p>
  </article>
  <article class="feature-card">
    <h3>Search, feeds, and metadata</h3>
    <p>Enable Lunr search, RSS/Atom feeds, and social image generation without extra tooling.</p>
  </article>
  <article class="feature-card">
    <h3>Fast local iteration</h3>
    <p>Use `build`, `watch`, and your preferred static server to edit and preview instantly.</p>
  </article>
</div>

## A workflow that stays simple

<div class="workflow-grid">
  <div class="workflow-step">
    <span class="workflow-step-index">1</span>
    <div>
      <h3>Scaffold</h3>
      <p>Generate a project skeleton with `markspresso.json`, starter content, layouts, and assets.</p>
    </div>
  </div>
  <div class="workflow-step">
    <span class="workflow-step-index">2</span>
    <div>
      <h3>Author</h3>
      <p>Add Markdown pages and posts, then tune navigation and metadata with front matter.</p>
    </div>
  </div>
  <div class="workflow-step">
    <span class="workflow-step-index">3</span>
    <div>
      <h3>Build</h3>
      <p>Render static HTML and copy assets with one command: `markspresso build`.</p>
    </div>
  </div>
  <div class="workflow-step">
    <span class="workflow-step-index">4</span>
    <div>
      <h3>Ship</h3>
      <p>Publish the output folder to GitHub Pages, object storage, or any static host.</p>
    </div>
  </div>
</div>

## Developer-friendly defaults

- Strong configuration defaults with `markspresso.json`.
- Global metadata and reusable list tokens such as the posts list helper.
- Draft filtering in local and CI builds.
- Support for docs, blogs, changelogs, and product updates in one repo.

## Run it your way

- Use `markspresso ...` with a standalone binary.
- Or run through LuCLI with `lucli markspresso ...`.

## Latest from the brew log
<div class="latest-posts-wrap">
{{ latest_posts }}
</div>
