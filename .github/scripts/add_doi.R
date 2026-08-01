script_dir <- function() {
  file <- sub(
    "^--file=",
    "",
    grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  )
  if (length(file) == 0) "." else dirname(normalizePath(file[1]))
}

source(file.path(script_dir(), "zenodo.R"))

posts <- list.files(
  "content/blog",
  pattern = "^index\\.md$",
  recursive = TRUE,
  full.names = TRUE
)

invisible(lapply(posts, sync_doi))

posts <- posts[vapply(posts, needs_doi, logical(1))]

if (length(posts) == 0) {
  message("No posts need a DOI.")
} else {
  invisible(lapply(posts, publish_to_zenodo, upload = !zenodo_dry_run()))
}
