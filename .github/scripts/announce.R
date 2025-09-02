#!/usr/bin/env Rscript

post <- commandArgs(trailingOnly = TRUE)

# Check if arguments are provided
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
source(here::here(".github/scripts/linkedin.R"))
source(here::here(".github/scripts/kit_newsletter.R"))
source(here::here(".github/scripts/gemini.R"))

frontmatter <- rmarkdown::yaml_front_matter(post)

# build URL
url <- sprintf(
  "https://drmowinckels.io/blog/%s/%s",
  basename(dirname(dirname(post))),
  frontmatter$slug
)
uri <- short_url(url)
frontmatter$url <- url

message <-
  gemini_upload_file(post) |>
  doc_summary(
    sprintf(
      "Please provide a text to announce the publication of the following article, highlighting its key points, practical approaches, and encouraging engagement. There should be three separate texts returned, one for each social media platform: LinkedIn (long, well structured with line breaks etc), Bluesky (short), and Mastodon (short). Each text should be tailored to the specific platform's audience and style, and should be in the first person, the author of the document is posting on their own accounts. The texts should be engaging and include relevant hashtags and emojis where appropriate, and raw link to the article at the end (%s). Output the information in a single line json, not pretty, without backslashes and information on file type (omit ```json), with keys linkedin, bluesky, and mastodon",
      uri
    )
  ) |>
  jsonlite::fromJSON()

image <- here::here(
  dirname(post),
  frontmatter$image
) |>
  optimize_image_size(
    max_size_mb = .976,
    quality = 80,
    scale_factor = 0.90
  )

# Post to Bluesky
bpst <- bskyr::bs_post(
  text = message$bluesky,
  images = image,
  images_alt = frontmatter$image_alt
)
bskurl <- paste0("https://bsky.app/profile/drmowinckels.io/post/", bpst$cid)
cli::cli_alert_info("Bluesky posted at {.url  {bskurl}}")


# Post to LinkedIn
lipst <- li_post_write(
  author = li_urn_me(),
  image_alt = frontmatter$image_alt,
  image = image,
  text = message$linkedin
)

# Post to Mastodon
toot <- rtoot::post_toot(
  status = message$mastodon,
  media = image,
  alt_text = frontmatter$image_alt,
  visibility = "public",
  language = "US-en"
)

# Send Newsletter
send_newsletter(frontmatter, url)
