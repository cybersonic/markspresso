---
title: Navigation
layout: page
---

## Navigation

Markspresso can generate a navigation sidebar from your content using filename conventions.

### How navigation is built

Navigation is built from the list of documents discovered during a build. For each document, Markspresso knows:

- `relPath` – path relative to the content root (e.g. `docs/010_getting-started.md`)
- `meta` – front matter
- `canonicalUrl` – the preferred URL for the page

The navigation builder:

- Treats top-level files (e.g. `index.md`) as root items
- Treats one level of nested folders as sections (e.g. everything under `docs/`)
- Ignores deeper nesting beyond two levels

### Numeric prefixes for ordering

You can control ordering with numeric prefixes separated by an underscore:

- `010_getting-started.md`
- `020_site-structure-and-config.md`
- `030_content-and-front-matter.md`

Rules:

- Prefixes are 1–4 digits followed by `_` (e.g. `010_`, `5_`, `1234_`)
- Prefixes are *stripped* from display titles and URLs
- Items without a prefix are sorted after all prefixed items

### Deriving titles

If a document has `title` in front matter, that is used. Otherwise Markspresso:

1. Strips numeric prefixes and file extensions
2. Replaces `-` and `_` with spaces
3. Title-cases each word

Examples:

- `010_introduction.md` → `Introduction`
- `020_server-management.md` → `Server Management`

### Hiding items from navigation

To hide a page from navigation, add `nav_hidden: true` in front matter:

```markdown
---
title: Internal notes
layout: page
nav_hidden: true
---

This page will not appear in the sidebar.
```

### Scoping navigation to a sub-tree

If you only want navigation for a subset of your content (for example, everything under `content/docs`), set `navigation.rootPath` in `markspresso.json`:

```json
{
  "navigation": {
    "rootPath": "docs"
  }
}
```

With this setting, only documents whose `relPath` starts with `docs/` contribute to navigation, and the `docs/` prefix is removed when computing section names.

### Docs prev/next pagination tokens

When `navigation.rootPath` is configured, Markspresso also computes reading-order pagination tokens for docs pages:

- `prev_url`
- `prev_title`
- `next_url`
- `next_title`

These are injected into layout data and can be used directly in templates:

```html
<nav class="docs-pagination">
  {{#if prev_url}}
  <a href="{{ prev_url }}">← {{ prev_title }}</a>
  {{/if}}
  {{#if next_url}}
  <a href="{{ next_url }}">{{ next_title }} →</a>
  {{/if}}
</nav>
```

Pagination behavior:

- Enabled by default when `navigation.rootPath` is set.
- Can be disabled with `navigation.pagination: false`.
- Orders pages by numeric filename/folder prefixes (for example `010_`, `020_`).

Example config:

```json
{
  "navigation": {
    "rootPath": "docs",
    "pagination": true
  }
}
```

### Active item highlighting

The navigation HTML includes an `active` class on the `<li>` corresponding to the current page. You can target this in CSS to highlight the current location.
