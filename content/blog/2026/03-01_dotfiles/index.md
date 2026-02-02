---
title: "Dotfiles: Taming Your Dev Environment (and Your AI Coding Agents)"
author: Dr. Mowinckel
date: '2026-02-15'
tags:
  - tooling
  - dotfiles
  - AI
  - Claude Code
  - OpenCode
slug: dotfiles-coding-agents
seo: >-
  How to manage dotfiles for consistent development environments, with a focus on configuring AI coding agents like Claude Code and OpenCode.
summary: >
  My dotfiles repo has evolved from basic shell configs to a full system that keeps my AI coding agents in sync. Here's how I structure it, why submodules matter for shared skills, and how symlinks tie everything together.
---

I reinstalled my Mac last year and it took me *days* to get everything working again.
Never again.

That frustration pushed me to finally set up a proper dotfiles repository.
If you're not familiar with the concept: dotfiles are the hidden configuration files that live in your home directory (`.zshrc`, `.gitconfig`, etc.), and a dotfiles repo is a way to version control them so you can restore your entire setup on a new machine.

But here's the thing — my dotfiles have grown beyond shell configs.
They now manage my AI coding agents too.
With tools like Claude Code and OpenCode becoming central to my workflow, I needed a way to keep their configurations consistent and shareable.

## The Basic Structure

My dotfiles live at `~/.dotfiles` and get symlinked to where they need to be.
Here's the layout:

```
.dotfiles/
├── config/
│   ├── claude/          # Claude Code configuration
│   ├── opencode/        # OpenCode configuration
│   ├── env/             # Shell environment (zshrc, aliases, etc.)
│   ├── git/             # Git config and global ignore
│   ├── vscode/          # Positron/VSCode settings
│   └── Brewfile         # Homebrew packages
├── install/
│   ├── symlinks.sh      # Creates all the symlinks
│   ├── homebrew.sh      # Installs brew packages
│   └── ...
├── install.sh           # Main installer
├── update.sh            # Updates everything
└── backup.sh            # Backs up before changes
```

The key insight: everything lives in `config/`, and `install/symlinks.sh` creates the links to where each tool expects its config.

```bash
safe_symlink "$DOTFILES/config/claude" "$HOME/.claude"
safe_symlink "$DOTFILES/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
safe_symlink "$DOTFILES/config/env/zshrc" "$HOME/.zshrc"
```

This means I can edit files in one place, version control them, and they're automatically active wherever the tools look for them.

## Configuring AI Coding Agents

Here's where it gets interesting.
Both Claude Code and OpenCode read configuration from specific locations, and I want them to behave consistently.

### Claude Code

Claude Code looks for its config in `~/.claude/`.
My setup includes:

**settings.json** — The main configuration:

```json
{
    "customInstructions": "You are working with an R package developer...",
    "fileExclusions": [
        ".Rproj.user/**",
        "node_modules/**",
        ".git/**",
        "docs/**"
    ],
    "autoApprovePatterns": [
        "**/*.Rd",
        "**/NEWS.md",
        "**/NAMESPACE"
    ]
}
```

The `customInstructions` tell Claude about my preferences: no unnecessary comments, tidyverse style, concise responses.
The `fileExclusions` prevent it from reading generated files.
And `autoApprovePatterns` lets routine R package documentation updates happen without me clicking "approve" every time.

**CLAUDE.md** — High-level instructions that apply across all projects:

```markdown
# Coding Standards

- No code comments except when explaining necessary workarounds
- Self-explanatory naming
- R: tidyverse style, roxygen2 docs, testthat (describe/it) structure
- Hugo: semantic CSS classes, minimal JS
- Concise, direct responses
```

### OpenCode

OpenCode is an open-source alternative I've been experimenting with.
Its config lives at `~/.config/opencode/opencode.json`.

The neat part: I can point it to the same instruction file that Claude Code uses:

```json
{
  "model": "anthropic/claude-sonnet-4-5",
  "instructions": [
    "{file:~/.claude/CLAUDE.md}"
  ],
  "watcher": {
    "ignore": [
      ".Rproj.user/**",
      "node_modules/**"
    ]
  }
}
```

Same instructions, same exclusions.
Consistency across tools without duplication.

## Skills as Git Submodules

Both Claude Code and OpenCode support "skills" — reusable instruction sets for specific tasks.
This is where git submodules shine.

My skills directory structure:

```
config/claude/skills/
├── drmo-voice/           # My personal writing voice
├── hugo-site/            # Hugo development patterns
├── r-package/            # R package preferences
├── posit-skills/         # [submodule] Posit's official skills
└── straight-talk/        # [submodule] Alison Hill's writing skills
```

The submodules point to external repositories:

```ini
[submodule "config/claude/skills/posit-skills"]
    path = config/claude/skills/posit-skills
    url = https://github.com/posit-dev/skills
```

Why submodules?

1. **Upstream updates**: When Posit improves their R testing skill, I pull the changes
2. **No duplication**: I don't copy-paste skill files that others maintain
3. **Mix and match**: My personal skills live alongside community ones

The Posit skills repo includes gems like `testing-r-packages` (comprehensive testthat guidance) and `brand-yml` (pkgdown branding).
Alison Hill's `straight-talk` repo has writing skills I use as a foundation for my own voice.

### Custom Skills

My personal skills extend or customize the community ones.
For example, `r-package/skill.md` starts with:

```markdown
# R Package Development - Personal Preferences

Specific style preferences and workflow choices for R package development.
Use alongside Posit `testing-r-packages` for comprehensive guidance.

## Code Style Philosophy

### Self-Explanatory Code Without Comments

Functions and variables should be named clearly enough that comments
are unnecessary...
```

And `drmo-voice/skill.md` captures my writing style for blog posts:

```markdown
# Dr. Mo's Voice

Write like you're explaining something to a smart friend who hasn't
encountered this specific thing yet. Be the guide you wished you had.

**Foundation:** This skill builds on the codex-voice principles.
Start there for the fundamentals of honest, reader-first technical writing.
```

These are things I'd otherwise repeat in every conversation.
Now they're documented once and available whenever I invoke the skill.

## The Update Workflow

My `update.sh` script pulls everything together:

```bash
# Update dotfiles from git
git pull origin main

# Update submodules
git submodule update --remote

# Refresh symlinks
./install/symlinks.sh

# Update Homebrew packages
brew bundle --file="$DOTFILES/config/Brewfile"
```

One command keeps my shell config, editor settings, AI agent instructions, and community skills all current.

## Why This Matters

Before this setup, I had instructions scattered everywhere.
Project-specific `.claude` files.
Mental notes about "how I like things done."
Inconsistent behavior between tools.

Now:

- **New machine?** Clone the repo, run `install.sh`, done.
- **New AI tool?** Point it at the same instruction files.
- **Better skill from the community?** Pull the submodule.
- **Refined my preferences?** Edit once, applies everywhere.

The AI coding agents are the newest addition to my dotfiles, but they follow the same principle as everything else: define it once, symlink it to where it needs to be, version control the whole thing.

If you're using Claude Code or similar tools regularly, I'd encourage you to move their configs into your dotfiles.
Future you — reinstalling on a new machine — will thank present you.

## Resources

- [My dotfiles repo](https://github.com/drmowinckels/dotfiles) (feel free to fork and adapt)
- [Posit Skills](https://github.com/posit-dev/skills) — Official R/Shiny/Quarto skills
- [Alison Hill's straight-talk](https://github.com/apreshill/straight-talk) — Writing voice skills
- [GitHub does dotfiles](https://dotfiles.github.io/) — Inspiration and examples
