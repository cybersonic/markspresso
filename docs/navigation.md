# Documentation Navigation

Markspresso automatically generates navigation from your content directory structure using a numeric prefix convention. This guide explains how to organize your documentation files for optimal navigation.

## File Naming Convention

Files and folders use **zero-padded numeric prefixes** to control ordering:

```
010_introduction.md
020_installation.md
030_configuration.md
```

### Why Zero-Padding?

Zero-padding (e.g., `010_` instead of `10_`) ensures correct alphabetical sorting:

- ✅ Correct: `"010"` < `"020"` < `"100"`
- ❌ Wrong: `"10"` < `"100"` < `"20"`

### Prefix Format

- **3-digit prefixes** (recommended): `010_`, `020_`, `030_`
- Supports up to 99 items per section (010-990)
- Use **10-gaps** between items for easy insertions

### Inserting Items

With 10-gaps, you can insert items without renumbering:

```
010_first-item.md
020_second-item.md
030_third-item.md
```

Insert a new item between first and second:

```
010_first-item.md
015_inserted-item.md     ← Added without renumbering
020_second-item.md
030_third-item.md
```

For more than 99 items (rare), use 4-digit prefixes: `0100_`, `0200_`, etc.

## Title Derivation

Markspresso automatically derives titles from filenames:

| Filename | Display Title |
|----------|--------------|
| `010_introduction.md` | Introduction |
| `020_server-management.md` | Server Management |
| `ServerManagement.md` | Server Management |

**Rules:**
1. Remove numeric prefix (`010_`)
2. Remove file extension (`.md`)
3. Convert hyphens and underscores to spaces
4. Apply title case to each word

**Override with front matter:**

```markdown
---
title: Custom Title Here
---
```

## Directory Structure

Use a **2-level hierarchy**:

- **Root files**: Top-level pages
- **Folders**: Sections containing related pages
- Deeper nesting is ignored

### Example Structure

```
content/
  index.md                           # Home page
  010_getting-started/
    010_introduction.md              # Getting Started > Introduction
    020_installation.md              # Getting Started > Installation
    030_quick-start.md               # Getting Started > Quick Start
  020_guides/
    010_server-management.md         # Guides > Server Management
    020_module-development.md        # Guides > Module Development
    030_cfml-scripting.md            # Guides > CFML Scripting
  030_reference/
    010_cli-commands.md              # Reference > CLI Commands
    020_configuration.md             # Reference > Configuration
```

### Folder Titles

Folder names follow the same naming convention as files:

- `010_getting-started/` → "Getting Started"
- `020_guides/` → "Guides"

## Generated Navigation

Markspresso generates HTML navigation automatically:

```html
<nav class="docs-nav">
  <ul>
    <li><strong>Getting Started</strong>
      <ul>
        <li><a href="/getting-started/introduction/">Introduction</a></li>
        <li><a href="/getting-started/installation/">Installation</a></li>
        <li><a href="/getting-started/quick-start/">Quick Start</a></li>
      </ul>
    </li>
    <li><strong>Guides</strong>
      <ul>
        <li><a href="/guides/server-management/">Server Management</a></li>
        <li><a href="/guides/module-development/">Module Development</a></li>
        <li><a href="/guides/cfml-scripting/">CFML Scripting</a></li>
      </ul>
    </li>
  </ul>
</nav>
```

## Active Page Highlighting

The current page is automatically highlighted with an `active` class:

```html
<li class="active"><a href="/guides/server-management/">Server Management</a></li>
```

Style active pages in your layout CSS:

```css
.docs-nav li.active > a {
  font-weight: bold;
  color: #0066cc;
}
```

## URL Generation

URLs are clean and semantic, with numeric prefixes removed:

| File | URL |
|------|-----|
| `010_introduction.md` | `/introduction/` |
| `020_guides/010_basics.md` | `/guides/basics/` |

## Hiding Pages from Navigation

Hide pages from navigation using front matter:

```markdown
---
nav_hidden: true
---
```

Or use an underscore prefix (without a number):

- `_template.md` → Hidden
- `_draft.md` → Hidden

## Using Navigation in Layouts

The `{{ navigation }}` placeholder is automatically available in all layouts:

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

## Configuration

Optionally configure navigation in `markspresso.json`:

```json
{
  "navigation": {
    "rootPath": "docs"
  }
}
```

- `rootPath`: Only include files under this path in navigation (e.g., exclude blog posts)

## Best Practices

1. **Use 10-gaps**: Start with `010_`, `020_`, `030_` for easy insertions
2. **Descriptive names**: Use kebab-case for multi-word filenames
3. **Consistent structure**: Keep hierarchy to 2 levels maximum
4. **Override when needed**: Use front matter `title:` for special cases
5. **Test locally**: Run `lucli markspresso watch` to see changes live

## Example Documentation Site

Here's a complete example for a typical documentation site:

```
content/
  index.md                           # Homepage (not in nav)
  docs/
    010_introduction.md              # First page
    020_installation.md
    030_quick-start.md
    040_concepts/
      010_architecture.md
      020_components.md
      030_workflows.md
    050_guides/
      010_basic-usage.md
      020_advanced-features.md
      030_best-practices.md
    060_api/
      010_rest-api.md
      020_cli-reference.md
    070_troubleshooting.md
```

This structure creates clear, navigable documentation with automatic ordering and titles.
