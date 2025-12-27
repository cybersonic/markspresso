---
title: Navigation
layout: page
---

# Documentation Navigation

Markspresso automatically generates navigation from your content directory structure using a numeric prefix convention. This page explains how to organize your documentation files for optimal navigation.

## File naming convention

Use zero-padded numeric prefixes to control ordering, for example:

```text
010_introduction.md
020_installation.md
030_configuration.md
```

Using `010_`, `020_`, etc. keeps alphabetical and numeric ordering aligned and leaves room for inserts like `015_`.

## Title derivation

By default, titles are derived from filenames by:

1. Removing any numeric prefix (e.g., `010_`).
2. Stripping the file extension.
3. Replacing hyphens/underscores with spaces.
4. Converting to title case.

You can override the derived title with front matter:

```markdown
---
title: Custom Title Here
---
```

## Directory structure

Use a two-level hierarchy for documentation:

- Root files for top-level pages.
- Folders for sections containing related pages.

Deeper nesting is generally ignored by navigation.

## Hiding pages from navigation

To hide a page from navigation, either:

- Add `nav_hidden: true` in front matter, or
- Prefix the filename with an underscore (e.g., `_draft.md`).

## Using navigation in layouts

Layouts can embed navigation with the `{{ navigation }}` placeholder, for example:

```html
<!doctype html>
<html>
  <head>
    <title>{{ title }}</title>
  </head>
  <body>
    {{ navigation }}
    <main>
      {{ content }}
    </main>
  </body>
</html>
```

See the rest of the documentation for more examples and best practices.
