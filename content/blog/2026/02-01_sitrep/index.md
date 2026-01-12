---
title: "The Under-Appreciated `_sitrep()` Function"
author: "Dr. Mowinckel's"
date: "2026-01-12"
tags:
  - R
  - package development
  - debugging
  - API wrappers
slug: sitrep-functions
draft: false
---

The usethis package has a function I rely on constantly: `git_sitrep()`. 
When Git authentication breaks or remotes get confused, it dumps everything relevant in one go.
No more hunting through config files or trying random fixes.

This pattern—the situation report function—should be standard in any R package wrapping an API or external program. 
I've built them into meetupr and freesurfer, and they've saved me endless debugging cycles.

## Why This Matters

API wrappers and program interfaces fail predictably:
- Missing credentials
- Expired tokens
- Wrong environment variables  
- Version mismatches
- Network issues

Users hit these walls and open issues: "why doesn't it work?" 
You end up playing 20 questions trying to diagnose their setup. A `sitrep()` function surfaces everything at once.

## The Dual-Purpose Architecture

The real power comes from building checking functions that serve two purposes:

1. **Error early in function calls** - Validate setup before attempting operations
2. **Report status in sitrep** - Present comprehensive diagnostic information

This reduces duplication and keeps validation logic consistent.

## meetupr Implementation

The package authenticates with Meetup's GraphQL API via OAuth. Here's the sitrep output:

```r
meetup_sitrep()
#> ── meetupr Situation Report ─────────────────────
#> 
#> ── Active Authentication Method ──
#> ✔ OAuth - Active
#> 
#> ── OAuth Configuration ──
#> Client ID: ae743e...
#> Client Secret: Set
#> ✔ Cached Token: Available
#> 
#> ── Package Settings ──
#> Debug Mode: Disabled
#> API endpoint: https://api.meetup.com/gql
#> 
#> ── API Connectivity Test ──
#> ✔ API Connection: Working
#> ℹ Authenticated as: Mo Mowinckel (ID: 123456)
```

### The Checking Functions

These helpers check auth status without side effects:

```r
has_oauth_credentials <- function() {
  nzchar(Sys.getenv("MEETUP_CLIENT_ID")) && 
    nzchar(Sys.getenv("MEETUP_CLIENT_SECRET"))
}

has_cached_token <- function() {
  tryCatch({
    token_path(pattern = ".rds.enc$")
    TRUE
  }, error = function(e) FALSE)
}

is_ci_mode <- function() {
  nzchar(Sys.getenv("MEETUP_TOKEN")) && 
    nzchar(Sys.getenv("MEETUP_TOKEN_FILE"))
}
```

### Using Them in Functions

Internal functions call these for early validation:

```r
meetup_query <- function(query) {
  if (!has_cached_token() && !is_ci_mode()) {
    stop("Not authenticated. Run meetup_auth() first.", call. = FALSE)
  }
  
  # Proceed with API call
}
```

### Using Them in Sitrep

The sitrep aggregates and reports:

```r
meetup_sitrep <- function() {
  cli::cli_h1("meetupr Situation Report")
  
  auth_status <- check_auth_methods()
  display_auth_status(auth_status)
  test_api_connectivity(auth_status)
  
  invisible(auth_status)
}

check_auth_methods <- function() {
  list(
    oauth_available = has_oauth_credentials(),
    has_cached_token = has_cached_token(),
    ci_mode = is_ci_mode(),
    active_method = determine_active_method()
  )
}
```

The key: `check_auth_methods()` doesn't duplicate logic—it calls the same validation functions used throughout the package.

## freesurfer Implementation  

FreeSurfer is a neuroimaging toolkit with command-line tools. Different failure modes, same dual-purpose pattern:

```r
check_freesurfer_home <- function() {
  home <- Sys.getenv("FREESURFER_HOME")
  if (home == "") {
    return(list(
      valid = FALSE,
      path = NA_character_,
      message = "FREESURFER_HOME not set"
    ))
  }
  
  if (!dir.exists(home)) {
    return(list(
      valid = FALSE,
      path = home,
      message = "FREESURFER_HOME directory does not exist"
    ))
  }
  
  list(valid = TRUE, path = home, message = NULL)
}

check_freesurfer_binary <- function(binary_name) {
  status <- check_freesurfer_home()
  if (!status$valid) return(status)
  
  bin_path <- file.path(status$path, "bin", binary_name)
  if (!file.exists(bin_path)) {
    return(list(
      valid = FALSE,
      path = bin_path,
      message = paste("Binary not found:", binary_name)
    ))
  }
  
  list(valid = TRUE, path = bin_path, message = NULL)
}
```

### Using Them in Functions

```r
mri_convert <- function(input, output, ...) {
  bin_check <- check_freesurfer_binary("mri_convert")
  if (!bin_check$valid) {
    stop(bin_check$message, call. = FALSE)
  }
  
  # Execute command
}
```

### Using Them in Sitrep

```r
freesurfer_sitrep <- function() {
  cli::cli_h1("freesurfer Situation Report")
  
  home_status <- check_freesurfer_home()
  display_freesurfer_home(home_status)
  
  if (home_status$valid) {
    test_key_binaries()
    check_subjects_dir()
  }
  
  invisible(home_status)
}

test_key_binaries <- function() {
  cli::cli_h2("Key Binaries")
  
  binaries <- c("mri_convert", "mri_info", "recon-all")
  
  for (bin in binaries) {
    status <- check_freesurfer_binary(bin)
    if (status$valid) {
      cli::cli_alert_success("{bin}: Found")
    } else {
      cli::cli_alert_danger("{bin}: {status$message}")
    }
  }
}
```

## Design Principles

**Write checking functions, not checking code.** Extract validation logic into small, testable functions that return structured results.

**Structure over booleans.** Return lists with `valid`, `value`, and `message` instead of just TRUE/FALSE. This gives both functions and sitrep the context they need.

**No side effects in checks.** Functions named `check_*()` or `has_*()` should only inspect, never modify or trigger auth flows.

**Consistent returns.** All checking functions should return the same structure so they can be used interchangeably.

**Use cli semantics.** Headers, alerts, and colors make sitrep output scannable.

## The Maintenance Win

When auth logic changes, you update one checking function.
Both error messages and sitrep automatically stay in sync. 
No hunting for duplicate validation code scattered across your package.

When debugging CI failures, you can add a `package_sitrep()` call to the workflow and get comprehensive diagnostics in the logs.

When someone reports "it's not working", you say: "Run `package_sitrep()` and show me the output." 
You get structured information instead of playing diagnostics ping-pong.

The usethis team built this pattern because they handle enormous volumes of Git/GitHub setup issues. 
If it works for them, it'll work for your API wrapper.
