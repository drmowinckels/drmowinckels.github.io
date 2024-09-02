library(httr2)
library(yaml)
library(quarto)

#' Find line index where first post paragraph ends
#' 
#' Looks for the indeces of empty lines surrounding 
#' paragraphs. Specifically looking for the index that
#' ends the first paragraph, using this as the post
#' summary for Zenodo meta-data.
#' 
#' @param x path to content .md
find_end <- function(x){
  char <- grep("^$", x, invert = TRUE)
  char_lag <- c(char[2:length(char)], NA)
  start_index <- which(abs(char - char_lag) > 1)
  char[start_index[1]]
}

#' Check if post needs DOI
#' 
#' Will check if the post frontmatter
#' indicates the post needs DOI.
#' The post date needs to be in the past or 
#' today, it cannot be listed as a draft, and
#' it should not already have a DOI.
#' 
#' @param x path to content .md
#' 
needs_doi <- function(x){
  frontmatter <- readLines(x, 30)

  # Don't process if draft
  draft <- frontmatter[grep("^draft:", frontmatter)]
  if(length(draft) != 0){
    if(grepl("true", draft))
      return(FALSE) 
  }

  # Don't process if already has DOI
  if(any(grep("^doi:", frontmatter))){
    return(FALSE)
  }
  
  # Don't process if date is in future
  date <- frontmatter[grep("^date:", frontmatter)]
  date <- yaml.load(date)$date
  if(as.Date(date) > Sys.Date()){
    return(FALSE)
  }

  return(TRUE)
}

#' Publish blogpost to Zenodo
#' 
#' Function will read in meta-data from yaml,
#' and create pdf for archiving to Zenodo.
#' If run with \code{uplad = FALSE} will prepare
#' meta-data and create the pdf, without submitting
#' to Zenodo.
#' 
#' @param post character. path to the post .md
#' @param upload logical. If the information should be uploaded
#' 
publish_to_zenodo <- function(post, upload = FALSE){
  cli::cli_h1(sprintf(
    "Starting Zenodo process for %s",
    basename(dirname(post))
  ))

  post_content <- readLines(post)

  # Extract YAML front matter
  metadata <- rmarkdown::yaml_front_matter(post)

  if(is.null(metadata$summmary)){
    end_yaml <- grep("---", post_content)[2]+2
    post_summary <- post_content[end_yaml:length(post_content)]
    metadata$summary <- post_summary[1:find_end(post_summary)]
    metadata$summary <- sprintf(
      "Dr. Mowinckel's blog: %s", 
      paste0(metadata$summary, collapse = " ")
    )
  }

  cli::cli_bullets(list("*" = "Fixing meta-data"))
  # Create Zenodo deposition metadata
  zenodo_metadata <- list(
    metadata = list(
      title = metadata$title,
      description = metadata$summary,
      creators = list(list(
        name = "Athanasia Monika Mowinckel",
        orcid = "0000-0002-5756-0223"
      )),
      upload_type = "publication",
      publication_type = "other",
      publication_date = metadata$date, 
      url = sprintf("https://drmowinckels.io/blog/%s/%s", substr(metadata$date, 1, 4), metadata$slug),
      access_right = "open",
      license = "cc-by",
      keywords = metadata$tags,
      language = "eng"
    )
  )

  cli::cli_bullets(list("*" = "Generating PDF"))
  pdf_file <- sprintf(
    "drmowinckels_%s_%s.pdf",
    metadata$date,
    metadata$slug
  )

  # Try rendering pdf, if errors returns FALSE so we can abort.
  render_status <- tryCatch({
    quarto_render(
      post, 
      output_format = "pdf", 
      output_file = pdf_file, 
      as_job = FALSE
    )
    TRUE
  }, 
  error = function(e) {FALSE}
  )

  if(!render_status)
    stop(
      sprintf("Error during PDF conversion: %s\n", e$message),
      call. = FALSE
    )
  
  if(upload){
    cli::cli_bullets(list("*" = "Initiating deposition"))
    # Upload metadata to initiate DOI
    response <- request(zenodo_api_endpoint) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_body_json(zenodo_metadata, auto_unbox = TRUE) |> 
      req_perform()
      
    if (!resp_status(response) %in% c(200, 201)) {
      stop(sprintf(
        "Failed to create DOI for %s: %s", post, resp_status(response)),
        call. = FALSE
        )
    }

    deposition <- resp_body_json(response)

    # Upload the pdf file
    cli::cli_bullets(list("*" = "Uploading file"))
    upload_response <- request(deposition$links$bucket) |> 
      req_url_path_append(pdf_file) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("PUT") |> 
      req_body_file(pdf_file) |> 
      req_perform()
          
    if (!resp_status(upload_response) %in% c(200, 201)) {
      stop(sprintf("Failed to upload %s to Zenodo: %s", post, resp_status(upload_response)),
      call. = FALSE
      )
    }

    cli::cli_bullets(list("*" = "Publishing deposition"))

    # Publish the deposition
    pub_response <- request(zenodo_api_endpoint) |> 
      req_url_path_append(deposition$id, "actions", "publish") |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("POST") |> 
      req_perform()
      
    if (!resp_status(pub_response) %in% c(200, 201, 202)) {
      stop(sprintf("Failed to publish %s on Zenodo: %s", pdf_file, resp_status(pub_response)),
      call. = FALSE)
    }

    cli::cli_alert_success("Successfully publishe")

    pub_deposition <- resp_body_json(pub_response)

    # Update YAML front matter with DOI
    post_content <- c(
      post_content[1],
      sprintf("doi: %s", pub_deposition$metadata$doi),
      post_content[2:length(post_content)]
    )
  
    writeLines(post_content, post)
  }

  return(pdf_file)
}

# Zenodo API settings
zenodo_api_endpoint <- "https://zenodo.org/api/deposit/depositions"
zenodo_api_token <- Sys.getenv("ZENODO_API_TOKEN")

# Read Hugo content files
posts <- list.files(
  "content/blog", 
  pattern = "^index\\.md$", 
  recursive = TRUE,
  full.names = TRUE
) 

# Only process files without doi and that are published
posts <- posts[sapply(posts, needs_doi)]

if( length(posts) > 0){
  # Run thorugh all posts that need a doi.
  sapply(posts,
    publish_to_zenodo, 
    upload = TRUE
  )
}
