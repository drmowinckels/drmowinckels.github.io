#' Draft social media and newsletter texts into a post's frontmatter
#'
#' Asks Claude to draft Bluesky, Mastodon, LinkedIn and newsletter texts in
#' Dr. Mowinckel's voice and writes them to a `social:` block in the post's
#' frontmatter. Review and edit them in the PR; once the post is merged and
#' live, `.github/workflows/announce.yml` posts the social texts via Buffer and
#' sends the newsletter text as a Kit broadcast.
#' The post URL is appended automatically, so the texts should not include it.
#'
#' @param post Path to the blog post index.md file
#' @param overwrite If TRUE, replace an existing `social:` block
#'
#' @examples
#' source("R/announce-social.R")
#' draft_social("content/blog/2026/02-02_sitrep/index.md")
draft_social <- function(post, overwrite = FALSE) {
  frontmatter <- rmarkdown::yaml_front_matter(post)
  if (!is.null(frontmatter$social) && !overwrite) {
    cli::cli_abort(
      "{.path {post}} already has a {.field social} block. Use {.code overwrite = TRUE} to replace it."
    )
  }

  prompt <- sprintf(
    'You are writing social media posts for Dr. Mowinckel. Follow these voice guidelines: in drmo-voice, and social-voice.

Write announcements for the following blog post. Create four separate texts:
- linkedin: Long, well-structured with line breaks, professional but warm
- bluesky: At most 240 characters (graphemes), casual and engaging
- mastodon: Short, community-focused, at most 400 characters
- newsletter: 2-3 paragraphs for email subscribers separated by blank lines. Highlight key insights, practical takeaways, or interesting points from the post. More personal and detailed than social media. Plain text only, no HTML or markdown.

All texts should:
- Be in first person (the author posting on their own accounts)
- NOT include a link to the post (it is appended automatically)
Social media texts should include relevant hashtags and emojis where appropriate.

Output ONLY a single line JSON object with keys "linkedin", "bluesky", "mastodon", and "newsletter". No markdown formatting, no code blocks, just the raw JSON.

<document>
%s
</document>',
    paste(readLines(post, warn = FALSE), collapse = "\n")
  )

  cli::cli_progress_step("Drafting texts with Claude")
  result <- processx::run(
    "claude",
    args = c("-p", prompt, "--output-format", "text"),
    error_on_status = TRUE
  )
  json <- regmatches(result$stdout, regexpr("\\{.*\\}", result$stdout))
  if (length(json) == 0) {
    cli::cli_abort("Could not find JSON in Claude output: {result$stdout}")
  }
  texts <- jsonlite::fromJSON(json)[c(
    "bluesky",
    "mastodon",
    "linkedin",
    "newsletter"
  )]
  cli::cli_progress_done()

  write_social(post, texts)

  if (nchar(texts$bluesky, type = "chars") > 250) {
    cli::cli_warn(
      "Bluesky text is {nchar(texts$bluesky)} characters; with the link it may exceed Bluesky's 300 limit."
    )
  }
  cli::cli_alert_success(
    "Wrote {.field social} to {.path {post}}. Review before merging."
  )
  invisible(texts)
}

write_social <- function(post, texts) {
  texts <- lapply(texts, function(x) enc2utf8(trimws(x)))
  lines <- readLines(post, warn = FALSE, encoding = "UTF-8")
  fences <- which(lines == "---")
  stopifnot(length(fences) >= 2, fences[1] == 1)
  header <- lines[2:(fences[2] - 1)]

  social_start <- grep("^social:", header)
  if (length(social_start) > 0) {
    nested <- grepl("^(\\s|$)", header[-(1:social_start)])
    social_end <- social_start +
      (if (all(nested)) length(nested) else which(!nested)[1] - 1)
    header <- header[-(social_start:social_end)]
  }

  block <- c(
    "social:",
    unlist(lapply(names(texts), function(key) {
      body <- strsplit(texts[[key]], "\n", fixed = TRUE)[[1]]
      c(
        paste0("  ", key, ": |-"),
        ifelse(nzchar(body), paste0("    ", body), "")
      )
    }))
  )

  out <- enc2utf8(c("---", header, block, lines[fences[2]:length(lines)]))
  writeLines(out, post, useBytes = TRUE)

  written <- rmarkdown::yaml_front_matter(post)$social
  stopifnot(identical(
    enc2utf8(unlist(written[names(texts)])),
    unlist(texts)
  ))
}
