script_dir <- function() {
  file <- sub(
    "^--file=",
    "",
    grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  )
  if (length(file) == 0) "." else dirname(normalizePath(file[1]))
}

tests <- script_dir()
source(file.path(tests, "..", "zenodo.R"))

library(testthat)
test_dir(tests, stop_on_failure = TRUE)
