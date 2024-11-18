# SHhmelessly stolen and adapted from rOpenSci
# https://github.com/ropensci-org/promoutils/blob/main/R/linkedin.R


# LinkedIn Chars to escape
escape_linkedin_chars <- function(x) {
  chars <- c("\\|", "\\{", "\\}", "\\@", "\\[", "\\]", "\\(", "\\)", "\\<", "\\>", "\\#", "\\\\", "\\*", "\\_", "\\~")
  p <- stats::setNames(paste0("\\", chars), chars)
  stringr::str_replace_all(x, p)
}

#' Post to LinkedIn
#'
#' @param author Character. URN. Either yours (see `li_urn_me()` or rOpenSci's
#'   "urn:li:organization:77132573")
#' @param body Character. The body of the post as you would like it to appear.
#' @param dry_run Logical. TRUE to show what would be sent to the server without
#'   actually sending it.
#'
#' @return A string of the URN for the post id.
#' @export
#'
#' @examples
#'
#' # Dry-run
#' id <- li_posts_write(
#'   author = ro_urn, # Post on behalf of rOpenSci
#'   body = "Testing out the LinkedIn API via R and httr2!",
#'   dry_run = TRUE)
#'
#' \dontrun{
#' # Real post
#' id <- li_posts_write(
#'   author = ro_urn, # Post on behalf of rOpenSci
#'   body = "Testing out the LinkedIn API via R and httr2!")
#' }


li_posts_write <- function(author, body, dry_run = FALSE) {

  # Need to escape () around links in the body or we lose them and everything following
  body <- escape_linkedin_chars(body)

  r <- li_req_posts() |>
    httr2::req_headers("Content-Type" = "application/json") |>
    httr2::req_body_json(list(
      author = author,
      commentary = body,
      visibility = "PUBLIC",
      distribution = list("feedDistribution" = "MAIN_FEED",
                          "targetEntities" = list(),
                          "thirdPartyDistributionChannels" = list()),
      lifecycleState = "PUBLISHED",
      isReshareDisabledByAuthor = FALSE
    ), auto_unbox = TRUE)

  if(dry_run) {
    httr2::req_dry_run(r)
  } else {
    httr2::req_perform(r) |>
      httr2::resp_header("x-restli-id")
  }
}

#' Setup API request for Posts endpoint
#'
#' @references
#'  - https://learn.microsoft.com/en-us/linkedin/marketing/integrations/community-management/shares/posts-api
#'
#' @noRd
li_req_posts <- function() {
  httr2::request(base_url = "https://api.linkedin.com/rest/posts") |>
    li_req_auth() |>
    httr2::req_headers(
      "LinkedIn-Version" = "202311",
      "X-Restli-Protocol-Version" = "2.0.0"
    )
}



#' Fetch your personal URN number
#'
#' This is required to post on LinkedIn to your personal account
#' (for rOpenSci, use the organization urn, "urn:li:organization:77132573"
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
  id <- httr2::request(base_url = "https://api.linkedin.com/v2/me") |>
    li_req_auth() |>
    httr2::req_url_query(projection = "(id)") |>
    httr2::req_perform() |>
    httr2::resp_body_json() |>
    unlist()
  paste0("urn:li:person:", id)
}

#' Create authorization for rOpenSci on LinkedIn
#'
#' @param req httr2 request
#'
#' @noRd
li_req_auth <- function(req) {
  # Uses refresh token so works programatically on GitHub API
  # Define authorization
  httr2::req_oauth_refresh(
    req,
    client = li_client())
}



#' Setup rOpenSci client id for LinkedIn API
#'
#' Expects to find the "Client Secret" in the .Renviron file under
#' LINKEDIN_SECRET (Or as a general environemental variable through GitHub
#' actions).
#'
#' @noRd
li_client <- function() {
  httr2::oauth_client(
    name = "drmowinckels_linkedIn",
    id = "77vql6v7pla4n2",
    token_url = "https://www.linkedin.com/oauth/v2/accessToken",
    secret = Sys.getenv("LINKEDIN_SECRET"))
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
#' t <- li_auth()
#' t$refresh_token
#' }

li_auth <- function() {
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
    scope = paste("w_member_social"),
    pkce = FALSE
  )
}

httr2::oauth_client(
  name = "drmowinckels-gha",
  id = "778d2qp9e4w5vz",
  token_url = "https://www.linkedin.com/oauth/v2/accessToken",
  secret = Sys.getenv("LINKEDIN_SECRET")
)

