library(httr2)

zenodo_base_url <- function() {
  Sys.getenv("ZENODO_BASE_URL", unset = "https://zenodo.org")
}

zenodo_deposit_endpoint <- function() {
  paste0(zenodo_base_url(), "/api/deposit/depositions")
}

zenodo_record_endpoint <- function() {
  paste0(zenodo_base_url(), "/api/records")
}

zenodo_token <- function() {
  token <- Sys.getenv("ZENODO_API_TOKEN")
  if (!nzchar(token)) {
    stop("ZENODO_API_TOKEN is not set.", call. = FALSE)
  }
  token
}

zenodo_dry_run <- function() {
  tolower(Sys.getenv("ZENODO_DRY_RUN", unset = "false")) %in%
    c("true", "1", "yes")
}

#' Build a Zenodo API error message
#'
#' Passed as the \code{body} argument to \code{\link[httr2]{req_error}} so a
#' failed request reports the Zenodo status, message and per-field errors
#' instead of a bare HTTP code.
#'
#' @param resp an httr2 response
#'
#' @return character vector of message lines
zenodo_error_body <- function(resp) {
  body <- tryCatch(resp_body_json(resp), error = function(e) NULL)
  if (is.null(body)) {
    return(sprintf("Zenodo said: %s", resp_status_desc(resp)))
  }
  field_errors <- vapply(
    body$errors,
    function(e) sprintf("- %s: %s", e$field, paste(e$message, collapse = "; ")),
    character(1)
  )
  c(
    sprintf(
      "Zenodo said: %s",
      paste(c(body$status, body$message), collapse = " - ")
    ),
    field_errors
  )
}

#' Start an authenticated request against the deposition API
#'
#' @param ... path segments appended to the deposition endpoint
#'
#' @return an httr2 request
zenodo_request <- function(...) {
  req <- request(zenodo_deposit_endpoint()) |>
    req_auth_bearer_token(zenodo_token()) |>
    req_error(body = zenodo_error_body) |>
    req_user_agent("drmowinckels.io Zenodo pipeline")

  segments <- c(...)
  if (length(segments) == 0) {
    return(req)
  }
  do.call(req_url_path_append, c(list(req), as.list(as.character(segments))))
}

#' Extract a Zenodo record id from a DOI
#'
#' @param doi character. A Zenodo DOI, such as "10.5281/zenodo.20489086".
#'
#' @return character record id
doi_record_id <- function(doi) {
  id <- sub("^.*zenodo\\.", "", trimws(as.character(doi)))
  if (length(id) != 1 || is.na(id) || !grepl("^[0-9]+$", id)) {
    stop(
      sprintf("Cannot read a Zenodo record id from doi '%s'", doi),
      call. = FALSE
    )
  }
  id
}

#' Look up the most recent version of a Zenodo record
#'
#' Zenodo only allows a new version to be created from the latest version of
#' a record. The DOI in a post's frontmatter points at the version that
#' existed when the post was first archived, so the latest one has to be
#' resolved before anything else can happen.
#'
#' @param record_id character. Any published record id in the version chain.
#'
#' @return list. The parsed record, including \code{id} and \code{metadata}.
latest_version <- function(record_id) {
  request(zenodo_record_endpoint()) |>
    req_url_path_append(record_id, "versions", "latest") |>
    req_error(body = zenodo_error_body) |>
    req_user_agent("drmowinckels.io Zenodo pipeline") |>
    req_perform() |>
    resp_body_json()
}

#' Run git and return its output
#'
#' @param ... arguments passed to git
#'
#' @return character vector of output lines, empty if git failed
git_run <- function(...) {
  args <- vapply(c(...), shQuote, character(1), USE.NAMES = FALSE)
  out <- suppressWarnings(
    system2("git", args, stdout = TRUE, stderr = FALSE)
  )
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    return(character(0))
  }
  as.character(out)
}

#' Last commit that touched a path
#'
#' @param path character. File or directory to look up.
#'
#' @return character commit sha, or NA if the path has no history
git_last_commit <- function(path) {
  sha <- git_run("log", "-1", "--format=%H", "--", path)
  if (length(sha) == 0) NA_character_ else sha[1]
}

#' Full message of a commit
#'
#' @param sha character. Commit to look up.
#'
#' @return character. The commit message, empty if the sha is unknown.
git_commit_message <- function(sha) {
  if (is.na(sha)) {
    return("")
  }
  paste(git_run("log", "-1", "--format=%B", sha), collapse = "\n")
}

#' Find the post a changed file belongs to
#'
#' Walks up from a changed file until it hits a directory holding an
#' index.md, so an edited image or figure resolves to the post that
#' contains it.
#'
#' @param path character. Path to a changed file.
#' @param root character. Content directory the search stops at.
#'
#' @return character path to index.md, or NA if the file is not in a post
find_post <- function(path, root = "content/blog") {
  dir <- dirname(path)
  while (startsWith(dir, root) && dir != root) {
    index <- file.path(dir, "index.md")
    if (file.exists(index)) {
      return(index)
    }
    dir <- dirname(dir)
  }
  NA_character_
}

#' Posts whose source changed between two commits
#'
#' Any file inside a post directory counts, so swapped images and edited
#' figures are treated as changes to the post the same way edited prose is.
#'
#' @param base character. Commit to compare from.
#' @param head character. Commit to compare to.
#' @param root character. Content directory to scan.
#'
#' @return character vector of paths to index.md files
changed_posts <- function(base, head = "HEAD", root = "content/blog") {
  files <- git_run("diff", "--name-only", base, head, "--", root)
  if (length(files) == 0) {
    return(character(0))
  }
  posts <- vapply(
    files,
    find_post,
    character(1),
    root = root,
    USE.NAMES = FALSE
  )
  sort(unique(posts[!is.na(posts)]))
}

#' Find line index where the first post paragraph ends
#'
#' Looks for the indices of empty lines surrounding paragraphs.
#' Specifically looking for the index that ends the first paragraph, used as
#' the post summary for Zenodo meta-data when the frontmatter has none.
#'
#' @param x character vector of content lines
#'
#' @return integer index
find_end <- function(x) {
  char <- grep("^$", x, invert = TRUE)
  if (length(char) == 0) {
    return(0L)
  }
  char_lag <- c(char[2:length(char)], NA)
  start_index <- which(abs(char - char_lag) > 1)
  if (length(start_index) == 0) {
    return(char[length(char)])
  }
  char[start_index[1]]
}

#' Check if a post is publicly published
#'
#' A post counts as published once its date has arrived and it is not
#' flagged as a draft.
#'
#' @param frontmatter list. Parsed YAML frontmatter.
#'
#' @return logical
is_published <- function(frontmatter) {
  if (isTRUE(frontmatter$draft)) {
    return(FALSE)
  }
  as.Date(frontmatter$date) <= Sys.Date()
}

#' Files in a post that carry frontmatter
#'
#' Posts are written as .qmd or .Rmd and rendered to the index.md Hugo
#' serves. The rendered file is listed first, since that is the one the site
#' is built from.
#'
#' @param post path to the post index.md
#'
#' @return character vector of existing paths
post_bundle <- function(post) {
  files <- list.files(
    dirname(post),
    pattern = "^index[.](md|qmd|Rmd|rmd)$",
    full.names = TRUE
  )
  rendered <- basename(files) == "index.md"
  c(files[rendered], sort(files[!rendered]))
}

#' Read the DOI recorded in a file's frontmatter
#'
#' @param path path to a file with YAML frontmatter
#'
#' @return character DOI, or NA if the file records none
frontmatter_doi <- function(path) {
  doi <- rmarkdown::yaml_front_matter(path)$doi
  if (is.null(doi)) NA_character_ else as.character(doi)[1]
}

#' Read the DOI a post is archived under
#'
#' @param post path to the post index.md
#'
#' @return character DOI, or NA if no file in the post records one
bundle_doi <- function(post) {
  files <- post_bundle(post)
  dois <- vapply(files, frontmatter_doi, character(1), USE.NAMES = FALSE)
  dois <- unique(dois[!is.na(dois)])

  if (length(dois) == 0) {
    return(NA_character_)
  }
  if (length(dois) > 1) {
    warning(
      sprintf(
        "%s records more than one DOI (%s), using %s",
        dirname(post),
        paste(dois, collapse = ", "),
        dois[1]
      ),
      call. = FALSE
    )
  }
  dois[1]
}

#' Write a DOI into a file's frontmatter
#'
#' @param path path to a file with YAML frontmatter
#' @param doi the doi to record
#'
#' @return logical, whether the file was changed
write_doi <- function(path, doi) {
  if (!is.na(frontmatter_doi(path))) {
    return(FALSE)
  }

  content <- readLines(path, warn = FALSE)
  if (length(content) == 0 || !grepl("^---\\s*$", content[1])) {
    warning(
      sprintf("%s has no frontmatter to record a DOI in", path),
      call. = FALSE
    )
    return(FALSE)
  }

  writeLines(append(content, sprintf("doi: %s", doi), after = 1), path)
  TRUE
}

#' Record a post's DOI in every file that makes it up
#'
#' Takes the DOI from whichever file already has one and writes it to the
#' rest. Without this the DOI lives only in the rendered markdown, so
#' re-rendering the source drops it and the post looks unarchived.
#'
#' @param post path to the post index.md
#'
#' @return the DOI, or NA if the post has none yet
sync_doi <- function(post) {
  doi <- bundle_doi(post)
  if (is.na(doi)) {
    return(invisible(doi))
  }

  files <- post_bundle(post)
  changed <- vapply(files, write_doi, logical(1), doi = doi)
  if (any(changed)) {
    message(sprintf(
      "- Recorded %s in %s \n",
      doi,
      paste(basename(files[changed]), collapse = ", ")
    ))
  }
  invisible(doi)
}

#' Check if a post needs a DOI
#'
#' The post date needs to be in the past or today, it cannot be listed as a
#' draft, and none of the files it is made of may already carry a DOI.
#'
#' @param x path to content .md
#'
#' @return logical
needs_doi <- function(x) {
  if (!is.na(bundle_doi(x))) {
    return(FALSE)
  }
  is_published(rmarkdown::yaml_front_matter(x))
}

#' Check if a changed post should be archived as a new version
#'
#' Only published posts that already have a DOI can get a new version.
#' Putting \code{[skip zenodo]} in the commit message that changed the post
#' keeps typo fixes and other trivial edits out of the archive.
#'
#' @param x path to content .md
#'
#' @return logical
needs_update <- function(x) {
  if (is.na(bundle_doi(x))) {
    return(FALSE)
  }
  if (!is_published(rmarkdown::yaml_front_matter(x))) {
    return(FALSE)
  }
  message <- git_commit_message(git_last_commit(dirname(x)))
  !grepl("[skip zenodo]", message, fixed = TRUE)
}

#' Get metadata from YAML frontmatter
#'
#' Extracts YAML frontmatter using \code{\link[rmarkdown]{yaml_front_matter}},
#' and if a summary is missing, will use the first paragraph of the content
#' as a summary.
#'
#' @param path path to the markdown file with the post.
#' @param version character. Optional version string recorded on the
#'   deposition, used to tell which commit the archived file was built from.
#'
#' @return a list of meta-data as needed by the Zenodo API
get_metadata <- function(path, version = NULL) {
  message("- Fixing meta-data \n")

  metadata <- rmarkdown::yaml_front_matter(path)

  if (is.null(metadata$summary)) {
    post_content <- readLines(path)
    end_yaml <- grep("---", post_content)[2] + 2
    post_summary <- post_content[end_yaml:length(post_content)]
    metadata$summary <- post_summary[1:find_end(post_summary)]
  }
  description <- sprintf(
    "Dr. Mowinckel's blog: %s",
    paste0(metadata$summary, collapse = " ")
  )

  list(
    metadata = list(
      title = metadata$title,
      description = description,
      creators = list(list(
        name = "Athanasia Monika Mowinckel",
        orcid = "0000-0002-5756-0223"
      )),
      upload_type = "publication",
      publication_type = "other",
      publication_date = metadata$date,
      version = version,
      url = sprintf(
        "https://drmowinckels.io/blog/%s/%s",
        substr(metadata$date, 1, 4),
        metadata$slug
      ),
      access_right = "open",
      license = "cc-by",
      keywords = as.list(metadata$tags),
      language = "eng"
    )
  )
}

#' Generate PDF from markdown file
#'
#' Generates a PDF using quarto, through LaTeX and pandoc. Will generate a
#' file name using the date and slug of the post.
#'
#' @param path to markdown file
#' @param date of the post
#' @param slug slug of the post
#'
#' @return pdf file name
generate_pdf <- function(path, date, slug) {
  message("- Generating PDF \n")

  pdf_file <- sprintf("drmowinckels_%s_%s.pdf", date, slug)

  status <- system2(
    "quarto",
    c("render", shQuote(path), "--to", "pdf", "--output", shQuote(pdf_file))
  )

  if (status != 0 || !file.exists(pdf_file)) {
    stop(sprintf("Error rendering %s to PDF", path), call. = FALSE)
  }
  normalizePath(pdf_file)
}

#' Delete a Zenodo draft deposition
#'
#' Deletes an unpublished draft deposition from Zenodo, used for cleanup
#' when subsequent steps fail.
#'
#' @param id Deposition id to delete
delete_deposition <- function(id) {
  message("- Cleaning up draft deposition \n")
  zenodo_request(id) |>
    req_method("DELETE") |>
    req_perform()
}

#' Initiate a Zenodo deposition
#'
#' Initiates a Zenodo deposition by supplying meta-data to the API.
#'
#' @param metadata a list of meta-data properties as needed by the Zenodo API
#'
#' @return the parsed deposition
initiate_deposition <- function(metadata) {
  message("- Initiating deposition \n")

  zenodo_request() |>
    req_body_json(metadata, auto_unbox = TRUE) |>
    req_perform() |>
    resp_body_json()
}

#' Fetch a deposition
#'
#' @param id Deposition id
#'
#' @return the parsed deposition
get_deposition <- function(id) {
  zenodo_request(id) |>
    req_perform() |>
    resp_body_json()
}

#' Create a draft for a new version of a published record
#'
#' Zenodo answers with the record the new version was based on, not with the
#' new draft, so the draft id is read off the returned link. Calling this
#' twice is safe: while a draft is unpublished, Zenodo returns that same
#' draft rather than making another one.
#'
#' @param record_id character. Id of the latest published version.
#'
#' @return character id of the new draft deposition
new_version_draft <- function(record_id) {
  message("- Creating new version \n")

  response <- zenodo_request(record_id, "actions", "newversion") |>
    req_method("POST") |>
    req_perform() |>
    resp_body_json()

  draft_url <- response$links$latest_draft
  if (is.null(draft_url)) {
    stop(
      sprintf("Zenodo returned no draft for record %s", record_id),
      call. = FALSE
    )
  }
  basename(draft_url)
}

#' Remove every file inherited by a draft deposition
#'
#' A new version starts out holding the previous version's files. They are
#' dropped so the published version contains only the freshly rendered PDF,
#' which matters when a post's date or slug changed the file name.
#'
#' @param id Deposition id of an unpublished draft
clear_deposition_files <- function(id) {
  files <- zenodo_request(id, "files") |>
    req_perform() |>
    resp_body_json()

  if (length(files) == 0) {
    return(invisible(NULL))
  }

  message(sprintf("- Removing %d inherited file(s) \n", length(files)))
  for (file in files) {
    # Zenodo intermittently refuses to drop an inherited file. The upload that
    # follows supersedes anything sharing its name, so a stale leftover is
    # worth a warning rather than losing the whole new version over it.
    tryCatch(
      zenodo_request(id, "files", file$id) |>
        req_method("DELETE") |>
        req_perform(),
      error = function(e) {
        warning(
          sprintf(
            "Could not remove inherited file %s: %s",
            file$filename,
            e$message
          ),
          call. = FALSE
        )
      }
    )
  }
  invisible(NULL)
}

#' Replace the metadata on a deposition
#'
#' @param id Deposition id
#' @param metadata a list of meta-data properties as needed by the Zenodo API
#'
#' @return the parsed deposition
update_deposition_metadata <- function(id, metadata) {
  message("- Updating meta-data \n")

  zenodo_request(id) |>
    req_method("PUT") |>
    req_body_json(metadata, auto_unbox = TRUE) |>
    req_perform() |>
    resp_body_json()
}

#' Upload PDF
#'
#' Upload the created PDF to the Zenodo deposition.
#'
#' @param bucket the bucket url from the deposition
#' @param pdf_file path to the pdf-file.
upload_pdf <- function(bucket, pdf_file) {
  message("- Uploading file \n")
  request(bucket) |>
    req_url_path_append(basename(pdf_file)) |>
    req_auth_bearer_token(zenodo_token()) |>
    req_method("PUT") |>
    req_body_file(pdf_file) |>
    req_error(body = zenodo_error_body) |>
    req_timeout(5 * 60) |>
    req_throttle(rate = 30 / 60) |>
    req_perform()
  invisible(NULL)
}

#' Publish Zenodo deposition
#'
#' When a deposition has its pdf file, it should be ready to publish. This is
#' a step that cannot be undone, a DOI is persistent and you will not be able
#' to delete the deposition after this step is done.
#'
#' @param id Deposition id.
#'
#' @return the parsed deposition
publish_deposition <- function(id) {
  message("- Publishing deposition \n")

  published <- zenodo_request(id, "actions", "publish") |>
    req_method("POST") |>
    req_perform() |>
    resp_body_json()

  message("- Successfully published \n")
  published
}

#' Add DOI to post frontmatter
#'
#' Adds the created DOI to the top of the front matter of every file the post
#' is made of, so re-rendering the source cannot drop it again.
#'
#' @param path to the markdown file
#' @param doi the doi of the deposition
update_post <- function(path, doi) {
  files <- post_bundle(path)
  changed <- vapply(files, write_doi, logical(1), doi = doi)

  message(sprintf(
    "- Updated %s with DOI: %s \n",
    paste(basename(files[changed]), collapse = ", "),
    doi
  ))
}

#' Publish blogpost to Zenodo
#'
#' Reads meta-data from yaml and creates a pdf for archiving to Zenodo.
#' If run with \code{upload = FALSE} will prepare meta-data and create the
#' pdf, without submitting to Zenodo.
#'
#' @param post character. path to the post .md
#' @param upload logical. If the information should be uploaded
#'
#' @return path to the generated pdf
publish_to_zenodo <- function(post, upload = TRUE) {
  message(sprintf(
    "Starting Zenodo process for %s \n ------ \n ",
    basename(dirname(post))
  ))

  zenodo_metadata <- get_metadata(
    post,
    version = git_last_commit(dirname(post))
  )
  pdf_file <- generate_pdf(
    post,
    zenodo_metadata$metadata$publication_date,
    basename(zenodo_metadata$metadata$url)
  )

  if (!upload) {
    message("- Dry run, nothing sent to Zenodo \n")
    return(pdf_file)
  }

  deposition <- initiate_deposition(zenodo_metadata)
  tryCatch(
    {
      upload_pdf(deposition$links$bucket, pdf_file)
      published <- publish_deposition(deposition$id)
      update_post(post, published$metadata$doi)
    },
    error = function(e) {
      delete_deposition(deposition$id)
      stop(e$message, call. = FALSE)
    }
  )

  pdf_file
}

#' Archive an edited blogpost as a new Zenodo version
#'
#' Creates a new version of the post's existing Zenodo record, so the archive
#' keeps up with the live post. The frontmatter DOI is left alone: Zenodo
#' groups every version under a concept DOI that always resolves to the
#' newest one.
#'
#' The commit that last touched the post is recorded as the deposition
#' version, which is what lets a re-run of the pipeline tell an already
#' archived edit from a new one.
#'
#' @param post character. path to the post .md
#' @param upload logical. If the information should be uploaded
#'
#' @return path to the generated pdf, or NULL if the post was already archived
update_on_zenodo <- function(post, upload = TRUE) {
  message(sprintf(
    "Starting Zenodo update for %s \n ------ \n ",
    basename(dirname(post))
  ))

  commit <- git_last_commit(dirname(post))
  record <- latest_version(doi_record_id(sync_doi(post)))

  if (identical(record$metadata$version, commit)) {
    message(sprintf(
      "- Version %s is already archived as %s, skipping \n",
      substr(commit, 1, 7),
      record$doi
    ))
    return(invisible(NULL))
  }

  zenodo_metadata <- get_metadata(post, version = commit)
  pdf_file <- generate_pdf(
    post,
    zenodo_metadata$metadata$publication_date,
    basename(zenodo_metadata$metadata$url)
  )

  if (!upload) {
    message(sprintf(
      "- Dry run, would create a new version of %s \n",
      record$doi
    ))
    return(pdf_file)
  }

  draft_id <- new_version_draft(record$id)
  tryCatch(
    {
      clear_deposition_files(draft_id)
      draft <- update_deposition_metadata(draft_id, zenodo_metadata)
      bucket <- draft$links$bucket
      if (is.null(bucket)) {
        bucket <- get_deposition(draft_id)$links$bucket
      }
      upload_pdf(bucket, pdf_file)
      published <- publish_deposition(draft_id)
      message(sprintf("- New version DOI: %s \n", published$metadata$doi))
    },
    error = function(e) {
      delete_deposition(draft_id)
      stop(e$message, call. = FALSE)
    }
  )

  pdf_file
}
