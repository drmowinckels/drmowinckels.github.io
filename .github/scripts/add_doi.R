library(httr2)

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
  date <- yaml::yaml.load(date)$date
  if(as.Date(date) > Sys.Date()){
    return(FALSE)
  }

  return(TRUE)
}

#' Get metadata from YAML frontmatter
#' 
#' Extracts YAML frontmatter using \code{link[rmarkdown]{yaml_front_matter}}, and if a summary is missing,
#' will use the first paragraph of the content as a summary.
#' 
#' @params path path to the markdown file with the post.
#' 
#' @return a list of meta-data as needed by Zenodo API
get_metadata <- function(path){
  message("- Fixing meta-data \n")

  # Extract YAML front matter
  metadata <- rmarkdown::yaml_front_matter(path)

  if(is.null(metadata$summmary)){
    post_content <- readLines(path)
    end_yaml <- grep("---", post_content)[2]+2
    post_summary <- post_content[end_yaml:length(post_content)]
    metadata$summary <- post_summary[1:find_end(post_summary)]
    metadata$summary <- sprintf(
      "Dr. Mowinckel's blog: %s", 
      paste0(metadata$summary, collapse = " ")
    )
  }

  # Create Zenodo deposition metadata
  list(
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
}

#' Generate PDF from markdown file
#' 
#' Generates a PDF using \code{link[quarto]{quarto_render},
#' and does this through LaTeX and pandoc.
#' Will generate a file name using the date and slug
#' of the post.
#' 
#' @params path to markdown file
#' @params date of the post
#' @params slug slug of the post
#' 
#' @return pdf file name
#' 
generate_pdf <- function(path, date, slug){
  message("- Generating PDF \n")

  pdf_file <- sprintf(
    "drmowinckels_%s_%s.pdf",
    date,
    slug
  )

  # Try rendering pdf, if errors returns FALSE so we can abort.
  render_status <- tryCatch({
    quarto::quarto_render(
      path, 
      output_format = "pdf", 
      output_file = pdf_file, 
      as_job = FALSE
    )
    TRUE
    }, 
    error = function(e) {FALSE}
  )

  if(!render_status)
    stop("Error during PDF conversion")
  pdf_file
}

#' Initiate a Zenodo deposition
#' 
#' Initiates a Zenodo deposition by supplying 
#' meta-data to the API. 
#' 
#' @params metadata a list of meta-data properties as needed by the Zenodo API
#' 
#' @return a list created by running \code{\link{[httr2](resp_body_json)}} on the httr2 request that made the deposition.
#' 
initiate_deposition <- function(metadata){
  message("- Initiating deposition \n")

  # Upload metadata to initiate DOI
  response <- request(zenodo_api_endpoint) |> 
    req_auth_bearer_token(zenodo_api_token) |> 
    req_body_json(metadata, auto_unbox = TRUE) |> 
    req_perform()
    
  if (!resp_status(response) %in% c(200, 201)) {
    stop(sprintf(
      "Failed to create DOI: %s", resp_status(response)),
      call. = FALSE
      )
  }

  resp_body_json(response)
}

#' Upload PDF
#' 
#' Upload the created PDF to the Zenodo deposition.
#' 
#' @params bucket the bucket url from the response that created the deposition.
#' @params pdf_file path to the pdf-file.
#' @params id id of the deposition
#' 
upload_pdf <- function(bucket, pdf_file, id){
  # Upload the pdf file
  message("- Uploading file \n")

  upload_response <- request(bucket) |> 
      req_url_path_append(pdf_file) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("PUT") |> 
      req_body_file(pdf_file) |> 
      req_error(is_error = function(e) FALSE) |>
      req_timeout(5*60) |>
      req_throttle(rate = 30 / 60) |>
      req_perform()
  
  browser()

  if (inherits(upload_response, "error")) {
    request(zenodo_api_endpoint) |> 
      req_url_path_append(id) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("DELETE") |> 
      req_perform()
browser()
    stop(sprintf("Failed to upload Zenodo: %s", 
      e),
      call. = FALSE
    )
  }
  browser()

  if (!resp_status(upload_response) %in% c(200, 201)) {
    request(zenodo_api_endpoint) |> 
      req_url_path_append(id) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("DELETE") |> 
      req_perform()

    stop(sprintf("Failed to upload to Zenodo: %s", 
      resp_status(upload_response)),
      call. = FALSE
    )
  }  
}

#' Publish Zenodo deposition
#' 
#' When a deposition has its pdf file,
#' it should be ready to publish. This is
#' a step that cannot be undone, a DOI is
#' persistent and you will not be able to 
#' delete the deposition after this step is done.
#' 
#' @params id Deposition id.
#' @return list made from the response
publish_deposition <- function(id){
  message("- Publishing deposition \n")

  # Publish the deposition
  pub_response <- request(zenodo_api_endpoint) |> 
    req_url_path_append(id, "actions", "publish") |> 
    req_auth_bearer_token(zenodo_api_token) |> 
    req_method("POST") |> 
    req_perform()
    
  if (!resp_status(pub_response) %in% c(200, 201, 202)) {
    stop(sprintf("Failed to publish %s on Zenodo: %s", pdf_file, resp_status(pub_response)),
    call. = FALSE)
  }
  message("- Successfully published \n")
  resp_body_json(pub_response)
}

#' Add DOI to post frontmatter
#' 
#' Adds the created DOI to the top of the posts front matter for future reference.
#' 
#' @params path to the markdown file
#' @params doi the doi of the deposition
#' 
update_post <- function(path, doi){
  post_content <- readLines(post)

  # Update YAML front matter with DOI
  post_content <- c(
    post_content[1],
    sprintf("doi: %s", doi),
    post_content[2:length(post_content)]
  )

  writeLines(post_content, path)
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
publish_to_zenodo <- function(post, upload = TRUE){
  message(sprintf(
    "Starting Zenodo process for %s \n ------ \n ",
    basename(dirname(post))
  ))
  zenodo_metadata <- get_metadata(post)
  pdf_file <- generate_pdf(
    post, 
    zenodo_metadata$metadata$publication_date, 
    basename(zenodo_metadata$metadata$url)
  )
  if(upload){
    deposition <- initiate_deposition(zenodo_metadata)
    pdf_upload <- upload_pdf(deposition$links$bucket, pdf_file, deposition$id)
    pub_deposition <- publish_deposition(deposition$id)
    update_post(post, pub_deposition$metadata$doi)
  }

  pdf_file
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
