generate_content <- function(doc) {
  prompt_text <- paste(
    "Summarize the following blog post into a series of distinct points, each suitable for a LinkedIn carousel slide.",
    "For each point, provide:",
    "1. A concise, attention-grabbing title (max 10 words).",
    "2. A brief, engaging description (max 50 words) that elaborates on the title.",
    "Ensure there are at least 5 and no more than 8 points.",
    "Use code input and output in examples for engagement in extra slides after slides that mention code solutions.",
    "Use image paths from the post where appropriate to create more engaging slides",
    "Conclude with a final summary slide title and description encouraging engagement.",
    "Output the information in a single line json, not pretty",
    "{title:<input>,slides:[s1:{title, body, input, output}].",
    sep = "\n"
  )

  gemini.R::gemini_docs(
    doc,
    type = "Markdown",
    prompt = prompt_text
  )
}

resp2list <- function(x) {
  x <- strsplit(x, "json")
  x <- gsub("\\n|`", "", x[[1]][2])
  jsonlite::fromJSON(x)
}


generate_md_carousel <- function(
  content,
  output_file = "linkedin_carousel.qmd"
) {
  yaml_header <- c(
    "---",
    paste("title: ", gsub(":", " -", content$title)),
    "format:",
    "  revealjs:",
    "    theme: default",
    "    slide-number: false",
    "    controls: false",
    "    fragment: false",
    "    hash-for-ids: true",
    "    embed-resources: true",
    "    self-contained: true",
    "---",
    ""
  )

  markdown_lines <- c(yaml_header)

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
        "## Code Input",
        "",
        "```{r}",
        slide_data$input,
        "",
        "```",
        ""
      )
    }

    if (!is.na(slide_data$output) && slide_data$output != "") {
      markdown_lines <- c(
        markdown_lines,
        "## Code Output",
        "",
        "```",
        slide_data$output,
        "",
        "```",
        ""
      )
    }
  }

  writeLines(
    markdown_lines,
    output_file,
    useBytes = TRUE
  )
  message(paste("Quarto Markdown file generated:", output_file))
}


create_li_carousel <- function(path) {
  generated_content <- generate_content(path)

  cleaned_content <- resp2list(generated_content)

  generate_md_carousel(
    cleaned_content,
    output_file = here::here(
      dirname(path),
      "highlights.qmd"
    )
  )
}

create_li_carousel("content/blog/2025/07-01_httr2_client/index.md")
