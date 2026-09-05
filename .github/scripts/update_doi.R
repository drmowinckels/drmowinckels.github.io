script_dir <- function() {
  file <- sub(
    "^--file=",
    "",
    grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  )
  if (length(file) == 0) "." else dirname(normalizePath(file[1]))
}

source(file.path(script_dir(), "zenodo.R"))

diff_base <- Sys.getenv("ZENODO_DIFF_BASE")
diff_head <- Sys.getenv("ZENODO_DIFF_HEAD", unset = "HEAD")

if (!nzchar(diff_base)) {
  stop(
    "ZENODO_DIFF_BASE is not set, cannot tell which posts changed.",
    call. = FALSE
  )
}

posts <- changed_posts(diff_base, diff_head)

if (length(posts) > 0) {
  invisible(lapply(posts, sync_doi))
  posts <- posts[vapply(posts, needs_update, logical(1))]
}

if (length(posts) == 0) {
  message(sprintf(
    "No published posts with a DOI changed between %s and %s.",
    substr(diff_base, 1, 7),
    substr(diff_head, 1, 7)
  ))
} else {
  invisible(lapply(posts, update_on_zenodo, upload = !zenodo_dry_run()))
}
