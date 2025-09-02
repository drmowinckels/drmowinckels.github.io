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

  if (httr2::resp_status(upload_content_resp) != 200) {
    stop(paste(
      "File content upload failed with status:",
      httr2::resp_status(upload_content_resp),
      "-",
      httr2::resp_body_json(upload_content_resp)
    ))
  }
  file_info <- httr2::resp_body_json(upload_content_resp)
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

  if (httr2::resp_status(resp) != 200) {
    body <- ""
    if (httr2::resp_has_body(resp)) {
      body <- httr2::resp_body_json(resp)
    }
    cli::cli_abort(
      "Summary API Request failed with status: 
      {.val {httr2::resp_status(resp)}} - 
      {.val {httr2::resp_status_desc(resp)}} - 
      {.val {body}}"
    )
  }

  json <- httr2::resp_body_json(resp)
  json$candidate[[1]]$content$parts[[1]]$text
}
