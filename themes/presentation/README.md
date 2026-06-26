# Presentation theme
This theme is designed for single-file, slide-style talks.

## Quick use
1. Set the active theme:
   - `lucli markspresso theme --name=presentation`
2. In your presentation markdown file front matter, set:
   - `layout: presentation`
3. Build:
   - `lucli markspresso build --clean`

## How one Markdown file becomes multiple slides
The `layouts/presentation.html` runtime splits rendered HTML on horizontal rules (`<hr>`).

In markdown, create slide breaks with horizontal-rule syntax, for example:

```markdown
---
title: My Talk
layout: presentation
---

# Slide 1
Intro content

---

# Slide 2
More content

---

# Slide 3
Wrap up
```

Each section between slide breaks is wrapped into its own `<section class="slide">`.

## Slide anchors and reload behavior
- Slides get stable IDs like `slide01`, `slide02`, etc.
- Navigation updates the URL hash (`#slide01`, `#slide02`, ...).
- Reloading keeps your current slide.
- You can deep-link directly to a specific slide by hash.

## Two-column slide layouts
The theme supports both code-first and general two-column slides.

### Code-focused two-column markers
- `<!-- two-col-code -->`
- `<!-- two-col-code-right-40 -->`
- `<!-- two-col-code-left-40 -->`

Code-focused example:

````markdown
## API Example
<!-- two-col-code-right-40 -->

- Point one
- Point two
- Point three

```js
fetch("/api/hello").then(r => r.json()).then(console.log);
```
````

When bullet reveal is enabled, code now reveals after the bullet points for that slide.

## Code line highlighting
To highlight specific lines in fenced code blocks, place an HTML comment directly above the code block:

````markdown
<!-- hl: 2,4-6 -->
```js
const a = 1;
const b = 2;
const c = a + b;
console.log(c);
```
````

Supported format:
- single line: `2`
- ranges: `4-6`
- line span (zero-based columns, inclusive): `1:0-10`
- mixed: `1:0-10,2,4-6,9`

This works in both the audience slide view and presenter preview.

### Generic two-column markers (non-code)
- `<!-- two-col -->`
- `<!-- two-col-right-40 -->`
- `<!-- two-col-left-40 -->`

For explicit left/right split, add a column break comment:
- `<!-- col-break -->` (also supports `<!-- two-col-break -->`, `<!-- column-break -->`, `<!-- col-right -->`, `<!-- right-col -->`)

Generic two-column example (text + image):

````markdown
## Product Overview
<!-- two-col -->

- Main capability
- Performance detail
- Rollout note

<!-- col-break -->

![Architecture diagram](./assets/images/architecture.png)
````

If no column-break marker is present, the layout auto-splits using the first media/code/table block when possible.

## Presenter and speaker-note behavior
- Use the Settings button (bottom-right) to open presenter mode and enable bullet-by-bullet reveal.
- In presenter mode, the current-slide preview keeps unrevealed bullets and code highlights visible at reduced opacity (70% by default) so reveal progress is easy to track.
- You can change that pending-opacity value from **Theme settings**.
- Speaker notes are blockquotes prefixed like `Speaker note:`, `Speaker tip:`, `Demo cue:`, etc.
- Speaker-note blockquotes are hidden on audience slides and shown in presenter notes.

## Maintainer note
This `README.md` is documentation for theme maintainers and should not be treated as theme output content.
At build time, Markspresso uses theme layouts/partials/assets, so this file is not published with site output.
