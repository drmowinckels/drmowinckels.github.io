---
title: "Year in review — 2025"
author: "Dr. Mowinckel"
date: "2026-01-19"
format: 
  hugo-md:
    filters:
      - ../../../../figure-to-markdown.lua
tags: 
  - R
  - year-in-review
slug: year-in-review-2025
summary: "A year of deliberate work despite post-COVID recovery: API explorations with httr2, the R Package Development Advent Calendar, ggseg improvements, and looking ahead to 2026."
seo: "A concise look back at 2025: tooling, a package‑dev advent calendar, teaching, and coping with post‑COVID recovery."
image: "newyear.jpg"
image_alt: "image of a woman (me) with dark hair and glasses wearing mauve-burgundy dress, sitting next to an evergreen tree decorated with lights and Christmas ornaments"
doi: false
---

2025 was a year of steady rebuilding: quieter than some years, but more deliberate and productive in the ways that matter. 
I continued to manage lingering post‑COVID effects that shaped how and when I work — I shipped less, but made each piece count.

## The health factor: still recovering
Post‑COVID recovery remains an important constraint. 
I still struggle with variable energy and slower recovery after exertion; that has influenced how I plan work, respond to requests, and set deadlines. 
The positive side is that this limitation forced better prioritization: I focus on durable outputs (tools, tutorials, packages) rather than quick, ephemeral experiments. 
I mention this here because it shaped my year — and because being transparent about it matters to me and, I hope, to readers in similar situations.

I've written about my experience with post‑COVID recovery in a few posts:
- [The difficult year](/blog/2025/the-difficult-year/)
- [Visible - Health tracking App](/blog/2025/visible/)
- [Visible — PCA exploration](/blog/2025/visible-pca/)

## API's and httr2
I've been exploring API work in R more deeply this year, particularly with the httr2 package.
APIs are a powerful way to access data and services, and httr2 provides a modern, flexible interface for working with them in R.
I wrote a couple of posts to share what I've learned:

- [LinkedIn API](/blog/2025/linkedin-api/)
- [httr2 client](/blog/2025/httr2_client/)
- [LinkedIn + Gemini](/blog/2025/linkedin_gemini/)

I did also manage to refactor and release [meetupr](https://rladies.org/meetupr/) to CRAN for R-Ladies, which was a satisfying side project. 
R-Ladies relies on [Meetup.com](https://www.meetup.com/pro/rladies/) for event management, and this package makes it possible for the global team to monitor activity and generate reports directly from R. 

## R Package Development Advent Calendar
The R Package Development Advent Calendar was the year's biggest writing project: 25 focused entries that collectively became a practical reference for modern package authors. 
Building that series forced me to tidy my own habits around testing, CI, documentation, and CRAN submission — and it felt great to publish something immediately useful to the community. 
([R Package Development Advent Calendar](/blog/2025/rpackage-dev-calendar/))

## ggseg development
In the background, where noone could see (except maybe those looking at my github commit chart), I continued to maintain and improve the [ggseg](https://ggseg.github.io/) package for brain atlas visualization in R.
There have been a couple minor releases to make sure ggseg remains on CRAN – nothing major, but dependency packages keep evolving, and it's important to keep up.
In addition to that, I have been working on a major overhaul of the internal data structures to improve performance and flexibility.
In particular I'm working on reducing atlas size by optimizing how the underlying spatial data is stored and accessed.
This is still a work in progress, but I'm excited about the potential improvements it will bring to ggseg users.

In tandem to that, I've been working on some contributions to the [freesurfer]() R-package, which provides R bindings for the popular FreeSurfer neuroimaging software.
It's mostly been about adding tests to the R-code that calls the functions (making sure the calls are formatted correctly etc), and improving documentation. 
It's an amazing package, and I'm happy to contribute to its development.
I've not yet made the PR for these changes, but I plan to do so soon.

## Keeping up with LLMs and coding assistants

We all know that the world of generative AI moves fast, and keeping some sort of tabs on it is important.
I don't want to become obsolete while I'm out sick.

Currently I've just discovered that [claude-code](https://code.claude.com/docs/en/overview) let's you log in with [Claude Pro/Max](https://claude.ai/projects) accounts now.
Which is great, because I prefer having a set monthly quota (my tests also indicate that how I use Claude I actually get more bang for my buck with a Pro subscription that paying as I go).

## Looking ahead to 2026
Goals for 2026 are pragmatic: 
- continue balancing ambition with sustainable pace while I keep recovering.
- refine and share my workflows for reproducible work in R.
- slowly increase my capacity to work, engage, and create.

Happy New Year, and thanks for reading!
