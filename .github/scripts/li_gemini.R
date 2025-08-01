library(httr2)

gemini_url <- function(
  version = "v1beta",
  model = "gemini-1.5-flash",
  upload = FALSE
) {
  baseurl <- "https://generativelanguage.googleapis.com"

  if (upload) {
    return(file.path(
      baseurl,
      "upload",
      version,
      "files"
    ))
  }

  sprintf(
    "%s/%s/models/%s:generateContent",
    baseurl,
    version,
    model
  )
}

gemini_upload_file <- function(path) {
  api_key <- Sys.getenv("GEMINI_API_KEY")

  if (!nzchar(api_key)) {
    cli::cli_abort(
      "{.val GEMINI_API_KEY} environment variable not set. Please set it before running."
    )
  }

  # To get information about the file
  file_raw_content <- readBin(
    path,
    "raw",
    n = file.info(path)$size
  )

  # Get upload URL -- step 1
  upload_resp_start <- gemini_url(upload = TRUE) |>
    httr2::request() |>
    httr2::req_headers(
      "x-goog-api-key" = api_key,
      "X-Goog-Upload-Protocol" = "resumable",
      "X-Goog-Upload-Command" = "start",
      "X-Goog-Upload-Header-Content-Length" = length(file_raw_content),
      "X-Goog-Upload-Header-Content-Type" = "text/markdown"
    ) |>
    httr2::req_body_json(list(
      file = list(
        display_name = basename(dirname(path)),
        mime_type = "text/markdown"
      )
    )) |>
    httr2::req_perform()

  upload_url <- httr2::resp_header(upload_resp_start, "X-Goog-Upload-Url")

  if (is.null(upload_url)) {
    cli::cli_abort("Failed to get upload URL from Files API start request.")
  }

  # Upload file content -- step 2
  upload_content_resp <- httr2::request(upload_url) |>
    httr2::req_headers(
      "Content-Type" = "text/markdown",
      "X-Goog-Upload-Command" = "upload, finalize",
      "X-Goog-Upload-Offset" = "0",
      "x-goog-api-key" = api_key
    ) |>
    httr2::req_body_raw(file_raw_content) |>
    httr2::req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2::req_perform()

  if (resp_status(upload_content_resp) != 200) {
    stop(paste(
      "File content upload failed with status:",
      resp_status(upload_content_resp),
      "-",
      resp_body_json(upload_content_resp)
    ))
  }
  file_info <- resp_body_json(upload_content_resp)
  cli::cli_alert_info(
    "File uploaded successfully! File Name: {.path {file_info$file$name}}"
  )
  return(file_info$file)
}


doc_summary <- function(
  file_info,
  prompt = "Please summarize the attached  document concisely, focusing on its overview, key accomplishments, challenges, and next steps."
) {
  api_key <- Sys.getenv("GEMINI_API_KEY")

  if (!nzchar(api_key)) {
    cli::cli_abort(
      "{.val GEMINI_API_KEY} environment variable not set. Please set it before running."
    )
  }

  body <- list(
    contents = list(list(
      parts = list(
        list(text = prompt),
        list(
          file_data = list(
            mime_type = file_info$mimeType,
            file_uri = file_info$uri
          )
        )
      )
    ))
  )

  resp <- gemini_url(upload = FALSE) |>
    httr2::request() |>
    httr2::req_headers(
      "x-goog-api-key" = api_key,
      "Content-Type" = "application/json"
    ) |>
    httr2::req_body_json(
      body,
      auto_unbox = TRUE
    ) |>
    httr2::req_throttle(rate = 50 / 60) |>
    httr2::req_error(
      is_error = function(resp) FALSE
    ) |>
    httr2::req_perform()

  if (resp_status(resp) != 200) {
    body <- ""
    if (httr2::resp_has_body(resp)) {
      body <- httr2::resp_body_json(resp)
    }
    cli::cli_abort(
      "Summary API Request failed with status: 
      {.val {resp_status(resp)}} - 
      {.val {resp_status_desc(resp)}} - 
      {.val {body}}"
    )
  }

  json <- httr2::resp_body_json(resp)
  json$candidate[[1]]$content$parts[[1]]$text
}


generate_md_carousel <- function(
  content,
  output_file = "highlights.qmd"
) {
  markdown_lines <- c(
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

qmd <- here::here("content/blog/2025/08-01_linkedin_gemini/index.md") |>
  create_li_carousel()
