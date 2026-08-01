git_quiet <- function(...) {
  system2(
    "git",
    vapply(c(...), shQuote, character(1), USE.NAMES = FALSE),
    stdout = FALSE,
    stderr = FALSE
  )
}

local_blog_repo <- function(env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  withr::local_dir(dir, .local_envir = env)
  git_quiet("init", "-q", "-b", "main")
  git_quiet("config", "user.email", "test@example.com")
  git_quiet("config", "user.name", "Test User")
  git_quiet("config", "commit.gpgsign", "false")
  dir
}

git_commit_all <- function(message) {
  git_quiet("add", "-A")
  git_quiet("commit", "-q", "-m", message)
  git_run("rev-parse", "HEAD")[1]
}

write_post <- function(
  dir,
  frontmatter,
  body = c("First paragraph.", "", "Second paragraph.")
) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, "index.md")
  writeLines(c("---", frontmatter, "---", "", body), path)
  path
}

write_source <- function(dir, extension, frontmatter, body = "Source body.") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, paste0("index.", extension))
  writeLines(c("---", frontmatter, "---", "", body), path)
  path
}

published_frontmatter <- function(...) {
  defaults <- c(
    "title: A Post",
    "date: '2020-01-01'",
    "slug: a-post",
    "tags:",
    "  - r",
    "  - hugo"
  )
  c(defaults, ...)
}
