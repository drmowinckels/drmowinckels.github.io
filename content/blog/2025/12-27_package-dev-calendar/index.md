---
title: 'R Package Development Advent Calendar 2025: A Complete Journey'
author: Dr. Mowinckel
date: '2025-12-26'
format:
  hugo-md:
    filters:
      - ../../../../figure-to-markdown.lua
categories:
  - R
  - packages
  - development
  - advent
  - tutorial
seo: 25 days of modern R package development tools, techniques, and best practices
summary: >-
  A comprehensive guide to modern R package development, covering setup,
  documentation, testing, CI/CD, and CRAN submission, a summary of a social
  media advent calendar.
image: pak-dev-cal.jpeg
---


Over the past 25 days, we've explored the complete modern R package development workflow through the #RPackageAdvent2025 advent calendar.  
From initial project setup to CRAN submission, we covered the essential tools and techniques that professional R developers use to create high-quality packages.

This post serves as a comprehensive reference guide, capturing all the insights, tools, and best practices shared throughout the advent calendar.  
Whether you're just getting started with package development or looking to modernize your workflow, you'll find actionable advice for every stage of the process.

## Why This Calendar?

The R package development ecosystem has evolved dramatically over the past decade.  
Tools like `usethis`, `pkgdown`, and GitHub Actions have automated what used to be tedious, error-prone manual work.  
Yet many developers still follow outdated workflows, missing out on productivity gains and quality improvements.

This advent calendar was designed to bridge that gap---offering bite-sized, practical lessons that you can implement immediately in your packages.  
It comprises my favorite tools and techniques that I've found invaluable in my own package development journey.

## Week 1: Foundation & Setup (Days 1-6)

### Day 1: `usethis` - Project Setup Automation 🎯

The `usethis` package is the cornerstone of modern R package development.
Instead of manually creating DESCRIPTION files, writing configuration from scratch, or copying YAML you don't fully understand, `usethis` automates everything with best practices built in.

**Key functions:**

``` r
usethis::create_package("~/mypackage")
usethis::use_mit_license()
usethis::use_github_action("check-standard")
usethis::use_testthat(3)
usethis::use_pkgdown()
usethis::use_news_md()
```

**Why it matters:**  
What used to take 2-3 hours of setup now takes 5 minutes.  
More importantly, you won't forget crucial infrastructure like NEWS.md files or proper .Rbuildignore entries.

**Pro tip:**  
Set up your preferences once with `usethis::edit_r_profile()` and every package inherits them automatically.  
I have this set up:

``` r
options(
  usethis.full_name = "Athanasia M. Mowinckel",
  usethis.description = list(
    "Authors@R" = utils::person(
      given = "Athanasia Mo",
      family = "Mowinckel",
      email = "a.m.mowinckel@psykologi.uio.no",
      role = c("aut", "cre"),
      comment = c(ORCID = "0000-0002-5756-0223")
    ),
    Version = "0.0.0.9000"
  ),
  usethis.destdir = "~/workspace/rproj/"
)
```

**Pro tip 2:**
When in doubt of what function to use, type `usethis::use_` in the console of RStudio or Positron and hit `Tab` to see all available options.

See \[usethis documentation\][^1].

### Day 2: `devtools` - Essential Development Workflow 🔧

The `devtools` package revolutionizes the package development iteration cycle.
Traditional development meant constantly quitting R, rebuilding packages, and restarting---a cycle that consumed hours of productive time.

**The magic workflow:**

``` r
# Instant feedback on changes
devtools::load_all()    

# Update documentation
devtools::document() 

# Run tests without reinstalling
devtools::test()  

# Full CRAN checks locally
devtools::check()
```

**Why `load_all()` is revolutionary:**  
It simulates installing your package without actually installing it.  
Test functions immediately, try different approaches rapidly, and maintain state between iterations.  
Learn the keyboard shortcuts for even faster workflow:

**Essential keyboard shortcuts:**  
- `Ctrl/Cmd + Shift + L`: load_all()  
- `Ctrl/Cmd + Shift + T`: test()  
- `Ctrl/Cmd + Shift + D`: document()  
- `Ctrl/Cmd + Shift + E`: check()

**Impact:**  
Shaving 30 seconds off each iteration, across 100 daily iterations, saves 50 minutes per day.  
That's hours per week spent building features instead of waiting.

**Gotcha:**
`load_all` also loads internal package functions, as if they were exported.
This can mask bugs that only appear when the package is installed properly, and accessed by users.  
Always run `devtools::check()` before submission to catch these issues.

See \[devtools documentation\][^2].

### Day 3: GitHub Actions - CI/CD Setup 🚀

Platform-specific bugs are a nightmare.
Your package works perfectly on your Mac, but breaks on Windows due to path separators or fails on Linux due to file permissions.
GitHub Actions solves this by testing your package on multiple platforms automatically with every push.

**Setup:**

``` r
usethis::use_github_action("check-standard")
usethis::use_github_action("test-coverage")
usethis::use_github_action("pkgdown")
```

**What happens automatically:**  
- Tests run on Windows, macOS, and Ubuntu  
- Multiple R versions tested (devel, release, oldrel)  
- Coverage tracked and reported  
- Documentation website deployed

**Real example:**  
I once added a function using `tempdir()` that worked perfectly on macOS but failed on Windows due to path separator differences.  
GitHub Actions caught this in 8 minutes, not 8 days after CRAN submission.

**Tip:**
Customize workflows by editing the YAML files in `.github/workflows/`.
Add a schedule to run checks weekly, i.e to the `check-standard.yaml` file, this way you can catch issues that arise from changes in dependencies.

``` yaml
on:
  schedule:
    - cron: '0 0 * * 0'  # Every Sunday at midnight
```

See \[GitHub Actions documentation\][^3].

### Day 4: `.Rbuildignore` and `.gitignore` Best Practices 📁

These "invisible" files control what gets included in your package and repository.
Get them wrong and you'll either leak credentials, bloat your package, fail build chekcs, or confuse users with development artifacts.

**Two distinct jobs:**  
- `.gitignore`: Keeps secrets and local files OFF GitHub  
- `.Rbuildignore`: Keeps development files OUT of your CRAN package

**Essential .Rbuildignore entries:**

    ^.*\.Rproj$
    ^\.Rproj\.user$
    ^README\.Rmd$
    ^\.github$
    ^_pkgdown\.yml$
    ^docs$

**The usethis way:**

``` r
usethis::use_build_ignore("dev_script.R")
usethis::use_git_ignore("private_data/")
```

**Common disaster:**  
Accidentally committing `.httr-oauth` with API credentials.  
Once in git history, those credentials are public forever (there are ways to purge git history, but that is not something you want to deal with!).  
Add it to `.gitignore` immediately.

### Day 5: Package Structure with `pkgdown` Site Generation 🌐

Documentation quality determines package adoption.
Reading `?my_function` in a terminal is a poor user experience compared to browsing a beautiful, searchable website with syntax highlighting and navigation.

**Setup is trivial:**

``` r
usethis::use_pkgdown()
pkgdown::build_site()
```

**What you get:**  
- Professional website with all function documentation  
- Vignettes displayed as articles  
- README as landing page  
- Changelog from NEWS.md  
- Full-text search

**Auto-deployment:**

``` r
usethis::use_github_action("pkgdown")
```

Now your site rebuilds and deploys automatically with every push.  
Documentation always stays current.

See \[pkgdown documentation\][^4].

**Resources:** [pkgdown.r-lib.org](https://pkgdown.r-lib.org/)

### Day 6: `pre-commit` Hooks for R 🪝

We've all committed code with trailing whitespace, forgotten to run `devtools::document()`, or left debug `print()` statements in the code.
Pre-commit hooks catch these mistakes before they reach your repository.

**Setup:**

``` r
precommit::use_precommit()
```

**What runs automatically on every commit:**  
- Code formatting with styler  
- Style checks with lintr  
- Documentation updates via roxygenize  
- Syntax validation  
- README.md stays current with README.Rmd

**Why it matters:**  
Pre-commit hooks are like spell-check for code.  
They prevent embarrassing mistakes, enforce consistency, and save time.  
Setup once, benefit forever.

See \[pre-commit documentation\][^5].

## Week 2: Documentation & Communication (Days 7-13)

### Day 7: `roxygen2` Advanced Tags and Cross-References 📝

Most developers learn the basics of roxygen2 (`@param`, `@return`, `@export`) and stop there.
But roxygen2's advanced features transform documentation from a chore into an interconnected knowledge base.

**Cross-references that become clickable links:**

``` r
#' @seealso [other_function()] 
#' @family data manipulation
```

**The `@inheritParams` superpower:**

``` r
#' @param data A data frame
#' @param col Column to use
parent_function <- function(data, col) {}

#' @inheritParams parent_function
child_function <- function(data, col, extra) {}
```

Update parameter documentation once, it propagates everywhere.
DRY (Do not Repeat Yourself) principle for documentation.

**The `@inheritDotParams` magic:**

``` r
#' @inheritDotParams ggplot2::theme
my_plot <- function(...) {}
```

All parameters from `theme()` are now documented in your function without typing them.

**Section tags for organization:**

``` r
#' @section Warning:
#' This function modifies data in place.
#'
#' @section Performance:
#' For large datasets, consider using data.table.
```

See \[roxygen2 documentation\][^6].

### Day 8: `pkgdown` Customization and Deployment 🎨

Default pkgdown sites are functional but forgettable.
Customization isn't vanity---it's about creating memorable user experiences and improving navigation.

**Modern styling:**

``` yaml
template:
  bootstrap: 5
  params:
    bootswatch: flatly
```

**Organize functions logically:**

``` yaml
reference:
  - title: "Data Input"
    contents:
    - read_*
  - title: "Processing"
    contents:
    - has_concept("manipulation")
```

One developer reorganized 60 alphabetically-listed functions into logical groups and saw support questions drop by 40%.
When users find what they need, they don't email you.

**Add your hex logo:**

``` yaml
home:
  logo: man/figures/logo.png
```

Check out [Melissa Van Bussel's](https://www.melissavanbussel.com/) [R/Medicine 2025 talk](https://www.youtube.com/watch?v=aMVdZX6dhIc) for a great run through!

See \[pkgdown documentation\][^7].

### Day 9: Vignettes with `knitr` and `rmarkdown` 📖

Function documentation explains *what* parameters do.
Vignettes explain *why* and *how* to use your package.
Users need complete workflows, not isolated function calls.

**Create your first vignette:**

``` r
usethis::use_vignette("getting-started")
```

**Best practices:**

-   Start with a clear problem statement  
-   Show complete workflows, not code fragments  
-   Keep computation under 5 minutes  
-   Use [pre-computed](https://ropensci.org/blog/2019/12/08/precompute-vignettes/) results for heavy tasks  
-   Use real examples, not toy datasets

**Why vignettes matter:** One good vignette prevents 100 support emails and converts confused users into enthusiastic advocates who recommend your package.

### Day 10: `lifecycle` - Managing Function Deprecation 🔄

Package evolution is inevitable.
You need to rename functions or change behavior, but users have production code depending on current versions.
The `lifecycle` package makes evolution graceful.

**Setup:**

``` r
usethis::use_lifecycle()

#' @lifecycle deprecated
old_function <- function() {
  lifecycle::deprecate_warn("1.0.0", "old_function()", "new_function()")
  new_function()
}
```

**The lifecycle stages:**
experimental → stable → superseded → deprecated → defunct

**Why this matters:** tidyverse packages serve millions of users and evolve constantly without breaking everyone's code. lifecycle is how they do it.

**Resources:** [lifecycle.r-lib.org](https://lifecycle.r-lib.org/)

### Day 11: NEWS.md and Semantic Versioning 📰

When users see an available update, they ask:
"Will this break my code? What changed? Should I wait?"
Without NEWS.md, they skip the update or update blindly.

**Semantic versioning communicates risk:**

-   MAJOR version (1.0.0 → 2.0.0): possible breaking changes  
-   MINOR version (1.0.0 → 1.1.0): new features, backwards compatible  
-   PATCH version (1.0.0 → 1.0.1): bug fixes only

**NEWS.md structure:**

``` markdown
# mypackage 1.2.0

## New features
* Added `new_function()` for advanced analysis (#15)

## Bug fixes
* Fixed missing value handling in `existing_function()` (#12)

## Breaking changes
* Renamed `old_param` to `new_param` in `main_function()`
```

**Link to GitHub issues:** `(#15)` creates automatic links so users can see full context and discussion.

### Day 12: README.Rmd Automation 📝

Static README.md files show fake examples with made-up output.
Over time, code drifts from reality, examples break, and users copy-paste non-working code.
README.Rmd solves this by running real code and capturing actual output.

**Setup:**

``` r
usethis::use_readme_rmd()
```

**Essential sections:**

-   Installation instructions (CRAN/GitHub/r-universe)  
-   Quick example with real output  
-   Badges (build status, coverage, CRAN version)  
-   Link to full documentation

**Auto-render in CI:**

``` yaml
- name: Render README
  run: Rscript -e 'rmarkdown::render("README.Rmd")'
```

**Impact:** README examples that actually work build trust immediately.
The first 30 seconds on your README determine if users try your package.

### Day 13: `covr` - Test Coverage Reporting 📊

You write tests and feel confident, then a user finds a bug in completely untested code.
Coverage metrics reveal these blind spots.

**Check your coverage:**

``` r
covr::package_coverage()
covr::report()  # Interactive HTML report
```

**The 80% rule:** Chasing 100% coverage means testing trivial getters/setters.
Focus on complex logic, edge cases, and error handling.
80% meaningful coverage beats 100% checkbox coverage.

**CI integration:**

``` r
usethis::use_github_action("test-coverage")
usethis::use_coverage()  # Adds codecov badge
```

See \[covr documentation\][^8].

## Week 3: Testing & Quality (Days 14-20)

### Day 14: `testthat` 3rd Edition Features ✅

Edition 3 of testthat brings snapshot testing, better error messages, and cleaner setup/teardown patterns.

**Upgrade:**

``` r
usethis::use_testthat(3)
```

**Snapshot tests:**

``` r
test_that("error messages stay helpful", {
  expect_snapshot(my_function(bad_input), error = TRUE)
})
```

**Better organization:**

-   Helper functions in `tests/testthat/helper.R`  
-   `setup.R` runs before all tests  
-   `teardown.R` runs after all tests
    -   if you are making temp files etc, I recommend using `withr::temp_file()` and `withr::temp_dir()` inside individual tests instead of global setup/teardown.

**Write descriptive test names:**

``` r
test_that("function handles missing values by imputing mean", {})
```

Not: `test_that("test1", {})`

I've recently also started using the `describe()` function to group related tests together, like so:

``` r
describe("some_function()", {
  it("removes duplicates correctly", {})
  it("handles missing values appropriately", {})
})
```

See \[testthat documentation\][^9].

### Day 15: Snapshot Testing with `testthat` 📸

How do you test error messages, warnings, or complex print output?
Writing explicit assertions is tedious and brittle.
Snapshot testing solves this.

**Text snapshots:**

``` r
test_that("informative errors", {
  expect_snapshot(my_function(bad_input), error = TRUE)
})
```

First run captures output to a file.
Future runs compare against that snapshot.
Any difference causes test failure with a clear diff.

**Plot snapshots with vdiffr:**

``` r
library(vdiffr)
test_that("plot is stable", {
  p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
  vdiffr::expect_doppelganger("mtcars-scatter", p)
})
```

First run will save an svg of the plot, and then subsequent runs will compare against that.
Differences will trigger error, and you can review the diff visually.

**Critical:** Review snapshot changes carefully.
Intentional improvement?
Accept new snapshot. Unintentional regression?
Fix your code.

### Day 16: Testing with Mocks using `testthat` 🎭

Your function calls an API, database, or file system.
Tests shouldn't hit real external services.
Mocking lets you test your logic in isolation.

**Local mocking:**

``` r
test_that("handles API failure gracefully", {
  local_mocked_bindings(
    api_call = function(...) stop("API unavailable")
  )
  expect_error(my_function(), "API unavailable")
})
```

**Mock successful responses:**

``` r
test_that("processes API response", {
  local_mocked_bindings(
    fetch_data = function(...) list(status = "success", data = mtcars)
  )
  result <- my_function()
  expect_equal(nrow(result), 32)
})
```

**Why `local_mocked_bindings`:** Scoped to the test.
Real function automatically restored afterward.
No side effects between tests.

### Day 17: `vcr` - Recording API Calls for Tests 📼

Testing API interactions is challenging.
You need real responses but can't hit live APIs constantly (slow, rate limits, authentication required).
`vcr` records real API responses once, then replays them forever.

**Setup:**

``` r
library(vcr)
vcr_configure(dir = "tests/fixtures/vcr_cassettes")

test_that("API returns expected data", {
  use_cassette("github_api", {
    response <- httr::GET("https://api.github.com/users/octocat")
    expect_equal(httr::status_code(response), 200)
  })
})
```

**How it works:** First run hits the real API and saves the response to a "cassette" file.
Subsequent runs read from that file.
Tests are fast, reliable, and work offline.

**For vignettes too:**
use chunk labels, and cassettes will be created for vignette code as well.

    ```r
    #| label: github_api_vignette
    #| cassette: true
    ```

See \[vcr documentation\][^10].

### Day 18: `lintr` and `styler` - Code Quality ✨

Three contributors with three different coding styles leads to code reviews focused on spacing instead of logic.
Automated formatting solves this.

**Automate style:**

``` r
# Formats entire package
styler::style_pkg()    

# Finds style issues
lintr::lint_package()  
```

**Configure once:**

    # .lintr file
    linters: linters_with_defaults(
      line_length_linter(120),
      commented_code_linter = NULL
    )

**IDE integration:**
RStudio has styler in the Addins menu.
VSCode's R extension includes lintr support.
Some configure format-on-save.

**Impact:**
Consistent style = readable code = fewer bugs = faster code reviews.
Automate it and focus on logic, not formatting debates.

### Day 19: `goodpractice` - Package Health Checks 🏥

Is your package well-structured?
Are functions too complex?
Missing docs?
Checking manually takes hours.
`goodpractice` checks everything automatically.

**Run the check:**

``` r
goodpractice::gp()
```

**What it catches:**
- Functions over 50 lines (complexity warning)  
- Unused imports (unnecessary dependencies)  
- Missing documentation  
- Low test coverage  
- Common anti-patterns

**Tips :**
You don't have to fix everything.
Focus on high-impact issues, and improve incrementally.
Set a goal to reduce warnings over time, but don't obsess over perfection.

**Before CRAN submission:**

Always run `gp()` and fix warnings.
Your CRAN submission will go much smoother.

**Resources:**
[github.com/mangothecat/goodpractice](https://github.com/mangothecat/goodpractice)

### Day 20: Performance Testing with `bench` ⚡

"I think this approach is faster" is guessing.
Microbenchmarking is proof.

**Compare approaches:**

``` r
library(bench)
results <- bench::mark(
  old_approach = old_function(data),
  new_approach = new_function(data),
  iterations = 100
)
plot(results)
```

**Memory matters too:**

``` r
bench::mark(
  my_function(big_data),
  filter_gc = FALSE
)
```

Sometimes the "faster" solution uses 10x more memory. bench reveals the tradeoff.

**Best practice:**
Include benchmarks in your test suite.
If new code makes critical functions slower, tests should fail.

## Week 4: Advanced Features (Days 21-25)

### Day 21: `rhub` - Multi-Platform Testing 🌍

CRAN tests your package on Windows, macOS, and multiple Linux distributions.
Platform-specific bugs are submission killers.
rhub lets you test before submission.
You might have set up GitHub Actions for CI, but rhub provides additional platforms and more CRAN-like environments.

**Pre-submission testing:**

``` r
rhub::check_for_cran()
```

**Platform-specific checks:**

``` r
rhub::check_on_windows()
rhub::check_on_macos()
rhub::check(platform = "debian-clang-devel")
```

**The confidence workflow:**
Run rhub checks + GitHub Actions before CRAN submission.
If both pass, CRAN will very likely accept.

**Impact:**
CRAN rejection wastes 2+ weeks waiting for resubmission review.
rhub finds issues in hours.

See \[rhub documentation\][^11].

### Day 22: S3, S4, and S7 Object Systems 🎯

R has three object systems, each with different strengths.
Choose based on your needs, not trends.

**S3 - Simple & Common:**

``` r
#' @export
print.my_class <- function(x, ...) {
  cat("My object:", length(x), "elements\n")
  invisible(x)
}
```

95% of CRAN packages use S3.
Easy, flexible, good enough for most cases.

**S4 - Strict & Validated:**

``` r
setClass("MyClass",
  slots = list(data = "data.frame", metadata = "list"),
  validity = check_validity
)
```

For complex class hierarchies and strict validation.
Bioconductor standard.

**S7 - Modern & Intuitive:**

``` r
library(S7)
Person <- new_class("Person",
  properties = list(
    name = class_character,
    age = class_numeric
  )
)
```

Combines S3's simplicity with S4's features.
Somewhat experimental (though ggplot2 uses it internally now, so maybe its nice and stable now?), very promising.

**Recommendation:**
Most packages should use S3.
Need strict validation?
Choose S4.
Want modern OOP?
Try S7.

See \[S7 documentation\][^12].

### Day 23: `cli` - Beautiful Command Line Interfaces 💬

Basic R messages are plain text with no structure.
cli makes package output professional, informative, and user-friendly.

**Semantic messages:**

``` r
cli::cli_alert_success("Package built successfully!")
cli::cli_alert_warning("Missing documentation for {.fn my_function}")
cli::cli_abort("Invalid input: {.val {invalid_value}}")
```

**Progress bars:**

``` r
cli::cli_progress_bar("Processing files", total = length(files))
for (file in files) {
  process_file(file)
  cli::cli_progress_update()
}
```

**Semantic markup:**

-   `{.fn function_name}` for functions  
-   `{.val value}` for values  
-   `{.file path}` for file paths

**Impact:**
cli transforms user experience.
Better error messages help users fix problems faster.
Progress indicators reduce support questions.

**Resources:** [cli.r-lib.org](https://cli.r-lib.org/)

### Day 24: `rlang` - Tidy Evaluation in Packages 🎪

Users love writing `filter(data, age > 30)` instead of `filter(data, "age > 30")`.
Making this safe in packages requires tidy evaluation.

**The embrace operator:**

``` r
my_mutate <- function(data, col, value) {
  data |>
    dplyr::mutate({{ col }} := value)
}
```

**Pass through multiple expressions:**

``` r
my_summarise <- function(data, ...) {
  data |>
    dplyr::summarise(...)
}
```

**When to use it:** Building dplyr-like interfaces, working with column names as bare names, accepting multiple expressions.
For simple functions, standard evaluation is fine.

See \[rlang documentation\][^13].

### Day 25: CRAN Submission Checklist 🎁

The final step: shipping your package to CRAN with confidence.

**Start with the release issue:**

``` r
usethis::use_release_issue()
```

Creates a GitHub issue with a complete pre-submission checklist.

**Essential checks:**

-   [ ] `devtools::check()` shows 0 errors, 0 warnings, 0 notes  
-   [ ] Tests pass on rhub + GitHub Actions (all platforms)  
-   [ ] NEWS.md updated with version and changes  
-   [ ] Version number bumped in DESCRIPTION  
-   [ ] `devtools::spell_check()` passed  
-   [ ] Reverse dependencies checked

**Document everything:**

``` r
usethis::use_cran_comments()
```

**Common rejection reasons:**
- Examples taking \>5 seconds  
- Typos in documentation  
- URL's not resolving  
- Missing input validation  
- Platform-specific bugs

**Submit:**

``` r
devtools::submit_cran()
```

**After acceptance:** Monitor CRAN check results, fix issues promptly, maintain your package responsibly.
You're now part of the R ecosystem!

## Conclusion

Over these 25 days, we've covered the complete modern R package development workflow:

-   **Week 1** focused on foundation and infrastructure---automated setup, development workflow, CI/CD, and documentation sites  
-   **Week 2** explored documentation and communication---from advanced roxygen2 to vignettes and changelogs  
-   **Week 3** dove into testing and quality---comprehensive testing strategies, code quality tools, and performance benchmarking  
-   **Week 4** tackled advanced features---multi-platform testing, object systems, user interfaces, and CRAN submission

The tools and techniques presented here represent tooling and workflows I personally use (or strive to use) in my own package development.
They will help you create packages that are:

-   **Robust:** Well-tested with comprehensive test suites
-   **Maintainable:** Clear documentation and consistent code style
-   **User-friendly:** Beautiful websites and helpful error messages  
-   **Professional:** Automated CI/CD and multi-platform testing

Whether you're developing your first package or maintaining dozens, these tools will streamline your workflow and improve package quality.

## Where to Go From Here

-   **Practice:** Apply these techniques to your own packages  
-   **Learn more:** Read "R Packages" by Hadley Wickham and Jenny Bryan"[^14]  
-   **Explore:** Browse r-lib packages for cutting-edge R tooling[^15]  
-   **Contribute:** Share your knowledge and help others in the R community  
-   **Follow:** Keep up with #rstats and #RPackageAdvent2025 for more tips

Thank you for following along with the R Package Development Advent Calendar 2025.  
Now go build amazing packages that make R better for everyone (after the holidays, of course!)! 🎄📦

## Resources

Happy package development! 🚀

[^1]: https://usethis.r-lib.org/

[^2]: https://devtools.r-lib.org/

[^3]: https://github.com/r-lib/actions

[^4]: https://pkgdown.r-lib.org/

[^5]: https://pre-commit.com/

[^6]: https://roxygen2.r-lib.org/

[^7]: https://pkgdown.r-lib.org/

[^8]: https://covr.r-lib.org/

[^9]: https://testthat.r-lib.org/

[^10]: https://docs.ropensci.org/vcr/

[^11]: https://r-hub.github.io/rhub/

[^12]: https://rconsortium.github.io/S7/

[^13]: https://rlang.r-lib.org/

[^14]: https://r-pkgs.org/

[^15]: https://github.com/r-lib
