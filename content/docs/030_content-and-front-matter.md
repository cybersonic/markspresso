---
title: Content and front matter
layout: page
---

## Content and front matter

Markspresso turns Markdown (`.md`) files into HTML pages. Each file can include a front matter block at the top with key–value metadata.

### Basic example

```markdown
---
title: About this site
layout: page
---

# About

This text is written in Markdown and rendered to HTML.
```

Front matter is optional; if omitted, Markspresso uses sensible defaults.

### Front matter format

Front matter is a simple, YAML-like block at the very start of the file:

- Starts with `---` on its own line
- Contains one `key: value` pair per line
- Ends with another `---` line

Comments starting with `##` are ignored inside front matter.

```markdown
---
## This is a comment and will be ignored
title: My Page
layout: page
---

Page content here.
```

### Supported field types

Markspresso does some basic type coercion for values:

- `true` / `false` → booleans
- Numeric values (e.g. `42`, `3.14`) → numbers
- Everything else → strings

This means you can safely write:

```markdown
---
order: 10
featured: true
label: Docs
---
```

### Common front matter fields

These fields are commonly used throughout the system:

- `title` – human-readable page title; also used by navigation and `<title>` tags
- `layout` – which layout template to use (e.g. `page`, `post`)
- `draft` – if `true`, this file is skipped unless you pass `--drafts` or enable `includeDrafts`
- `date` – optional ISO date string for posts (e.g. `2025-01-15`)
- `permalink` – optional URL to prefer as the canonical URL for this page
- `nav_hidden` – if `true`, hide this page from navigation

You can also invent your own keys; anything in front matter is available to layouts as `{{ key }}`.

### Draft content

If you set `draft: true` in front matter, Markspresso will:

- Skip the document by default
- Include it when:
  - `markspresso.json` has `"includeDrafts": true` **or**
  - You pass `--drafts` to the `build` command

This is useful for work-in-progress posts and pages.

### Per-page permalinks

You can override a page's canonical URL using a `permalink` field:

```markdown
---
title: Contact
layout: page
permalink: /contact/
---

Contact details here.
```

This will:

- Use `/contact/` as the canonical URL in navigation
- Still write the physical HTML file into the output directory under a computed path (e.g. `public/contact/index.html`)

### Arbitrary metadata

Any key you add to front matter becomes available in templates. For example:

```markdown
---
title: Pricing
layout: page
plan: Pro
price: 19
showCTA: true
---

# Pricing

Content here.
```

In a layout you can reference these values using `{{ plan }}`, `{{ price }}`, and `{{ showCTA }}`.
