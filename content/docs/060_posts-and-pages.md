---
title: Posts and pages
layout: page
---

## Posts and pages

Markspresso supports collections of content, with a built-in `posts` collection suitable for blogs.

### The `new` command

To create new content, use:

```bash
lucli markspresso new <type> --title "My title" [--slug my-title]
```

Where `<type>` is:

- `posts` – for blog posts (uses the `posts` collection and `post` layout)
- `page` – for standalone pages that use the default `page` layout

Examples:

```bash
# New blog post
lucli markspresso new posts --title "Hello world"

# New standalone page
lucli markspresso new page --title "About"
```

If you omit `--slug`, Markspresso derives one from the title (lowercase, dashes between words, special characters stripped).

### Where files are created

- For `posts`, files are created under the `path` configured for the `posts` collection (by default `content/posts/`).
- For other types (like `page`), files are created directly under the content root (by default `content/`).

The exact directories are based on `markspresso.json`:

- `paths.content` – content root
- `collections.posts.path` – subdirectory for posts

### Filenames for posts

Posts get a date prefix in their filename:

```text
YYYY-MM-DD-slug.md
```

For example, creating a post titled "Hello world" on 2025-01-15 might produce:

```text
content/posts/2025-01-15-hello-world.md
```

Markspresso will also derive a `date` value from the filename if you don't specify one explicitly in front matter.

### Generated front matter

When using `new`, Markspresso writes front matter for you. For posts, this includes:

- `title` – from `--title`
- `layout` – typically `post`
- `date` – current date (YYYY-MM-DD)
- `draft: true` – so new posts don't appear until you're ready

For pages, it writes:

- `title` – from `--title`
- `layout` – based on `build.defaultLayout` (usually `page`)

You can edit the resulting file to add more fields like `permalink`, `nav_hidden`, or any custom keys.

### Publishing drafts

To publish a post created with `new`:

1. Open the generated `.md` file.
2. Change `draft: true` to `draft: false` **or** remove the line.
3. Run a build without `--drafts`.

Draft behavior:

- Drafts are skipped by default.
- They are included when:
  - `build.includeDrafts` is `true` in `markspresso.json`, or
  - You pass `--drafts` to `lucli markspresso build`.

### Posts on the home page

The scaffolded `content/index.md` includes a `{{ latest_posts }}` placeholder. During build, Markspresso:

- Collects posts from the `posts` collection
- Sorts them by `date` (newest first)
- Renders an HTML list of links, limited by `build.latestPostsCount`

You can remove or move `{{ latest_posts }}` to customize where the list of recent posts appears.
