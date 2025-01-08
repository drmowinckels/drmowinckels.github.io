# Explicitly library httpuv so renv acknowledges that it's needed.
library(httpuv)

Sys.setenv(
  LI_ENDPOINT = "rest"
)

# LinkedIn Chars to escape
escape_linkedin_chars <- function(x) {
  chars <- c("\\|", "\\{", "\\}", "\\@", "\\[", "\\]", "\\(", "\\)", "\\<", "\\>", "\\#", "\\\\", "\\*", "\\_", "\\~")
  p <- stats::setNames(paste0("\\", chars), chars)
  stringr::str_replace_all(x, p)
}

# Automatically set the LinkedIn API endpoint_version to 2 months ago since they
# constantly change that without changing core features.
li_get_version <- function(){
  li_version_date <- lubridate::rollback(lubridate::rollback(lubridate::today()))

  paste0(
    lubridate::year(li_version_date), 
    stringr::str_pad(lubridate::month(li_version_date), 2, pad = "0")
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


#' 
li_req <- function(endpoint_version = Sys.getenv("LI_ENDPOINT")){
  httr2::request("https://api.linkedin.com") |> 
    httr2::req_url_path_append(endpoint_version) |> 
    httr2::req_headers(
      "LinkedIn-Version" = li_get_version(),
      "X-Restli-Protocol-Version" = "2.0.0",
      "Content-Type" = "application/json"
    ) |>
    li_req_auth() 
}

# Shmelessly stolen and adapted from rOpenSci
# https://github.com/ropensci-org/promoutils/blob/main/R/linkedin.R


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
#' response <- li_posts_write(
#'   author = ro_urn, # Post on behalf of rOpenSci
#'   body = "Testing out the LinkedIn API via R and httr2!"
#' )
#' }
li_posts_write <- function(author, body, dry_run = FALSE) {

  # Need to escape () around links in the body or we lose them and everything following
  body <- escape_linkedin_chars(body)

  r <- li_req() |> 
    httr2::req_url_path_append("posts") |>
    httr2::req_body_json(list(
      author = author,
      commentary = body,
      visibility = "PUBLIC",
      distribution = list(
        "feedDistribution" = "MAIN_FEED",
        "targetEntities" = list(),
        "thirdPartyDistributionChannels" = list()
      ),
      lifecycleState = "PUBLISHED",
      isReshareDisabledByAuthor = FALSE
    ), 
    auto_unbox = TRUE)
    

  if(dry_run) {
    httr2::req_dry_run(r)
  } else {
    r |> 
      httr2::req_retry(
        is_transient = \(x) httr2::resp_status(x) == 401,
        max_tries = 10,
        backoff = ~ 3
      ) |> 
      httr2::req_perform() |>
      httr2::resp_header("x-restli-id")
  }
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

#' Setup client id for LinkedIn API
#'
#' Expects to find the "Client Secret" in the .Renviron file under
#' LI_CLIENT_SECRET (Or as a general environemental variable through GitHub
#' actions).
#'
#' @noRd
li_client <- function(endpoint_version = Sys.getenv("LI_ENDPOINT")) {
  httr2::oauth_client(
    name = "drmowinckels_linkedIn",
    id = Sys.getenv("LI_CLIENT_ID"),
    token_url = sprintf("https://www.linkedin.com/oauth/%s/accessToken", endpoint_version),
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

# To refresh the refresh, visit 
# https://www.linkedin.com/developers/tools/oauth/token-generator


## Trying to get things working ----

response <- li_posts_write(
  author = li_urn_me(), 
  body = "Testing the LinkedIn API"
)
