#!/usr/bin/env Rscript

post <- commandArgs(trailingOnly = TRUE)

if (length(post) == 0) {
  stop(
    "No arguments provided. Script needs a file to process.",
    call. = FALSE
  )
} else if (length(post) > 1) {
  warning(
    "Several arguments provided. Processing only first one.",
    call. = FALSE
  )
  post <- post[1]
}

source(here::here(".github/scripts/utils.R"))
source(here::here(".github/scripts/kit_newsletter.R"))

frontmatter <- rmarkdown::yaml_front_matter(post)

url <- sprintf(
  "https://drmowinckels.io/blog/%s/%s",
  basename(dirname(dirname(post))),
  frontmatter$slug %||% make_slug(post)
)
uri <- short_url(url)

send_newsletter(frontmatter, url)
cli::cli_alert_success("Newsletter sent for {.val {frontmatter$title}}")
