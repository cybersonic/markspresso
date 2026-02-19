---
title: RSS and Atom feeds
layout: page
---

## RSS and Atom feeds

Markspresso can automatically generate RSS 2.0 and Atom 1.0 feeds for your collections, making it easy for readers to subscribe to your content.

### Enabling feeds

Feeds are configured per collection in `markspresso.json`. Add a `feed` block to any collection:

```json
{
  "collections": {
    "posts": {
      "path": "posts",
      "layout": "post",
      "permalink": "/posts/:slug/",
      "feed": {
        "enabled": true,
        "formats": ["rss", "atom"],
        "limit": 20,
        "title": "My Blog",
        "description": "Latest posts from my blog"
      }
    }
  }
}
```

### Feed configuration options

- `enabled` – set to `true` to generate feeds for this collection
- `formats` – array of feed formats to generate; valid values are `"rss"` and `"atom"`
- `limit` – maximum number of items to include in the feed (default: 20)
- `title` – feed title; defaults to `"Site Name - collection"` if not set
- `description` – feed description; defaults to `"Latest collection from Site Name"`

### Output files

When feeds are enabled, Markspresso generates:

- **RSS 2.0**: `public/<collection>/feed.xml`
- **Atom 1.0**: `public/<collection>/atom.xml`

For the default `posts` collection, this produces:

- `public/posts/feed.xml` (RSS)
- `public/posts/atom.xml` (Atom)

### Feed content

Each feed item includes:

- **Title** – from the document's `title` front matter
- **Link** – the document's canonical URL (with `baseUrl` prefix)
- **Date** – from the document's `date` front matter or filename
- **Description** – from `description` front matter, or a snippet of the content
- **Content** – full HTML content (Atom only)

### Adding feed autodiscovery links

To help feed readers automatically detect your feeds, add `<link>` tags to your layout's `<head>`:

```html
<link rel="alternate" type="application/rss+xml" title="RSS" href="/posts/feed.xml">
<link rel="alternate" type="application/atom+xml" title="Atom" href="/posts/atom.xml">
```

This is optional but recommended for better discoverability.

### Multiple collection feeds

You can enable feeds for any collection, not just posts. Each collection with `feed.enabled: true` will generate its own set of feed files:

```json
{
  "collections": {
    "posts": {
      "path": "posts",
      "feed": { "enabled": true, "formats": ["rss", "atom"] }
    },
    "news": {
      "path": "news",
      "feed": { "enabled": true, "formats": ["rss"] }
    }
  }
}
```

This produces:

- `public/posts/feed.xml` and `public/posts/atom.xml`
- `public/news/feed.xml`
