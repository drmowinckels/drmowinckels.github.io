---
title: "Why Every R Package Wrapper Needs a sitrep() Function"
author: "Dr. Mowinckel's"
date: "2026-02-02"
tags:
  - R
  - package development
  - debugging
  - wrappers
slug: sitrep-functions
seo: "Discover how the sitrep() pattern simplifies R package maintenance and surfaces configuration errors in one go."
summary: |
  Stop playing "diagnostics ping-pong" with your users. This post explores why the _sitrep() (situation report) pattern — popularized by the usethis package — is a game-changer for R packages wrapping APIs or external software. Learn how to build structured validation functions that power both early error-handling and comprehensive system reports, featuring real-world implementation examples from the meetupr and freesurfer packages.
image: image.png
image_alt: |
  A close-up view of a computer monitor in a dimly lit room, showing a terminal console. The terminal displays the output of an R function called meetupr_sitrep(). The report shows green checkmarks for "Active Authentication" and "Cached Token," and a blue information icon for package settings. At the bottom, a red "X" marks a failed "API Connectivity Test," illustrating a diagnostic situation report in action. In the foreground, a coffee mug and a person’s hand on a keyboard are visible but slightly out of focus.
---

The usethis package has a function I find extremely useful: `git_sitrep()`. 
When Git authentication breaks or remotes get confused, it dumps everything relevant in one go.
No more hunting through config files or trying random fixes.

This pattern — the situation report function — should be standard in any R package wrapping an API or external program. 
I've built them into meetupr and freesurfer, and I think they'll help both users and developers when debugging issues.

## Why This Matters

API wrappers and program interfaces fail predictably:
- Missing credentials  
- Expired tokens  
- Wrong environment variables    
- Version mismatches  
- Network issues  

Users hit these walls and open issues: "why doesn't it work?" 
You end up playing 20 questions trying to diagnose their setup.
A `sitrep()` function surfaces everything at once, and can even help the user diagnose and fix on their own.

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

In meetupr, we implemented a function that goes through the possible validation options and checking what is available.
It is quite extensive, but I wanted to show the entire function, because I quite honestly think its pretty neat (not so humble brag).

The function checks if a JWT token is set up and available, then if the httr2 cache has a valid API token stored, and returns a list with all the information (which we can then use later).

```r
meetupr_auth_status <- function(
  client_name = get_client_name(),
  silent = FALSE
) {
  # JWT token
  jwt <- tryCatch(
    get_jwt_token(client_name = client_name),
    error = function(e) NULL
  )

  jwt_issuer <- meetupr_key_get(
    "jwt_issuer",
    client_name = client_name,
    error = FALSE
  )

  client_key <- meetupr_key_get(
    "client_key",
    client_name = client_name,
    error = FALSE
  )

  jwt_valid <- !is_empty(jwt) &&
    !is_empty(jwt_issuer) &&
    !is_empty(client_key)

  if (jwt_valid) {
    if (!silent) {
      cli::cli_alert_success("JWT setup found and is valid")
    }
  } else {
    if (!silent) {
      cli::cli_alert_warning("JWT setup not found or invalid")
    }
  }

  # httr2 OAuth cache
  cache_path <- get_cache_path(client_name)

  if (!dir.exists(cache_path)) {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token cache found")
    }
  }

  cache_files <- list_token_files(cache_path)
  cache_valid <- length(cache_files) > 0

  if (cache_valid) {
    if (!silent) {
      cli::cli_alert_success("Token found in cache")
      if (length(cache_files) > 1) {
        cli::cli_alert_info("Multiple token files found in cache:")
        for (f in cache_files) {
          cli::cli_text(" - {.file {f}}")
        }
      }
    }
  } else {
    if (!silent) {
      cli::cli_alert_danger("Not authenticated: No token found in cache")
    }
  }

  type <- if (jwt_valid) {
    "jwt"
  } else if (cache_valid) {
    "cache"
  } else {
    "none"
  }

  # Return detailed status
  list(
    auth = list(
      any = jwt_valid || encrypted_valid || cache_valid,
      client_name = client_name,
      method = type
    ),
    jwt = list(
      available = jwt_valid,
      value = jwt %||% NULL,
      issuer = jwt_issuer %||% NA_character_,
      client_key = client_key %||% NULL
    ),
    cache = list(
      available = cache_valid,
      files = cache_files %||% NA_character_
    )
  ) |>
    invisible()
}
```

Since the function returns all this information, we can set up convenience functions around this one that can help us evaluate the state of auth for the functions.

```r
has_auth <- function(
  client_name = get_client_name()
) {
  meetupr_auth_status(
    client_name,
    silent = TRUE
  )$auth$any
}


```

### Using Them in Functions

Internal functions call these for early validation:

```r
meetup_query <- function(query) {
  if (!has_auth()) {
    cli::cli_abort("Not authenticated. Run {.code meetup_auth()} first.")
  }
  
  # Proceed with API call
}
```

### Using Them in Sitrep

Since we have this `meetupr_auth_status` with all the information on the state of authentication, we can use it in the sitrep.
We built a convenience function, that takes the result of that function and displays the information in an orderly fashion and gives users aid if they need to fix something.

```r
meetupr_sitrep <- function() {
  cli::cli_h1("meetupr Situation Report")

  auth_status <- meetupr_auth_status(silent = TRUE)

  display_auth_status(auth_status)

  test_api_connectivity()

  invisible(auth_status)
}
```

Lastly, we created a simple API connectivity test, that calls the API and checks who is authenticated. 
With this last bit, we can tell the users whether the setup actually works.

The key: `meetupr_auth_status()` doesn't duplicate logic — it calls the same validation functions used throughout the package.

## freesurfer Implementation  

FreeSurfer is a neuroimaging toolkit with command-line tools. 
John Muschelli has a wrapper package from R that calls the CLI functions from R and optionally imports the data to R for further processing. 

My ggsegExtra-package, which contains pipelines for creating new ggseg-atlases, calls Freesurfer in several stages of the process, so I have contirbuted to the package several times, with functionality I need to my own package which make better sense to exist in Freesurfer than in my own package.
Last time I was working on Freesurfer, I had some issues getting R and my Freesurfer to talk to each other, and I got frustrated figuring out why.
So I thought, this package needs a sitrep function.

For freesurfer, I needed similar, but still different approach.
Since it relies on software being installed on your system, I needed a way to get information on user settings (environment or options) and whether the paths specified actually exists or not,
and I needed to have a good overview over how Freesurfer deal with all this it self (I kind of already knew this last bit, you can't work with Freesurfer CLI unless you have a fairly thorough understanding of where its installed and how to work with system paths).

However, there are quite a lot of possible settings, so the first step was to set up a convenience function that would help evaluate whether settings were available using the heuristic `options > environment > default guesswork`. 
That last one is using known paths that Freesurfer by default gets installed to to search for it.


```r
get_fs_setting <- function(
  env_var,
  opt_var,
  defaults = NULL,
  is_path = TRUE
) {
  # Check R option first
  original_opt <- getOption(opt_var)
  if (!is.null(original_opt) && nzchar(as.character(original_opt))) {
    return(return_setting(
      as.character(original_opt),
      paste("R option:", opt_var),
      is_path
    ))
  }

  # Check environment variable
  original_env <- Sys.getenv(env_var)
  if (nzchar(original_env)) {
    return(return_setting(
      original_env,
      paste("Environment variable:", env_var),
      is_path
    ))
  }

  # Try defaults
  if (!is.null(defaults)) {
    if (is_path) {
      # Find first existing default
      existing_defaults <- batch_file_exists(
        defaults,
        error = FALSE,
        warn = FALSE
      )
      valid_defaults <- defaults[existing_defaults]

      if (length(valid_defaults) > 0) {
        return(return_setting(
          valid_defaults[1],
          "Default path",
          TRUE
        ))
      }
    } else {
      # For non-paths, just return first default
      return(return_setting(
        defaults[1],
        "Default value",
        FALSE
      ))
    }
  }
  # Nothing found
  return_setting(
    NA,
    "Not found",
    is_path
  )
}
```

Again, my function here returns the information and context needed for further evaluation, but also calls a `return_setting` function, since I wanted to make sure this ALWAYS returns the same information, and evaluates whether a path exists or not.

```r
return_setting <- function(value, source, is_path = TRUE) {
  exists <- FALSE

  if (!is_path) {
    exists <- NA
  }

  if (is_path && !all(is.na(value))) {
    value <- normalizePath(value, mustWork = FALSE)
    if (length(value) == 1) {
      exists <- file.exists(value)
    } else {
      exists <- batch_file_exists(
        value,
        error = FALSE,
        warn = FALSE
      )
    }
  }

  list(
    value = value,
    source = source,
    exists = exists
  )
}
```

Now that we have these conveniences, I could start setting up custom functions that would look for specific pieces needed for the communication between Freesurfer and R, like the very crucial `get_fs_home()` function, which finds the path to where Freesurfer is installed.

```r
get_fs_home <- function(simplify = TRUE) {
  ret <- get_fs_setting(
    env_var = "FREESURFER_HOME",
    opt_var = "freesurfer.home",
    defaults = c(
      "/usr/freesurfer",
      "/usr/bin/freesurfer",
      "/usr/local/freesurfer",
      "/Applications/freesurfer"
    ),
    is_path = TRUE
  )
  if (simplify) {
    return(ret$value)
  }
  ret
}
```

This function checks first for whether the `FREESURFER_HOME` environment variable is set (which is necessary to set when using Freesurfer from the terminal, and thus any R called from a terminal on such a system will already have this set), it checks for the `freesurfer.home` `option()` setting in R, and then looks in the known default paths it may exist on a system.

And since we also added the `simplify` argument to the function, we can return a simple logical statement is Freesurfer home is set and exists on the system

```r
have_fs <- function() {
  get_fs_home(simplify = TRUE)
}
```

In addition, since we have the convenience `get_fs_setting()` function, we can create other check which we know Freesurfer relies on to work properly, like checking whether its license file is set up correctly (its free to use, but you need to register with them to get a license file).

```r
get_fs_license <- function(
  fs_home = get_fs_home(),
  simplify = TRUE
) {
  if (is.na(fs_home)) {
    ret <- return_setting(
      NA, 
      "FreeSurfer home not found", 
      TRUE
    )
    if (simplify) {
      return(ret$value)
    }
    return(ret)
  }

  ret <- get_fs_setting(
    "FS_LICENSE",
    "freesurfer.license",
    c(
      file.path(fs_home, ".license"),
      file.path(fs_home, "license.txt")
    )
  )

  if (simplify) {
    return(ret$value)
  }
  ret
}
```

The license file check, first checks if fs_home() returns correctly, no reason to check for lisence with the program isn't there.
Then it moves on to check for environment settings, options, and default paths again, like before.

### Using Them in Sitrep

To finally create a good `fs_sitrep()` function, we created a convenience function that took the output from get_fs_setting(), which is a list of three things, and made sure it could output good cli-style information to the console.

```r
alert_info <- function(settings, header) {
  cli::cli_h3(header)

  if (is.null(settings) || all(is.na(settings$value))) {
    cli::cli_li("Unable to detect")
    return()
  }

  if (length(settings$value) > 1) {
    cli::cli_alert_warning("Multiple possible values found")
    for (val in settings$value) {
      cli::cli_li("{.val {val}}")
    }
    cli::cli_alert_info("Consider setting preferred value with {.code options}")
    settings <- return_single(settings)
  }

  cli::cli_li("{.val {settings$value}}")

  # Source information
  if (!is.na(settings$source)) {
    if (grepl("Default|Not found", settings$source, ignore.case = TRUE)) {
      cli::cli_alert_warning("Determined from: {.code {settings$source}}")
    } else {
      cli::cli_alert_info("Determined from: {.code {settings$source}}")
    }
  }

  # Path existence
  if (!is.na(settings$exists)) {
    if (settings$exists) {
      cli::cli_alert_success("Path exists")
    } else {
      cli::cli_alert_danger("Path does not exist")
    }
  }
}
```

With that in place, we have a rather large sitrep for fs, that shows lots of different things, including whether something has been set from what source (env or option) or if it's just the default behaviour.

And just like in meetupr, we finish off with a test to whether the communication between R and Freesurfer is working, in this case by just asking for the help file of a core Freesurfer function, and making sure that outputs expected help information.


```r
fs_sitrep <- function(test_commands = TRUE) {
  fs_home <- get_fs_home(simplify = FALSE)
  license_info <- get_fs_license(simplify = FALSE)
  verbosity <- get_fs_verbosity(simplify = FALSE)

  cli::cli_h2("FreeSurfer Setup Report")

  # Core settings - simple and clean
  alert_info(fs_home, "FreeSurfer Directory")
  alert_info(
    get_fs_source(
      fs_home = fs_home$value,
      simplify = FALSE
    ),
    "Source script"
  )
  alert_info(license_info, "License File")
  alert_info(
    get_fs_subdir(fs_home = fs_home$value, simplify = FALSE),
    "Subjects Directory"
  )
  alert_info(verbosity, "Verbose mode")
  alert_info(
    get_mni_bin(fs_home = fs_home$value, simplify = FALSE),
    "MNI functionality"
  )
  alert_info(
    get_fs_output(simplify = FALSE),
    "Output Format"
  )

  # System information
  sysinfo <- sys_info()
  cli::cli_h3("System Information")
  cli::cli_li("Operating System: {.val {sysinfo$platform}}")
  cli::cli_li("R Version: {.val {sysinfo$r_version}}")
  cli::cli_li("Shell: {.val {sysinfo$shell}}")

  # Testing installation
  if (test_commands) {
    cli::cli_h3("Testing R and FreeSurfer Communication")

    # Test basic availability
    if (!have_fs()) {
      cli::cli_alert_danger("FreeSurfer installation not detected")
      cli::cli_li(
        "Use {.code options(freesurfer.home = '/path/to/freesurfer')} to set location"
      )
      return(invisible())
    }

    # Test version
    version_info <- fs_version()
    cli::cli_li("Version: {.val {version_info}}")

    # Test command execution - simple approach
    cli::cli_li("Testing command execution with {.code mri_info --help}")

    mri_info_result <- suppressMessages(mri_info.help())

    if (is.character(mri_info_result) && length(mri_info_result) > 0) {
      if (any(grepl("USAGE:|mri_info", mri_info_result, ignore.case = TRUE))) {
        cli::cli_alert_success("R and FreeSurfer are working together")
        cli::cli_li("Command test successful")
      } else {
        cli::cli_alert_warning(
          "FreeSurfer command executed but output format unexpected"
        )
        if (verbosity$value) {
          cli::cli_li(
            "Output preview: {.val {paste(head(mri_info_result, 2), collapse = ' | ')}}"
          )
        }
      }
    } else {
      cli::cli_alert_danger("FreeSurfer and R are not working together")
      cli::cli_li("Command execution failed or returned no output")
    }
  }

  # Simple recommendations
  cli::cli_h3("Recommendations")

  if (is.na(fs_home$value)) {
    cli::cli_li(
      "Set FreeSurfer home: {.code options(freesurfer.home = '/path/to/freesurfer')}"
    )
  } else if (is.na(license_info$value) || !license_info$exists) {
    cli::cli_li("Install FreeSurfer license file in {fs_home$value}")
  } else if (!verbosity$value) {
    cli::cli_li(
      "Enable verbose mode for better debugging: {.code options(freesurfer.verbose = TRUE)}"
    )
  } else {
    cli::cli_alert_success("FreeSurfer setup looks good!")
  }

  invisible()
}
```

With all that information, both the user and us should get enough context to figure out what is going wrong if they need help.


```
── FreeSurfer Setup Report ──

── FreeSurfer Directory 
• "/Applications/freesurfer"
! Determined from: `Default path`
✔ Path exists

── Source script 
• Unable to detect

── License File 
• Unable to detect

── Subjects Directory 
• Unable to detect

── Verbose mode 
• TRUE
! Determined from: `Default value`

── MNI functionality 
• Unable to detect

── Output Format 
• "nii.gz"
! Determined from: `Default value`

── System Information 
• Operating System:
"aarch64-apple-darwin20"
• R Version: "4.5.2 (2025-10-31)"
• Shell: "/bin/zsh"

── Testing R and FreeSurfer Communication 
✖ FreeSurfer installation not detected
• Use `options(freesurfer.home =
'/path/to/freesurfer')` to set location
```

## Design Principles

**Write checking functions, not checking code.** Extract validation logic into small, testable functions that return structured results.

**Structure over booleans.** Return lists with `valid`, `value`, and `message` instead of just TRUE/FALSE. 
This gives both functions and sitrep the context they need.

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

The usethis team built this pattern because they knew users (and them) needed help in diagnosing setup issues. 
If it works for them, it'll work for your API wrapper too.
