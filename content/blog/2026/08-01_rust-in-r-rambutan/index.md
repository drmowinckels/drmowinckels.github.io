---
title: A Rust Crate, an R Package, and One Very Stubborn Windows Crash
format: hugo-md
author: Dr. Mowinckel
date: '2026-08-01'
tags:
  - R
  - rust
  - extendr
  - cran
  - package-development
slug: rust-in-r-rambutan
image: featured.png
image_alt: >
  The rambutan R package hex logo. Three spiky rambutan fruits in shades of
  maroon and dusty pink sit inside a pale pink hexagon; the largest is
  half-peeled to reveal a smiling white face. The word "rambutan" runs across
  the bottom in rounded dark red letters.
seo: |
  Wrapping the Rust lychee crate in an R package with extendr — why I skipped
  CRAN, how to embed a Tokio runtime in R, and the Windows exit crash that took
  four attempts to fix.
summary: >
  I wanted a fast link checker in R, so I wrapped the Rust lychee crate with
  extendr. Along the way I had to decide whether CRAN was even possible (it
  wasn't, really), work out how to run async Rust from inside R, and chase down
  a Windows crash that only happened after every test had already passed. This
  is the whole trip, including the three fixes that didn't work.
---


There is a Rust crate called [lychee](https://github.com/lycheeverse/lychee) that checks links.
It is fast, it is async, and it does in seconds what my pure-R tooling does in minutes.
I wanted it in R.

What I did not know --- at all --- was how you get a Rust crate into an R package, and what CRAN makes of the whole idea.
So before writing a line of code, we went and found out.

I say "we" because I did this with Claude as a pairing partner, which mostly means I had someone to argue with about tradeoffs at 11pm.
The decisions are mine. The three failed fixes are also mine.

## What the research turned up

The mature path for Rust in R is [extendr](https://extendr.github.io/) and its R-side companion `rextendr`.
It is R Consortium-funded, and around 28 CRAN packages already use it.
There is a newer, more minimal alternative called `savvy`.
Neither is blessed by CRAN --- CRAN is toolchain-agnostic, it just has rules, and the rules are where it gets interesting.

CRAN's build machines have no network access.
That single constraint drives everything else: every one of your crate's dependencies has to be `cargo vendor`'d into the source tarball you submit.
Source tarballs should stay under roughly 10MB.
You should assume the Rust toolchain on the check machine is two to four years old.
And you cannot install Rust as part of your build --- you declare it in `SystemRequirements` and hope.

Then I went and measured what lychee actually costs.

`lychee-lib`, the library half of the crate, pulls in somewhere between 300 and 330 transitive crates.
An honest `cargo vendor` run came out at **17.3MB compressed**.
That is already past CRAN's ceiling before I have written any of my own code.
A big chunk of it is `octocrab`, which handles lychee's GitHub API checks and drags in a second crypto backend; `aws-lc-sys` alone is 67MB raw.
lychee-lib's minimum supported Rust version is 1.88, which is very recent, and directly at odds with "assume an old toolchain."

And there is a cautionary tale sitting right there: R `polars` tried to get onto CRAN for years, wrapping a big Rust crate, and eventually gave up.
It ships via r-universe now.

## Picking the channel before writing the code

I'll be honest, my first instinct was to find a way to make CRAN work.
CRAN is where R packages live. Skipping it feels like opting out of the neighbourhood.

There was a cheaper option available, too: don't bind the library at all, just shell out to the compiled `lychee` CLI and parse its JSON output.
That is a legitimate pattern --- it's roughly how R packages wrap `ripgrep` or `fd` --- and it sidesteps vendoring, the 300-crate build, and the whole async problem.
The cost is that your package now depends on a binary being on the user's machine, which is its own kind of fragile.

I went the other way.
r-universe, real bindings, no CRAN.

The thing that made it an easy call once I said it out loud: r-universe's build servers have network access.
No vendoring, no 17MB tarball, no trimming lychee's features to fit a budget, no fighting the MSRV.
I could just depend on the current `lychee-lib` and move on.

Here's the number that retroactively confirmed it: a clean build of this package takes about **13 minutes**, compiling that whole dependency tree from scratch.
That's fine locally and fine on r-universe, which caches between builds.
It would have been a serious problem inside CRAN's check-time budget.

The trade I made is real and I don't want to soften it.
Nobody will `install.packages("rambutan")` and have it work.
Anyone who installs it needs a Rust toolchain on their machine.
That is a smaller audience, and I decided a smaller audience for a working package beat a larger audience for a package that never ships.

The package is called rambutan, incidentally, because a rambutan and a lychee are cousins --- same family, spikier packaging.

## Running async Rust from inside R

Every public function in `lychee-lib` is an `async fn`.
There is no synchronous wrapper.
R, meanwhile, has no idea what a future is and would like you to just return a value.

So the binding has to stand up a Tokio runtime, hand it the future, and block until it comes back.
extendr documents this pattern, and it's the part I was most nervous about, because embedding someone else's async runtime inside R's process is exactly the sort of thing that works on your laptop and then doesn't.

It worked on the first try.
A live 200, a real 404, and a dead domain correctly flagged:

``` r
library(rambutan)

check_url("https://www.r-project.org")
#> $url
#> [1] "https://www.r-project.org"
#>
#> $is_success
#> [1] TRUE
#>
#> $code
#> [1] 200
#>
#> $details
#> [1] "200 OK"
```

There's a small delight in there too --- lychee automatically excludes `.invalid` domains, because [RFC 6761](https://www.rfc-editor.org/rfc/rfc6761) reserves that TLD for exactly this kind of "definitely not real" use.
I got that behaviour for free by wrapping someone else's careful work, which is the whole point of wrapping someone else's careful work.

From there the API filled out: `check_urls()` for concurrent checks that preserve input order, `check_paths()` for scanning files, directories, and globs using lychee's own Markdown and HTML extractors, and `check_package()`, which scans an R package's `DESCRIPTION`, Rd files, `NEWS`, `CITATION`, and vignettes --- the same set CRAN's own URL check looks at.

``` r
check_urls(c("https://www.r-project.org", "https://cran.r-project.org"))
#>                          url is_success code details
#> 1  https://www.r-project.org       TRUE  200  200 OK
#> 2 https://cran.r-project.org       TRUE  200  200 OK

check_project(".")
```

Then I turned on CI, and Windows started screaming.

## The crash that happened after everything passed

Here is the shape of the bug, because the shape is the interesting part.

On `windows-latest`, `R CMD check` reported an ERROR from the test step.
But when I pulled the actual test output from the CI artifact, it read:

    [ FAIL 0 | WARN 0 | SKIP 0 | PASS 101 ]

Every test passed.
Then the R process exited with `-1073740791`, which is `0xC0000409`, which is `STATUS_STACK_BUFFER_OVERRUN` --- Windows' stack-cookie check firing.
Not a generic failure. A specific, native, "something corrupted memory during teardown" failure.

The function worked. The result was correct. The process just refused to die politely.

In practice this only bites non-interactive use where someone checks the exit code --- `Rscript` in a CI step, basically.
Interactively it was invisible.
Which made it very tempting to leave alone, and I did leave it alone for a while.

### Three fixes that didn't work

My first assumption was that this was my fault, and specifically that it was the Tokio runtime.
That is a reasonable assumption. It was also wrong three times in a row.

**Attempt one: switch the runtime from multi-threaded to current-thread.**
The multi-threaded scheduler spawns persistent background OS threads, and persistent background OS threads are a classic way to make process teardown unhappy.
Result: identical crash.

**Attempt two: leak the runtime with `Box::leak` so its `Drop` never runs.**
This is a well-established fix for this exact class of bug in other embedded-Rust contexts --- if teardown is what crashes, don't tear down.
Result: instead of failing at 10 to 13 minutes, the job ran for 19 and a half minutes on the same step with no resolution.
I traded a crash for a hang, and cancelled it rather than let it sit there for the six-hour default timeout.

That's a genuinely informative failure, though.
A hang means something was waiting for the runtime's shutdown signal that never came.
So the state does need to be torn down --- it just crashes when teardown happens during process exit.

**Attempt three: build a fresh runtime per call and shut it down explicitly before returning to R.**
No static, no global, nothing surviving past the `.Call()` boundary.
Teardown now happens at a deterministic, safe point in the middle of a call rather than during DLL unload.
Result: identical crash.

And that is the one that mattered, because it ruled out my own code entirely.
There was no Tokio state left to blame.
Whatever was crashing was in somebody else's teardown.

At that point I documented it as a known issue in `?rambutan`, put `continue-on-error` on the Windows matrix job so it stayed visible but non-blocking, and moved on.
I want to be clear that this felt bad.
A known-broken platform with a workaround is a thing you tell yourself you'll come back to.

### The part that actually changed the game

The single most useful thing I did in this whole investigation was not a fix.
It was building a faster loop.

A full `R CMD check` on Windows costs 20 to 40 minutes.
At that price, every hypothesis is an expensive guess, and after two or three of them you start reaching for whatever is cheap to try rather than whatever is likely to be true.

So I wrote a throwaway Windows-only workflow that did exactly one thing: load the package, call `check_url()` once, print the result, exit.
Minutes instead of tens of minutes.
That's what turned "guessing" back into "debugging", and it's what let me confirm the fix three times over instead of once.

## What it actually was

Coming back to it later, the question I asked was different: what variable has nobody tested yet?

The answer was the TLS crypto backend.

`reqwest`'s default `rustls` feature hardcodes `aws-lc-rs` as its crypto provider.
I confirmed this by reading `cargo tree -e features` rather than assuming.
And rambutan builds for `x86_64-pc-windows-gnu` --- the MinGW/Rtools target, which is what R uses on Windows, and which is the less-travelled of the two Windows targets.

Now, `aws-lc-rs`'s own documentation says `x86_64-pc-windows-gnu` is CI-tested.
That is true and it is also not the situation we're in.
They test it as a standalone binary.
An R package is a DLL, dynamically loaded into a long-lived host process, and potentially unloaded mid-session while that host keeps running.

That distinction is worth sitting with if you're wrapping any Rust crate for R.
Crates test themselves as programs.
Your package is a guest inside somebody else's program.
Those are different lifecycles, and teardown is exactly where the difference shows up.

The fix is small.
`reqwest` only falls back to `aws-lc-rs` if no process-wide `CryptoProvider` has already been installed --- I read reqwest's source to confirm this rather than trusting the docs.
So install rustls' `ring` provider first, before the first client is ever built:

``` rust
static INSTALL_CRYPTO_PROVIDER: std::sync::Once = std::sync::Once::new();

fn ensure_crypto_provider() {
    INSTALL_CRYPTO_PROVIDER.call_once(|| {
        let result = rustls::crypto::ring::default_provider().install_default();
        debug_assert!(
            result.is_ok(),
            "a rustls CryptoProvider was already installed before rambutan could install ring; \
             the aws-lc-rs Windows exit crash this guards against may resurface"
        );
    });
}
```

`ring` has years of solid Windows-GNU track record.
`aws-lc-rs` is comparatively new there.

Note what this does and does not do.
`aws-lc-rs` is still compiled into the binary --- Cargo's feature unification means another dependency drags it in and I can't remove it.
It just never runs.
That's a workaround, not a cure, and the `debug_assert!` is there to shout if some future dependency installs a provider before I get there.

Three clean runs on the fast debug workflow, against a crash that had been 100% reproducible.
Then the real thing: the full `R-CMD-check.yaml`, all five matrix targets, 120 tests, vignettes and all.

`windows-latest` passed. 24 minutes and 47 seconds, genuinely green for the first time in the package's history.
Then I removed the `continue-on-error`, pushed again, and watched it pass as a real blocking check.

## What I'd tell you before you start

**Decide your distribution channel before you write Rust, not after.**
CRAN versus r-universe isn't a packaging detail you sort out at the end.
It determines your MSRV, whether you vendor, and how big a dependency tree you can afford.
Answering it first would have saved me a day.

**"It works but the process dies" is a real category of bug.**
When your tests pass and the exit code is still wrong, stop looking at your logic.
The bug is in teardown, and teardown is mostly other people's code.

**Your package is a guest in someone else's process.**
A crate that is well-tested as a binary has not been tested as a DLL loaded into R and unloaded mid-session.
That gap is where the ugly platform-specific bugs live.

**Build the fast loop before the third guess, not after.**
If a hypothesis costs 30 minutes to test, you will start optimising for cheap hypotheses instead of good ones.

**Ruling things out is progress.**
Those three failed Tokio fixes weren't wasted work.
They're the reason the fourth attempt was an informed experiment rather than a fourth guess.

## Where it is now

rambutan lives at [github.com/drmowinckels/rambutan](https://github.com/drmowinckels/rambutan), with a [pkgdown site](http://drmowinckels.io/rambutan/).

``` r
# install.packages("pak")
pak::pak("drmowinckels/rambutan")
```

You'll need Cargo and rustc --- see [rustup.rs](https://rustup.rs/).
That requirement is the honest cost of the CRAN decision, and it's the thing I'd most like to make disappear.

It's still not on CRAN, and I've made my peace with that.
`aws-lc-rs` is still sitting in the binary, unexercised, waiting for an upstream fix that may or may not come.
And I still cannot reproduce that Windows crash locally, on a Mac, which means the next Windows-only surprise will cost me another round of CI archaeology.

Worth it, though.
Link checking is fast now.
