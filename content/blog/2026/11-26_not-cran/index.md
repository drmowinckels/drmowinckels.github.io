---
title: "The NOT_CRAN Line I Don't Remember Writing"
format: hugo-md
author: Dr. Mowinckel
date: "2026-11-26"
tags:
  - R
  - testthat
  - package-development
  - renviron
slug: not-cran
seo: |
  How a global NOT_CRAN=TRUE in ~/.Renviron changes which testthat tests run,
  why it cannot be overridden from the shell, and the one-line default-value
  syntax that keeps both agent-driven test runs and CRAN-like checks honest.
summary: >
  While getting the ggsegverse ready for CRAN, my `--as-cran` checks went red in ways CRAN would never see. The culprit was a single `NOT_CRAN=TRUE` in my `.Renviron` that I have no memory of writing. Here is what that variable actually does, why it turned out to be useful, and the small change that made it stop lying to me.
image: confused.png
image_alt: | 
  An Art Nouveau-style illustration of Dr. Mowinckel looking deeply confused and perplexed at a computer monitor. She is seated at a wooden desk, leaning forward with one hand touching her temple in bewilderment, furrowing her brow at the glowing screen. She has dark hair with short straight bangs, wearing a black cardigan embroidered with white daisies over an olive-green ribbed turtleneck.
  The ornate computer monitor is framed in decorative vintage brass and copper filigree,
  The scene is enclosed in an intricate, Alphonse Mucha-inspired decorative border featuring swirling botanical vines, monstera leaves, stylized brain motifs, and waveform flourishes in muted earthy jewel tones, sage green, and antique gold. A steaming coffee cup sits on the desk next to books and a keyboard. A hand-lettered banner at the bottom reads: "THE NOT_CRAN LINE I DON'T REMEMBER WRITING".
---

I have been getting a whole bunch of ggseg packages ready for CRAN lately.
Part of that is running `R CMD check --as-cran` over and over, so you know what CRAN will see before CRAN sees it.

Except mine didn't.
ggseg came back with 23 failing snapshot tests.
Tests that, on CRAN, would never have run at all.

The cause was line 2 of my `~/.Renviron`:

```sh
NOT_CRAN=TRUE
```

Facepalm.
And I'll be honest with you: I have no idea who put it there.
I don't remember writing it.
I've been leaning on LLM agents a lot lately, and I'm fairly sure one of them added it at some point and I just didn't notice.

Before we dig in, this is really a non-issue in most cases. 
Like, I **WANT** all the tests to run generally. 
This isn't really a bad default behaviour, it was just not what I was expecting.

So, let's look at what that one line does, because it turned out to be more interesting than "delete it and move on".

## What NOT_CRAN actually does

testthat decides whether you are "on CRAN" with a tiny internal function.
In testthat 3.3.2, it looks like this:

```r
testthat:::on_cran
#> function ()
#> {
#>     env <- Sys.getenv("NOT_CRAN")
#>     if (identical(env, "")) {
#>         !interactive()
#>     }
#>     else {
#>         !isTRUE(as.logical(env))
#>     }
#> }
```

CRAN never sets `NOT_CRAN`.
So on CRAN, the variable is empty, R is running non-interactively, and `on_cran()` returns `TRUE`.
Anything guarded by `skip_on_cran()` is skipped.

If `NOT_CRAN` is set to `TRUE`, that whole branch is bypassed, and testthat believes you are _not_ on CRAN, no matter how you are running things.

## It's not just skip_on_cran()

This is the part that surprised me.
I went looking for `skip_on_cran()` calls in the ggsegverse, expecting loads of them.

| Package       | `skip_on_cran()` | Snapshot expectations |
| ------------- | ---------------- | --------------------- |
| ggseg.extra   | 1                | 88                    |
| ggseg.formats | 0                | 31                    |
| ggseg3d       | 8                | 10                    |

One.
ggseg.extra, the package with all the external neuroimaging dependencies, has a single explicit CRAN skip.

But snapshot tests skip themselves on CRAN too.
`expect_snapshot()`, `expect_snapshot_file()` and `vdiffr::expect_doppelganger()` all have a `cran = FALSE` argument, and they consult the very same `on_cran()`.
So all those snapshots are quietly CRAN-skipped tests, and `NOT_CRAN=TRUE` switches every one of them back on.
That is exactly where ggseg's 23 failures came from: visual snapshots that genuinely did not match the new geometry, and that CRAN would never have compared.

So if you are thinking "I don't use `skip_on_cran()`, this doesn't concern me", check your snapshots.

## Your .Renviron beats your shell

My first instinct was to override it for one run:

```sh
NOT_CRAN=false; Rscript -e 'Sys.getenv("NOT_CRAN")'
#> [1] "TRUE"
```

Nope.
R reads `~/.Renviron` at startup and overwrites whatever the shell handed it.
Unsetting it with `env -u NOT_CRAN` doesn't help either, for the same reason.

And `R CMD check --as-cran` is no protection, because the R processes it starts read your `.Renviron` as well.
I made a tiny throwaway package with one test that is designed to fail, guarded by `skip_on_cran()`:

```r
test_that("only runs off CRAN", {
  skip_on_cran()
  expect_equal(1, 2)
})
```

With an empty `.Renviron`, `R CMD check --as-cran` skips it and passes.
With `NOT_CRAN=TRUE`, it runs and fails: `[ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]`.

Notice which direction this goes, though.
A global `NOT_CRAN=TRUE` makes you run _more_ tests than CRAN, not fewer.
A green local check is still trustworthy.
A red one might be red for reasons CRAN will never see.

## Why I'm keeping it anyway

So, delete the line?
That was the plan, until I thought about how R gets called these days.

Look at that `on_cran()` code again.
When `NOT_CRAN` is empty, it falls back to `!interactive()`.
In your console, `interactive()` is `TRUE`, so everything runs, and you never notice anything.
But agents don't sit in a console.
They call R from the shell, with `Rscript`, where `interactive()` is `FALSE`.

I ran that same throwaway test from the shell, with `NOT_CRAN` unset, through the entry points an agent is likely to reach for:

| Called from the shell                                                 | The `skip_on_cran()` test |
| --------------------------------------------------------------------- | ------------------------- |
| `devtools::test()`, `testthat::test_local()`                          | Runs                      |
| `testthat::test_file()`, `test_dir()`, `devtools::test_active_file()` | Skipped                   |
| `covr::package_coverage()`                                            | Skipped                   |
| `R CMD check`                                                         | Skipped                   |

`devtools::test()` is fine, because `test_local()` sets `NOT_CRAN` for you behind the scenes.
But the moment an agent runs a single test file to check its own fix, or runs coverage, every CRAN-skipped test and every snapshot quietly disappears.
The output says zero failures.
The agent says "all tests pass".
Technically true, and not at all what you wanted.

So whoever wrote that line, it was doing a real job.

## The fix: a default, not a value

`.Renviron` supports a default-value syntax.
Instead of setting the variable outright, you can say "use `TRUE` unless something already set it":

```sh
NOT_CRAN=${NOT_CRAN-TRUE}
```

Now everything that calls R without thinking about it, agents included, still gets `TRUE`.
And when you want a check that behaves like CRAN, you ask for one:

```sh
NOT_CRAN=false R CMD check --as-cran mypkg_0.1.0.tar.gz
```

Back to the throwaway package:

| `.Renviron` line            | `NOT_CRAN=false R CMD check --as-cran` |
| --------------------------- | -------------------------------------- |
| `NOT_CRAN=TRUE`             | Override ignored, test runs and fails  |
| `NOT_CRAN=${NOT_CRAN-TRUE}` | Test skipped, check passes, like CRAN  |

Weee, both worlds!

## Use your own switch for things you really care about

One last thing the hunt taught me.
The reason I might have wanted `NOT_CRAN` in the first place was to make sure tests that touch external tools actually ran.
ggseg.extra drives FreeSurfer, and I want those tests exercised, not skipped.

But `NOT_CRAN` was never doing that job.
Those tests are guarded by our own helper, and it has its own switch:

```r
skip_if_no_freesurfer <- function() {
  if (nzchar(Sys.getenv("GGSEG_REQUIRE_FREESURFER"))) {
    if (!freesurfer::have_fs() || !nzchar(Sys.which("mri_info"))) {
      stop("GGSEG_REQUIRE_FREESURFER is set but FreeSurfer is not available")
    }
    return(invisible(TRUE))
  }
  skip_on_os("windows")
  skip_if_not_installed(
    "freesurfer",
    minimum_version = freesurfer_min_version()
  )
  if (!freesurfer::have_fs() || !nzchar(Sys.which("mri_info"))) {
    skip("FreeSurfer not available")
  }
}
```

Set `GGSEG_REQUIRE_FREESURFER`, and a missing FreeSurfer is an error instead of a silent skip.
That is a much better pattern for "this must run here" than overloading a variable that means "pretend I'm not CRAN".
It says exactly what it does, and nothing else.

## Go look at your .Renviron

It is a small file, it affects every R session you start, and it is very easy to forget about.
Especially now, when something other than you might be editing it.

```r
usethis::edit_r_environ()
```

Have a read.
If there is a line in there you don't recognise, it might be doing something useful.
Find out what before you delete it.
