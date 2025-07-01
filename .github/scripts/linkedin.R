# Shamelessly stolen and adapted from rOpenSci
# https://github.com/ropensci-org/promoutils/blob/main/R/linkedin.R

# And Jon Harmon's code for TinyTuesday sharing
# https://github.com/rfordatascience/ttpost/blob/main/runner-li.R

# To refresh the refresh the token, visit
# https://www.linkedin.com/developers/tools/oauth/token-generator

# LinkedIn Chars to escape
escape_linkedin_chars <- function(x) {
  chars <- c(
    "\\|",
    "\\{",
    "\\}",
    "\\@",
    "\\[",
    "\\]",
    "\\(",
    "\\)",
    "\\<",
    "\\>",
    "\\#",
    "\\\\",
    "\\*",
    "\\_",
    "\\~"
  )
  p <- stats::setNames(paste0("\\", chars), chars)
  stringr::str_replace_all(x, p)
}

# Automatically set the LinkedIn API endpoint_version to 2 months ago since they
# constantly change that without changing core features.
li_get_version <- function() {
  li_version_date <- lubridate::rollback(lubridate::today())

  paste0(
    lubridate::year(li_version_date),
    stringr::str_pad(lubridate::month(li_version_date), 2, pad = "0")
  )
}

#' Setup client id for LinkedIn API
#'
#' Expects to find the "Client Secret" in the .Renviron file under
#' LI_CLIENT_SECRET (Or as a general environemental variable through GitHub
#' actions).
#'
#' @noRd
li_client <- function() {
  httr2::oauth_client(
    name = "drmowinckels_linkedIn",
    id = Sys.getenv("LI_CLIENT_ID"),
    token_url = "https://www.linkedin.com/oauth/v2/accessToken",
    secret = Sys.getenv("LI_CLIENT_SECRET")
  )
}


#' Authorize rOpenSci client with LinkedIn
#'
#' This authorizes the rOpenSci client with **your** credentials (and you must
#' be part of the rOpenSci organization as an admin).
#' Make sure to take note of the 'refresh_token' as that is what you'll
#' add to your .Renviron file for local work, or the GitHub secrets for
#' the comms/scheduled_socials workflow.
#'
#' This function authorizes with a redirect url of "http://localhost:1444/",
#' this *must* be the same as that listed in the LinkedIn Developer App,
#' https://www.linkedin.com/developers/apps.
#'
#' **If you retrieve a new token, you will have to put it in the .Renviron
#' and the re-start your R session to continue**
#'
#' This function authorizes with the scopes:
#'
#' - w_member_social (default)
#' - w_organization_social (special request)
#' - r_organization_social (special request)
#' - r_organization_admin (special request)
#'
#' @return httr2 authorization
#' @export
#'
#' @references
#'   - Refresh tokens API: https://learn.microsoft.com/en-us/linkedin/shared/authentication/programmatic-refresh-tokens
#'
#' @examples
#'
#' \dontrun{
#' # Only run if you need to update the scopes or get a new token (otherwise
#' # you'll have to replace all your tokens)
#' t <- li_oauth()
#' t$refresh_token
#' }
li_oauth <- function() {
  auth_url <- "https://www.linkedin.com/oauth/v2/authorization"

  auth_url <- httr2::oauth_flow_auth_code_url(
    client = li_client(),
    auth_url = auth_url,
    state = "DEKELTMVCATS34562THEBEST"
  )

  httr2::oauth_flow_auth_code(
    client = li_client(),
    auth_url = auth_url,
    redirect_uri = "http://localhost:1444/",
    scope = paste("email", "openid", "profile", "w_member_social"),
    pkce = FALSE
  )
}


#' Create authorization for LinkedIn
#'
#' This uses the bearer token auth, which would
#' not work for organisation posting.
#'
#' @param req httr2 request
#' @param token Access token
#'
#' @noRd
li_req_auth <- function(req, token = Sys.getenv("LI_TOKEN")) {
  req |>
    httr2::req_auth_bearer_token(token)
}


#' Create setup for connecting to LinkedIn API
#'
#' Sets up API url, version endpoint, and necessary
#' headers for making resuests from the API.
#' Does not perform any actual calls to the API.
#'
#' @param endpoint_version character. Sets the endpoint version,
#'    should likely be either "v2" or "rest"
#' @param ... arguments passed along to \code{li_req_auth()}
#'
#' @export
#'
li_req <- function(endpoint_version = "rest", ...) {
  httr2::request("https://api.linkedin.com") |>
    httr2::req_url_path_append(endpoint_version) |>
    httr2::req_headers(
      "LinkedIn-Version" = li_get_version(),
      "X-Restli-Protocol-Version" = "2.0.0",
      "Content-Type" = "application/json"
    ) |>
    li_req_auth(...)
}

#' Fetch your personal URN number
#'
#' This is required to post on LinkedIn to your personal account
#'
#' @return A string with your URN in the format of "urn:li:person:XXXX"
#' @export
#'
#' @examples
#'
#' \dontrun{
#' li_urn_me()
#' }
li_urn_me <- function() {
  id <- li_req("v2") |>
    httr2::req_url_path_append("userinfo") |>
    httr2::req_auth_bearer_token(Sys.getenv("LI_TOKEN")) |>
    httr2::req_url_query(projection = "(sub)") |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    unlist()
  paste0("urn:li:person:", id)
}

#' Post to LinkedIn
#'
#' @param author Character. URN. Either yours (see `li_urn_me()`
#'    or an organisation's).
#' @param body Character. The body of the post as you would like
#'    it to appear.
#' @param image Character. Path to the image you want to use
#' @param image_alt Character. String describing the image.
#'
#' @return A string of the URN for the post id.
#' @export
#'
#' @examples
#'
#' \dontrun{
#' # Real post
#' response <- li_post_write(
#'   author = li_urn_me(),
#'   body = "Testing out the LinkedIn API via R and httr2!"
#' )
#' }
li_post_write <- function(author, text, image = NULL, image_alt = "") {
  text <- escape_linkedin_chars(text)

  body <- list(
    author = author,
    lifecycleState = "PUBLISHED",
    commentary = text,
    visibility = "PUBLIC",
    distribution = list(
      `feedDistribution` = "MAIN_FEED",
      `targetEntities` = list(),
      `thirdPartyDistributionChannels` = list()
    ),
    isReshareDisabledByAuthor = FALSE
  )

  if (!is.null(image)) {
    body <- c(
      body,
      list(
        content = list(
          media = list(
            id = li_media_upload(author, image),
            title = image_alt
          )
        )
      )
    )
  }

  resp <- li_req() |>
    httr2::req_url_path_append("posts") |>
    httr2::req_body_json(
      body,
      auto_unbox = TRUE
    ) |>
    httr2::req_retry(
      is_transient = \(x) httr2::resp_status(x) %in% c(401, 403, 425, 429),
      max_tries = 10,
      backoff = ~3
    ) |>
    httr2::req_perform() |>
    httr2::resp_header("x-restli-id")

  message(file.path(
    "https://www.linkedin.com/feed/update/",
    resp
  ))

  invisible(resp)
}

#' Upload image to LinkedIn
#'
#' @param author Character. URN. Either yours (see `li_urn_me()`
#'    or an organisation's).
#' @param image Character. Path to the image you want to use
#'
#' @return image urn asset
li_media_upload <- function(author, media) {
  r <- li_req() |>
    httr2::req_url_path_append("images") |>
    httr2::req_url_query(action = "initializeUpload") |>
    httr2::req_body_json(
      list(
        initializeUploadRequest = list(
          owner = author
        )
      ),
      auto_unbox = TRUE
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_json()

  img_r <- httr2::request(r$value$uploadUrl) |>
    httr2::req_body_file(image) |>
    httr2::req_perform()

  r$value$image
}
