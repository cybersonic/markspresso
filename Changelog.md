# Changelog

All notable changes to Markspresso are documented in this file.

## Unreleased
- Change default port from 8080 to 3456 across all commands and docs
- Implement `serve` command — now starts an HTTP server via lucli
- Add `pdf` and `geturl` subcommands to help/usage output
- Support arbitrary collection types in `new` command (e.g. `lucli markspresso new doc`)
- Better error message when `new` is called with an unconfigured collection type
- Fix bug in `new` where date/draft front matter was checking `"posts"` instead of `"post"`
- Rework scaffold layouts with `.site-wrapper` and `.content-area` wrapper divs for better flex layout
- Slugify site name in generated `lucee.json` and include port in config
- `buildSite()` now returns a `"Site Built"` string instead of void
- Use `arguments.` scope consistently in `out()`, `verbose()`, `geturl()`, and `pdf()`
- Bump version to 1.0.1 in `module.json`
- Fix `module.json` indentation for extensions config
- Add `demo.lucli` demo script

## 2026-02-19
- Add PDF generation functionality and update module configuration
- Add feed generation capabilities and update configuration for collections
- Add Bats testing framework documentation and sample tests
- Fixing merge issues

## 2026-01-29
- Adding a better markdown parser + adding current page to nav

## 2026-01-22
- Adding search and pagination

## 2026-01-12 – 2026-01-13
- Updating docs and layout
- Updated .gitignore and docs

## 2025-12-29
- Adding CFML rendering and layout features and lists
- Adding globals docs
- Made config visible as a whole
- Adding footer
- Updating homepage
- Removing rendered docs (will be done on commit)
- Fixing the parsing in blocks

## 2025-12-26 – 2025-12-27
- Refactored the uber component and added navigation
- Fixed docs and publishing of posts
- Adding site content
- Create CNAME
- Adding better docs and putting them in the right place
- Pointing markspresso to the right place
- Testing GitHub Action

## 2025-12-01 – 2025-12-02
- Add .gitignore and enhance Markdown processing in Module.cfc
- Adding logo

## 2025-11-29
- Initial release
- Fixing up processing
- Adding front readme
- Removing serve information
