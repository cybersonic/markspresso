---
title: Layouts and partials
layout: page
---

## Layouts and partials

Layouts control the HTML skeleton for your pages. They live under the `layouts/` directory.

### Basic layout structure

The `create` command scaffolds `layouts/page.html` and `layouts/post.html`. A simplified layout looks like this:

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>{{ title }}</title>
  </head>
  <body>
    {{ include "partials/header.html" }}
    <main>
      {{ content }}
    </main>
    {{ include "partials/footer.html" }}
  </body>
</html>
```

Key ideas:

- `{{` `title`  `}}` comes from front matter
- `{{` `content`  `}}` is the rendered Markdown body
- `{{` `navigation`  `}}` (when present) is generated HTML for the sidebar navigation
- `{{` `latest_posts`  `}}` is injected on the home page if you use it in `content/index.md`
- `{{` `tags_list`  `}}`, `{{` `archives_list` `}}` and `{{` `posts_list` `}}` are site-wide lists you can drop into any page or layout

### Token replacement

Any key in a document's front matter is available to layouts as a token:

- `{{ key }}`
- `{{key}}` (no spaces)

For example, given:

```markdown
---
title: Landing
layout: page
cta_label: Get started
---

Welcome!
```

You can use `{{ cta_label }}` inside `page.html`.

### Including partials

To reuse markup (headers, footers, sidebars), put HTML files under `layouts/partials/` and include them with:

```html
{{ include "partials/header.html" }}
```

Rules:

- Paths are resolved relative to the `layouts/` directory
- Nested includes are supported: partials can include other partials
- Unsafe paths using `..` segments are ignored for safety

The `create` command seeds two partials:

- `layouts/partials/header.html`
- `layouts/partials/footer.html`

Feel free to customize them.

### Conditional blocks

Layouts support a simple conditional syntax:

```html
{{#if featured}}
  <div class="badge">Featured</div>
{{/if}}
```

You can also specify an `else` branch:

```html
{{#if loggedIn}}
  <a href="/account/">My account</a>
{{else}}
  <a href="/login/">Log in</a>
{{/if}}
```

The condition key (`featured`, `loggedIn`) is looked up from the data available to the template (front matter plus injected fields like `content`, `navigation`, `latest_posts`).

**Truthiness rules**:

- `false`, `0`, empty strings, empty arrays, empty structs, and `null` are treated as false
- Everything else is true

### Layout selection

For each document, Markspresso chooses a layout as follows:

1. If front matter specifies `layout`, use that.
2. Else, if the document belongs to a collection with a `layout` configured, use that.
3. Otherwise, fall back to `build.defaultLayout` from `markspresso.json` (typically `page`).

This means you can:

- Use `layout: page` for regular pages
- Use `layout: post` for blog posts
- Define additional layouts (e.g. `docs.html`) and opt into them per page or per collection.

### CFML layouts

In addition to plain HTML layout files, Markspresso can render layouts written in CFML:

- For a layout name like `page`, you can create `layouts/page.cfm` instead of (or as well as) `layouts/page.html`.
- When both exist, the `.cfm` file wins; it is executed by Lucee and receives helpful variables such as `content`, `data` (front matter + injected fields), `page` (file path, collection, canonical URL, etc.), and `globals`/`config`.

Use CFML layouts when you want more dynamic behavior than simple token replacement and conditionals can provide.

### Search UI and `markspressoScripts`

When you enable Lunr search via the `search.lunr` block in `markspresso.json`, Markspresso will:

- Generate a client-side search data file (by default `js/markspresso-search-data.js`) that defines `window.MarkspressoSearchDocs`.
- Copy the bundled `markspresso-search.js` helper (which loads Lunr from a CDN and builds the index) into your output directory.
- Inject a `markspressoScripts` token into the layout data, which expands to the `<script>` tags needed to load the search assets.

To add a search box to an HTML layout, include the expected markup and the `{{ markspressoScripts }}` token. For example:

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>{{ title }}</title>
  </head>
  <body>
    <!-- your header / navigation here -->

    <header>
      <!-- other header content -->
      <form class="search">
        <input id="markspresso-input" type="search" placeholder="Search docs…">
      </form>
    </header>

    <main>
      {{ content }}
      <div id="markspresso-search-results"></div>
    </main>

    {{ markspressoScripts }}
  </body>
</html>
```

The bundled `markspresso-search.js` looks for elements with these IDs:

- `markspresso-search-input` – the `<input>` where users type their query
- `markspresso-search-results` – a container `<div>` where results will be rendered as links

You can either use those IDs directly, or adapt `resources/utility/markspresso-search.js` to target your own selectors.

In a CFML layout (e.g. `layouts/page.cfm`), the same script tags are available via the `markspressoScripts` variable:

```cfml
<!doctype html>
<html>
  <head>
    <title>#encodeForHtml(data.title)#</title>
  </head>
  <body>
    <cfoutput>
      <!-- your header / navigation here -->
      <form class="search">
        <input id="markspresso-search-input" type="search" placeholder="Search docs…">
      </form>

      #content#
      <div id="markspresso-search-results"></div>

      #markspressoScripts#
    </cfoutput>
  </body>
</html>
```

### Overriding built-in lists with CFML

Markspresso builds a few site-wide lists for you, you just have to surround them with `{{}}`:

- `{{` `tags_list` `}}`
- `{{` `archives_list` `}}`
- `{{` `posts_list` `}}`

By default these are rendered as simple `<ul>` elements, but you can override each one with a CFML template under `layouts/lists/`:

- `layouts/lists/tags_list.cfm`
- `layouts/lists/archives_list.cfm`
- `layouts/lists/posts_list.cfm`

If any of these `.cfm` files exist in your site's layouts directory, they will be used instead of the default HTML. The templates receive the corresponding data structures (`tagsIndex`, `archivesIndex` or `posts`), so you are free to output whatever markup you like.
