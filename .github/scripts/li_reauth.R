li_reauth <- function(key) {
  linkedin_oauth_client <- httr2::oauth_client(
    id = Sys.getenv("LINKEDIN_CLIENT_ID"),
    secret = Sys.getenv("LINKEDIN_CLIENT_SECRET"),
    token_url = "https://www.linkedin.com/oauth/v2/accessToken",
    name = "drmowinckels-gha-app"
  )

  # Perform the initial authentication
  # This will open a browser for you to log in and grant permissions.
  # httr2 will then save the token to its cache directory.
  req <- httr2::request(
    "https://api.linkedin.com/v2/me"
  ) %>%
    httr2::req_oauth_auth_code(
      client = linkedin_oauth_client,
      auth_url = "https://www.linkedin.com/oauth/v2/authorization",
      scope = c("r_liteprofile", "r_emailaddress"),
      redirect_uri = "http://localhost:1414/",
      cache_disk = TRUE,
      cache_key = key
    )

  # You can perform a request to confirm the token works
  httr2::req_perform(req) |>
    httr2::resp_body_json() |>
    print()

  # Get the path to the cached token file
  token_file_path <- httr2:::oauth_cache_path(
    name = linkedin_oauth_client$name,
    key = key
  )

  message("Cached token file located at: ", token_file_path)
  token_file_path
}
