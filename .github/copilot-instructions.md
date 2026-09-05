# AI Agent Instructions for drmowinckels.io

This is Dr. Mowinckel's personal blog and portfolio site built with Hugo.

## Writing Blog Posts

**Always use the `/drmo-voice` skill when drafting or editing blog content.** This ensures posts match the established writing style for technical content, tutorials, and educational material.

```
/drmo-voice
```

The voice skill captures:

- Conversational yet technically precise tone
- Educational approach with clear explanations
- R and neuroimaging domain expertise
- Personal anecdotes balanced with practical content

## Post Structure

Posts live in `content/blog/YYYY/MM-DD_slug/index.md` with frontmatter:

```yaml
---
title: Post Title
author: Dr. Mowinckel
date: "YYYY-MM-DD"
tags: [R, topic]
slug: "url-slug"
image: featured.png
image_alt: "alt text for image"
seo: Short SEO description, max 155 characters.
summary: Brief Summary of the post, longer than SEO, narrative form.
---
```

## Hugo Development

Use `/hugo-site` for site structure changes, theme modifications, or layout work. The site uses:

- Hugo Igloo theme (custom)
- Bulma CSS framework
- SCSS for styling
- Semantic CSS class naming

## Code Standards

- Self-explanatory naming
- R code: tidyverse style
- CSS: semantic class names, minimal JavaScript

## Key Directories

| Path                 | Purpose                          |
| -------------------- | -------------------------------- |
| `content/blog/`      | Blog posts by year               |
| `content/projects/`  | Project showcases                |
| `themes/hugo-igloo/` | Primary theme                    |
| `assets/css/`        | Custom styles                    |
| `R/`                 | Helper R functions               |
| `.github/scripts/`   | Automation (DOI, social posting) |

## Build & Preview

```bash
hugo server -DM   # Local preview with drafts
hugo              # Build site
```

## Automation

The repo has GitHub Actions for:

- Site building and deployment
- Zenodo DOI assignment for posts
- Zenodo re-archiving when a published post changes
- Social media announcements (LinkedIn, Bluesky)
- Newsletter sync with Kit

### Zenodo archiving

`.github/scripts/zenodo.R` holds the shared API and post helpers. Two entry
points use it:

| Script         | Runs when                                        | Does                                              |
| -------------- | ------------------------------------------------ | ------------------------------------------------- |
| `add_doi.R`    | A published post has no `doi:`                   | Mints a DOI and writes it into the frontmatter    |
| `update_doi.R` | A post that already has a `doi:` changed on main | Publishes a new Zenodo version of the same record |

Changed posts are found by diffing the pushed commit range against
`content/blog`, so editing an image or a figure counts as changing the post.
The frontmatter `doi:` is never rewritten by an update — Zenodo groups every
version under a concept DOI that resolves to the newest one.

The `doi:` is recorded in **every** file a post is made of: `index.md` and the
`index.qmd` or `index.Rmd` it was rendered from. Keeping it only in the
rendered markdown means the next render drops it, and the post then looks
unarchived and gets handed a second DOI. Both entry points repair this before
doing anything else, so a source file that is missing the DOI gets it back
rather than the post being minted twice.

To keep a trivial edit out of the archive, put `[skip zenodo]` in the commit
message that changes the post.

Set `ZENODO_DRY_RUN=true` to render the PDF and print what would happen
without touching Zenodo, and `ZENODO_BASE_URL=https://sandbox.zenodo.org` to
work against the sandbox. Tests run with `Rscript .github/scripts/tests/run.R`.
