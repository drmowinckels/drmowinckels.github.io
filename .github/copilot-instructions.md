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
date: 'YYYY-MM-DD'
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

| Path | Purpose |
|------|---------|
| `content/blog/` | Blog posts by year |
| `content/projects/` | Project showcases |
| `themes/hugo-igloo/` | Primary theme |
| `assets/css/` | Custom styles |
| `R/` | Helper R functions |
| `.github/scripts/` | Automation (DOI, social posting) |

## Build & Preview

```bash
hugo server -DM   # Local preview with drafts
hugo              # Build site
```

## Automation

The repo has GitHub Actions for:
- Site building and deployment
- Zenodo DOI assignment for posts
- Social media announcements (LinkedIn, Bluesky)
- Newsletter sync with Kit
