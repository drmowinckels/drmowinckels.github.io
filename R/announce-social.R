#' Announce blog post on social media
#'
#' @param post Path to the blog post index.md file
#' @param platforms Which platforms to post to (default: all)
#' @param newsletter If TRUE, also send newsletter (default: FALSE)
#' @param dry_run If TRUE, generate text but don't post (default: FALSE)
#'
#' @examples
#' # Source this file first
#' source("announce-social.R")
#'
#' # Then run interactively
#' announce("content/blog/2026/02-02_sitrep/index.md")
#'
#' # Preview without posting
#' announce("content/blog/2026/02-02_sitrep/index.md", dry_run = TRUE)
#'
#' # Post to specific platforms only
#' announce("content/blog/2026/02-02_sitrep/index.md", platforms = c("bluesky", "mastodon"))
#'
#' # Also send newsletter
#' announce("content/blog/2026/02-02_sitrep/index.md", newsletter = TRUE)
announce <- function(
  post,
  platforms = c("bluesky", "mastodon", "linkedin"),
  newsletter = FALSE,
  dry_run = FALSE
) {
  source(here::here(".github/scripts/utils.R"))

  cli::cli_progress_step("Reading post metadata")
  frontmatter <- rmarkdown::yaml_front_matter(post)
  url <- sprintf(
    "https://drmowinckels.io/blog/%s/%s",
    basename(dirname(dirname(post))),
    frontmatter$slug %||% make_slug(post)
  )

  cli::cli_progress_step("Creating short URL")
  uri <- short_url(url)
  frontmatter$url <- url

  cli::cli_progress_step("Loading voice skills")
  post_content <- readLines(post, warn = FALSE) |>
    paste(collapse = "\n")

  drmo_voice <- readLines(
    file.path(Sys.getenv("HOME"), ".claude/skills/drmo-voice/SKILL.md"),
    warn = FALSE
  ) |>
    paste(collapse = "\n")

  social_voice <- readLines(
    file.path(
      Sys.getenv("HOME"),
      ".claude/skills/straight-talk/social-voice/SKILL.md"
    ),
    warn = FALSE
  ) |>
    paste(collapse = "\n")

  prompt <- sprintf(
    'You are writing social media posts for Dr. Mowinckel. Follow these voice guidelines:

<drmo-voice>
%s
</drmo-voice>

<social-voice>
%s
</social-voice>

Write announcements for the following blog post. Create four separate texts:
- LinkedIn: Long, well-structured with line breaks, professional but warm
- Bluesky: Less than 250 characters (graphemes), casual and engaging
- Mastodon: Short, community-focused
- Newsletter: 2-3 paragraphs for email subscribers. Highlight key insights, practical takeaways, or interesting points from the post. More personal and detailed than social media. Do NOT include the link (it will be added separately). Plain text only, no HTML or markdown.

Social media posts should:
- Be in first person (the author posting on their own accounts)
- Include relevant hashtags and emojis where appropriate
- End with the link: %s

Output ONLY a single line JSON object with keys "linkedin", "bluesky", "mastodon", and "newsletter". No markdown formatting, no code blocks, just the raw JSON.

<document>
%s
</document>',
    drmo_voice,
    social_voice,
    uri,
    post_content
  )

  cli::cli_progress_step("Generating posts with Claude")
  result <- processx::run(
    "claude",
    args = c("-p", prompt, "--output-format", "text"),
    error_on_status = TRUE
  )

  raw_output <- result$stdout |> trimws()

  # Extract JSON object from output (in case Claude adds extra text)
  json_match <- regmatches(raw_output, regexpr("\\{.*\\}", raw_output))
  if (length(json_match) == 0) {
    cli::cli_abort("Could not find JSON in Claude output: {raw_output}")
  }

  # Replace smart quotes with regular quotes
  json_clean <- json_match |>
    gsub(pattern = "[\u201C\u201D]", replacement = '"') |>
    gsub(pattern = "[\u2018\u2019]", replacement = "'")

  texts <- jsonlite::fromJSON(json_clean)
  cli::cli_progress_done()

  cli::cli_progress_step("Optimizing image")
  image <- here::here(dirname(post), frontmatter$image) |>
    optimize_image_size(
      max_size_mb = .976,
      quality = 80,
      scale_factor = 0.90
    )
  cli::cli_progress_done()

  if (dry_run) {
    cli::cli_alert_warning("Dry run - not posting")
    return(invisible(texts))
  }

  if ("bluesky" %in% platforms) {
    cli::cli_progress_step("Posting to Bluesky")
    bpst <- bskyr::bs_post(
      text = texts$bluesky,
      images = image,
      images_alt = frontmatter$image_alt
    )
    bskurl <- paste0("https://bsky.app/profile/drmowinckels.io/post/", bpst$cid)
    cli::cli_progress_done()
    cli::cli_alert_success("{.url {bskurl}}")
  }

  if ("mastodon" %in% platforms) {
    cli::cli_progress_step("Posting to Mastodon")
    toot <- rtoot::post_toot(
      status = texts$mastodon,
      media = image,
      alt_text = frontmatter$image_alt,
      visibility = "public",
      language = "US-en"
    )
    tooturl <- toot$uri %||%
      paste0("https://fosstodon.org/@drmowinckels/", toot$id)
    cli::cli_progress_done()
    cli::cli_alert_success("{.url {tooturl}}")
  }

  if ("linkedin" %in% platforms) {
    cli::cli_h2("LinkedIn (copy/paste to {.url https://linkedin.com/feed})")
    cli::cli_verbatim(texts$linkedin)
    if (clipr::clipr_available()) {
      clipr::write_clip(texts$linkedin)
      cli::cli_alert_success("LinkedIn text copied to clipboard")
    }
  }

  if (newsletter) {
    cli::cli_h2("Newsletter preview")
    cli::cli_verbatim(texts$newsletter)
    if (utils::askYesNo("Send newsletter?")) {
      cli::cli_progress_step("Sending newsletter")
      source(here::here(".github/scripts/kit_newsletter.R"))
      send_newsletter(frontmatter, url, body = texts$newsletter)
      cli::cli_progress_done()
    }
  }

  cli::cli_alert_info("Done!")
  invisible(texts)
}
