generate_md_carousel <- function(
  content,
  post,
  output_file = "highlights.qmd"
) {
  frontmatter <- rmarkdown::yaml_front_matter(post)

  # build URL
  url <- sprintf(
    "https://drmowinckels.io/blog/%s/%s",
    basename(dirname(dirname(post))),
    frontmatter$slug
  )

  markdown_lines <- c(
    "---",
    paste("title: ", gsub(":", " -", content$title)),
    "format:",
    "  revealjs:",
    "    theme: [assets/quarto-igloo.scss, default]",
    "    logo: assets/img/logo.png",
    ,
    sprintf("    footer: '%s'", url),
    "    slide-number: false",
    "    controls: false",
    "    fragment: false",
    "    hash-for-ids: true",
    "    embed-resources: true",
    "    self-contained: true",
    "    title-slide-attributes:",

    sprintf(
      "        data-background-image: %s",
      file.path(url, frontmatter$image)
    ),
    "        data-background-size: cover",
    "        data-background-opacity: '0.3'",
    "---",
    ""
  )

  for (i in 1:nrow(content$slides)) {
    slide_data <- content$slides[i, ]

    if (!is.na(slide_data$title) && slide_data$title != "") {
      markdown_lines <- c(
        markdown_lines,
        paste0("# ", slide_data$title),
        ""
      )
    }

    if (!is.na(slide_data$body) && slide_data$body != "") {
      markdown_lines <- c(
        markdown_lines,
        slide_data$body,
        ""
      )
    }

    if (!is.na(slide_data$input) && slide_data$input != "") {
      markdown_lines <- c(
        markdown_lines,
        "",
        slide_data$input,
        ""
      )
    }

    if (!is.na(slide_data$output) && slide_data$output != "") {
      markdown_lines <- c(
        markdown_lines,
        "",
        slide_data$output,
        ""
      )
    }
  }

  writeLines(
    markdown_lines,
    output_file,
    useBytes = TRUE
  )
  cli::cli_text("Quarto Markdown file generated: {.path {output_file}}")
  invisible(markdown_lines)
}


create_li_carousel <- function(path) {
  prompt_text <- paste(
    "Summarize the following blog post into a series of distinct points, each suitable for a LinkedIn carousel slide.",
    "For each point, provide:",
    "1. A concise, attention-grabbing title (max 10 words).",
    "2. A brief, engaging description (max 50 words) that elaborates on the title.",
    "Ensure there are at least 5 and no more than 8 points.",
    "Use code input and output in examples for engagement in extra slides after slides that mention code solutions.",
    "Use image paths from the post where appropriate to create more engaging slides",
    "Conclude with a final summary slide title and description encouraging engagement.",
    "Output the information in a single line json, not pretty, without backslashes and information on file type (omit ```json).",
    "{title:<input>,slides:[s1:{title, body, input, output}].",
    sep = "\n"
  )

  gemini_upload_file(path) |>
    doc_summary(prompt_text) |>
    jsonlite::fromJSON() |>
    generate_md_carousel(
      output_file = here::here(
        dirname(path),
        "highlights.qmd"
      )
    )
}

path <- here::here("content/blog/2025/09-01_submodules/index.md")

qmd <- create_li_carousel(path)
