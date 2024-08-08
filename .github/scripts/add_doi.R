library(httr2)
library(yaml)
library(rmarkdown)

find_end <- function(x){
  char <- grep("^$", x, invert = TRUE)
  char_lag <- c(char[2:length(char)], NA)
  start_index <- which(abs(char - char_lag) > 1)
  char[start_index[1]]
}

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


publish_to_zenodo <- function(post, pdf_dir = tempdir()){
  post_content <- readLines(post)
  
  # Extract YAML front matter
  yaml_delimiters <- grep("^---", post_content)
  yaml_content <- post_content[(yaml_delimiters[1] + 1):(yaml_delimiters[2] - 1)]
  metadata <- yaml::yaml.load(paste(yaml_content, collapse = "\n"))

  if(is.null(metadata$summmary)){
    post_summary <- post_content[(yaml_delimiters[2]+2):length(post_content)]
    metadata$summary <- post_summary[1:find_end(post_summary)]
  }

  # Create Zenodo deposition metadata
  zenodo_metadata <- list(
    metadata = list(
      title = metadata$title,
      description = sprintf("Dr. Mowinckel's blog: %s", 
        paste0(metadata$summary, collapse = " ")),
      creators = list(list(
        name = "Athanasia Monika Mowinckel",
        orcid = "0000-0002-5756-0223"
      )),
      upload_type = "publication",
      publication_type = "other",
      publication_date = metadata$date, 
      url = sprintf("https://drmowinckels.io/%s", metadata$slug),
      access_right = "open",
      license = "cc-by",
      keywords = metadata$tags,
      language = "eng"
    )
  )
  
  # Mint the DOI
  response <- request(zenodo_api_endpoint) |> 
    req_auth_bearer_token(zenodo_api_token) |> 
    req_body_json(zenodo_metadata, auto_unbox = TRUE) |> 
    req_perform()
    
  if (resp_status(response) %in% c(200, 201)) {
    deposition <- resp_body_json(response)
    pdf_file <- sprintf(
      "drmowinckels_%s_%s.pdf",
      metadata$date,
      metadata$slug
    )
    
    # generate pdf for archiving
    render(
      post, 
      output_format = pdf_document(latex_engine = "lualatex"), 
      output_file = pdf_file,
      output_dir = pdf_dir
    )

    # Upload the pdf file
    upload_response <- request(deposition$links$bucket) |> 
      req_url_path_append(sprintf(
        "drmowinckels_%s_%s.pdf",
        metadata$date,
        metadata$slug
      )) |> 
      req_auth_bearer_token(zenodo_api_token) |> 
      req_method("PUT") |> 
      req_body_file(file.path(pdf_dir, pdf_file)) |> 
      req_perform()
        
      if (resp_status(upload_response) %in% c(200, 201)) {
        message(sprintf("Successfully uploaded %s to Zenodo", post))

        # Publish the deposition (optional)
        publish_response <- request(zenodo_api_endpoint) |> 
          req_url_path_append(deposition$id, "actions", "publish") |> 
          req_auth_bearer_token(zenodo_api_token) |> 
          req_method("POST") |> 
          req_perform()
      
        if (resp_status(publish_response) %in% c(200, 201, 202)) {
          message(sprintf("Successfully published %s on Zenodo", pdf_file))
          pub_deposition <- resp_body_json(publish_response)
          
          # Update YAML front matter with DOI
          post_content <- c(
            post_content[1],
            sprintf("doi: %s", pub_deposition$metadata$doi),
            post_content[2:length(post_content)]
          )
          writeLines(post_content, post)
        } else {
          message(sprintf("Failed to publish %s on Zenodo: %s", pdf_file, resp_status(publish_response)))
        }
        
      } else {
        message(sprintf("Failed to upload %s to Zenodo: %s", post, resp_status(upload_response)))
      }
      
  } else {
      message(sprintf(
        "Failed to create DOI for %s: %s", post, resp_status(response)))
    }
  }

# Zenodo API settings
zenodo_api_endpoint <- "https://zenodo.org/api/deposit/depositions"
zenodo_api_token <- Sys.getenv("ZENODO_API_TOKEN")

# Read Hugo content files
content_dir <- "content/blog"
posts <- list.files(
  content_dir, 
  pattern = "^index\\.md$", 
  recursive = TRUE,
  full.names = TRUE
) 

# Only process files without doi and that are published
posts <- posts[sapply(posts, needs_doi)]

sapply(posts,
  publish_to_zenodo, 
  pdf_dir = tempdir()
)
