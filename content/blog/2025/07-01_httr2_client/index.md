---
doi: 10.5281/zenodo.15783058
editor_options:
  markdown:
    wrap: sentence
title: "Decoding OAuth2 M2M with httr2: Client Setup & API Testing"
format: hugo-md
author: Dr. Mowinckel
date: "2025-07-01"
categories: []
tags:
  - R
  - API
slug: httr2_client
image: httr2_cassette.png
image_alt: >
  A stylized graphic featuring the white 'httr2' text in the foreground. Behind
  and slightly above it, a colorful, retro-style audio cassette tape is depicted
  with vibrant pink, blue, and teal accents. A small, pink mockingbird is
  perched on the upper left edge of the cassette tape. The background is a solid
  dark purple.
summary: >
  This post details the process of setting up an OAuth2 Machine-to-Machine (M2M)
  client using the httr2 package in R. 
  It covers client creation,
  handling authentication flows, and comprehensively testing API calls using the
  vcr package for request recording and testthat for mocking functions to ensure
  robust and reliable package development.
seo: >-
  Setting up httr2 OAuth2 M2M client in R, with testing using vcr and mocking mocking.
---

I recently managed to get some actual work done!
If you have been reading this blog lately, you'll know why it's been a while, but I am so very excited that I did some solid work!

So, I have a package that connects to my University's survey platform.
It enables researchers to grab the data collected (and associated meta-data) right into their R console, and can set up a whole pipeline for working with their data.
You know we all love that.

I recently did a large re-write of the package from httr to httr2, but the one thing I was struggling with getting to work was a client to deal with the OAuth.
I had this rather unsatisfactory code where I was grabbing a token and caching it myself, but that's not ideal.

But I met with some difficulties, as the API OAuth was set up in an unfamiliar way.
Traditionally, I've encountered APIs that use user authentication, often termed User-to-Machine (U2M) flows.
Here, a user interacts with a client application, typically via a browser login, to grant the application permission to act on their behalf.

```mermaid

sequenceDiagram
    title U2M (User-to-Machine) Flow: Authorization Code Grant
    actor User
    participant ClientApp as Client App
    participant AuthServer as Authorization Server
    participant ResourceServer as Resource Server

    User->>+ClientApp: 1. Initiates action (e.g., clicks 'Log in')
    ClientApp-->>-User: 2. Redirects browser to Auth Server for authorization

    User->>+AuthServer: 3. Logs in and grants consent
    AuthServer-->>-User: 4. Redirects browser back to Client App with Authorization Code

    ClientApp->>+AuthServer: 5. Exchanges Authorization Code for Access Token (back-channel)
    AuthServer-->>-ClientApp: 6. Responds with Access Token & Refresh Token

    ClientApp->>+ResourceServer: 7. Requests protected resource with Access Token
    ResourceServer-->>-ClientApp: 8. Returns requested data
```

Imagine you want to use a cool new photo editing app (the "Client App") to access pictures you've saved on your cloud storage (the "Resource Server").
You don't want to give the photo app your cloud storage password directly -- that would be risky!

It's like giving a trusted friend (the app) a special key to your locker, but only after you confirm with the locker company (the Authorization Server) that it's okay, and you never give your friend your locker combination.

However, my university's service employs a Machine-to-Machine (M2M) authentication setup.
In this model, the client itself possesses the necessary credentials to access resources directly, without acting on behalf of a specific end-user.
This distinction was crucial, as the API wasn't designed for the headless, programmatic access I intended.

```mermaid
sequenceDiagram
    title M2M (Machine-to-Machine) Flow: Client Credentials Grant
    participant ClientApp as Client App
    participant AuthServer as Authorization Server
    participant ResourceServer as Resource Server

    ClientApp->>+AuthServer: 1. Requests Access Token using its credentials (client_id, client_secret)
    AuthServer-->>-ClientApp: 2. Validates credentials and returns Access Token

    ClientApp->>+ResourceServer: 3. Requests protected resource with Access Token
    ResourceServer-->>-ClientApp: 4. Returns requested data
```

Imagine you have a smart home system (the "Client App") that needs to automatically turn on your outdoor lights (a "Resource Server" controlled by another service) when it gets dark.
No human user is involved in this decision; it's just one part of your smart home talking to another.

It's like two robots talking to each other.
One robot (the app/service) has a secret handshake (its credentials) that it uses to get a temporary ID card (the Access Token) from another robot (the Authorization Server).
Then, it uses that ID card to access a specific resource (like turning on lights) from a third robot (the Resource Server), all without any human telling them what to do.

## Setting up a client

First stage is to set up a client that can help you handle authentication.
This is the wanted setup, rather than grabbing the token yourself and dealing with refresh token and caching etc.
You let the client deal with the necessary stuff in the background and you can get to the fun stuff.

A client needs two basic things:

1.  an ID
2.  a secret

Both these should be provided to you from whichever API you are making the client at.

Let's start with a function to check if the information we need is saved in the environment.
Here I'm assuming this was set up in the `.Renviron` file, which is instructions I will provide with the package.
And having a function to check if the information is provided correctly is important for any package.
Notice how I both allow for the information to be set in the environment, but also to be provided to the function.
This should give users more flexibility.

```r
#' Check Environment Variables for Nettskjema Authentication
#'
#' This function verifies whether the required system
#' variables (`NETTSKJEMA_CLIENT_ID` and
#' `NETTSKJEMA_CLIENT_SECRET`) are set to enable
#' authentication with the Nettskjema API. It provides
#' feedback on the setup status and returns whether the
#' system is correctly configured.
#'
#' @inheritParams ns_client
#'
#' @return Logical. Returns `TRUE` if both environment
#'    variables are set, otherwise `FALSE`.
#'
#' @examples
#' ns_has_auth()
#'
#' @references
#' For more information about authentication setup, see:
#'
#' @export
ns_has_auth <- function(
  client_id = Sys.getenv("NETTSKJEMA_CLIENT_ID"),
  client_secret = Sys.getenv("NETTSKJEMA_CLIENT_SECRET")
) {
  if (!nzchar(client_id) || !nzchar(client_secret)) {
    return(FALSE)
  }

  TRUE
}
```

Now that we have that, we can start setting up a client.
To start that, I had a look at the documentation for the API, and it had this code for how to retrieve the token

    curl -X POST \
      -u "clientId:clientSecret" \
      -d "grant_type=client_credentials" \
      "https://authorization.nettskjema.no/oauth2/token"

This curl command, while providing the token, didn't immediately reveal how to implement a persistent client.
I wasn't familiar with this specific flow.
Thankfully, httr2 includes an incredibly powerful helper for just such a dilemma: `curl_translate`.

```r
httr2::curl_translate(
  'curl -X POST \
    -u "clientId:clientSecret" \
    -d "grant_type=client_credentials" \
    "https://authorization.nettskjema.no/oauth2/token"'
)
```

    request("https://authorization.nettskjema.no/oauth2/token") |>
      req_method("POST") |>
      req_body_raw("grant_type=client_credentials", "application/x-www-form-urlencoded") |>
      req_auth_basic("clientId", "clientSecret") |>
      req_perform()

Neat!
{httr2} really does come with such a genius suite of functions, but this one is my favourite.

But I'm still not seeing a client?
The code works, I get a token, but then I'd need to do the whole caching etc myself, and that's not a great option.
if (!nzchar(client_id) \|\| !nzchar(client_secret)) {
I need a client.

You will notice in my setup I also added an argument to name the client, a good practice that helps service providers identify which client ran specific commands in their logs.
Since I'm not expecting my users to directly call the client function, I will call it in the background for them, I'm not gonna add looking for the credentials to this function.

```r
#' Create an OAuth2 Client for Nettskjema API
#'
#' This function initializes an OAuth2 client using
#'  the `httr2::oauth_client` function. It is used to
#' authenticate and interact with the Nettskjema API.
#'
#' @param client_id [character] The client ID provided by Nettskjema.
#' @param client_secret [character] The client secret provided
#'     by Nettskjema.
#' @param client_name [character] An optional name for the
#'     client (default = "nettskjemar").
#'
#' @return A configured `httr2::oauth_client` object.
#'
#' @examples
#' # Example: Initialize an OAuth2 client for Nettskjema
#' client <- ns_client(
#'   client_id = "your_client_id",
#'   client_secret = "your_client_secret"
#' )
#'
#' # Using a custom client name
#' client <- ns_client(
#'   client_id = "your_client_id",
#'   client_secret = "your_client_secret",
#'   client_name = "custom_client_name"
#' )
#'
#' @export
ns_client <- function(
  client_id,
  client_secret,
  client_name = "nettskjemar"
) {
  # Check for valid id and secret
  if (!ns_has_auth(client_id, client_secret)) {
    cli::cli_abort(
      "Variables ",
      "{.code client_id} and ",
      "{.code client_secret} ",
      "are not set up.",
      "Please read ",
      "{.url https://www.capro.dev/nettskjemar/articles/authentication.html}",
      " on how to set your credentials correctly."
    )
  }

  httr2::oauth_client(
    id = client_id,
    secret = client_secret,
    name = client_name,
    token_url = "https://authorization.nettskjema.no/oauth2/token",
    auth = "header"
  )
}
```

So, I've fast-forwarded to a working function.
It took me a fair while to get here, and help from [Jon Harmon](http://jonthegeek.com).
The crucial detail that unlocked the client setup was the `auth = "header"` argument.
By default, `oauth_client` uses `auth = "body"`.
My initial assumption was that this referred to where the response token would be sent.
However, it actually dictates where the client credentials (ID and secret) are sent for authentication.
The `curl_translate` output clearly showed `req_auth_basic("clientId", "clientSecret")`, indicating basic authentication in the header.
Once I correctly specified `auth = "header"`, the client sprang to life!"

## Using the client

Now that I have a client correctly set up, I need to figure out how to use it.
In the [httr2 OAuth documentation](https://httr2.r-lib.org/articles/oauth.html) there are examples using `oauth_flow_auth_code`, which is a U2M flow.
I wasn't sure which one I needed to use for this setup.
There are _a lot_ of [OAuth functions](https://httr2.r-lib.org/reference/index.html#oauth) in httr2, but which one is the right one for this?
Actually clients are mentioned in several places in the docs, so which one should I use?
After being puzzled a while, I noticed one called `req_oauth_client_credentials`, and that `client credentials` is something in the header of that curl command we translated earlier.
That, is a really big hint!
This function, in addition to setting client information, also needs a request as input.
So it means its something that should be piped with other httr2 commands.

```r
#' Authenticate Nettskjema request
#'
#' After creating a client in Nettskjema,
#' this function will retrieve the access
#' token needed for the remaining processes
#' in the package. Automatically caches the
#' token for more efficient API usage.
#'
#' @param req An httr2 request, usually {\code{\link{ns_req}}}
#' @param client_id Character. Retrieved from the
#'     Client portal.
#' @param client_secret Character. Retrieved from the
#'     Client portal.
#' @param client_name Character. Used to identify who
#'     has been running the commands.
ns_req_auth <- function(
  req,
  client_id = Sys.getenv("NETTSKJEMA_CLIENT_ID"),
  client_secret = Sys.getenv("NETTSKJEMA_CLIENT_SECRET"),
  client_name = "nettskjemar"
) {
  httr2::req_oauth_client_credentials(
    req,
    client = ns_client(
      client_id = client_id,
      client_secret = client_secret,
      client_name = client_name
    )
  )
}
```

Right!
So, we have the client set up grabbing information from the environment, with error messages if it cant find it.
We should try out a request!

```r
httr2::request("https://nettskjema.no/api/v3/") |>
  ns_req_auth() |>
  httr2::req_url_path_append("me") |>
  httr2::req_perform() |>
  httr2::resp_body_json()
```

    $isPersonalDataResponsible
    [1] FALSE

    $displayName
    [1] "ccda25ce-8256-4c6f-ba71-7a4357dc6caf@apiclient"

    $logoutLink
    [1] "/signout"

    $isSuperUser
    [1] FALSE

    $isAuthenticated
    [1] TRUE

    $userType
    [1] "UNKNOWN_ROLE"

    $hasAcceptedTos
    [1] TRUE

    $isSupportUser
    [1] FALSE

    $isAdministrativeUser
    [1] TRUE

    $isInLdapGroupUioTils
    [1] FALSE

This specific API endpoint provides information about the client making the request.
And it works!
With a working client, that will cache and retrieve refreshtokens and whatever, we don't need to think about any of the backbone of the API authentication anymore.
Honestly, I feel every time I try reading up on OAuth my brain explodes.
I can't seem to wrap my head around it for more than 5 seconds (and is it wrapped, or more like my brother's attempts at gift wrapping a sweater for Christmas?).

## Testing the client

While getting all that set up was hard enough, I also knew that this iteration of the package needed a test suite.
I had previously omitted doing that, as I didn't have the bandwidth to actually figure out how to test API calling functions and not breaking CRAN policy about using internet sources while checking a package.

This time though, I knew I needed to mature the package, and myself.

![Screeenshot from "The Lion King" original animated movie of Rafiki touching Simba's shoulder with the text "It is time" on the top right corner](itistime.jpg)

After looking at the [vcr documentation](https://docs.ropensci.org/vcr/), I was ready to get started.
It looks, deceptively easy?
First thing is first, we need to create a `helper.R` file within the testthat folder for the package, which will load {vcr} and set up some initial important things.

One important thing, since my package lives on GitHub means the source is open for all to see.
vcr stores API calls and results as YAMLs, meaning the content can be read by _anyone_.
This means I need top make sure that the client secret is kept secure.
The `vcr_configure` function has a `filter_sensitive_data` argument which allows us to obfuscate the information we provide in the yamls so they are not exposed.
In this case, it will take the output of `Sys.getenv("NETTSKJEMA_CLIENT_SECRET")` and replace it with the string `<<CLIENT_SECRET>>` in all the yaml files.
Further, it has a `dir` function where you specify where the cassettes that vcr records will be saved.
In this case, we set `vcr::vcr_test_path("fixtures")` which puts the cassettes in `tests/testthat/fixtures`.

```r
# *Required* as vcr is set up on loading
library("vcr")

invisible(vcr::vcr_configure(
  filter_sensitive_data = list(
    "<<CLIENT_SECRET>>" = Sys.getenv("NETTSKJEMA_CLIENT_SECRET")
  ),
  dir = vcr::vcr_test_path("fixtures")
))

vcr::check_cassette_names()
```

Lastly, in the setup we also run a function to check that all the cassette names are good and things are ready to go for vcr to do its thing.
I can't seem to wrap my head around it for more than 5 seconds (and is it wrapped, or more like my brother's attempts at gift wrapping a sweater for Christmas?).
Using `vcr::use_cassette` can be done in one of two ways (maybe more, but this is how I have now learned):

1.  nested inside `test_that()`
2.  wrapped around `test_that()`

I'm not entirely sure which is best when, but I found it more meaningful for me to nest inside `test_that()`, which more closely resembles my standard testing workflow for packages.
`vcr::use_cassette` will run a call to the API _if there is no associated cassette already in existence_, and save the call and results in a yaml.
All subsequent runs of that test, will then use the information from the yaml rather than doing the call to the API.

Let's say I have created a function to easily get the information about the client, i.e. using the request code I used before in the post.
This is something you'd typically do in a package, set up convenience functions to get to specific end-points of an API that are important.

```r
# Example for `ns_get_me` (add this somewhere before "Testing the client")
ns_get_me <- function() {
  httr2::request("https://nettskjema.no/api/v3/") |>
    ns_req_auth() |>
    httr2::req_url_path_append("me") |>
    httr2::req_perform() |>
    httr2::resp_body_json()
}
```

In the code below, I run the function `ns_get_me()`, which is a convenience function I made that runs the request I made earlier in this post.
The results I save in the `me` variable, which I can then run some expectations on, like I would normally do using testthat.
In this case, i make sure `me` is a list, and has the length of `10` (my actual package tests run more expectations, but this is enough for this example).

```r
test_that("test user information", {
  vcr::use_cassette("ns_get_me", {
    me <- ns_get_me()
  })

  expect_is(me, "list")
  expect_length(me, 10)
})
```

Running this test, a file is made within the testthat folder called `fixtures/ns_get_me.yml`, and its contents looks like so:

```yml
http_interactions:
  - request:
      method: get
      uri: https://nettskjema.no/api/v3/me
      body:
        encoding: ""
        string: ""
      headers: []
    response:
      status:
        status_code: 200
        message: OK
      headers:
        server: nginx
        date: Fri, 06 Jun 2025 12:11:47 GMT
        content-length: "234"
        content-encoding: gzip
        referrer-policy: same-origin
        set-cookie:
          JSESSIONID=F5AA8CC20BCFE3463BA73D25E04BF01E; Path=/api/v3; Secure;
          HttpOnly; SameSite=Lax
        strict-transport-security: max-age=31536000 ; includeSubDomains ; preload
        vary: accept-encoding
        x-application-gateway-proxy: api
        x-frame-options: DENY
        x-robots-tag: noindex, nofollow, noarchive, noai, noimageai, noml, SPC
        x-content-type-options: nosniff
        x-dns-prefetch-control: "off"
        origin-agent-cluster: ?1
        x-permitted-cross-domain-policies: none
        x-download-options: noopen
        x-xss-protection: "0"
        content-type: application/json
        cache-control: private, max-age=0, no-cache, no-store
        permissions-policy:
          interest-cohort=(), browsing-topics=(), join-ad-interest-group=(),
          run-ad-auction=(), conversion-measurement=(), accelerometer=(), ambient-light-sensor=(),
          autoplay=(), battery=(), camera=(), display-capture=(), encrypted-media=(),
          fullscreen=(self), gamepad=(self), geolocation=(), gyroscope=(), layout-animations=(self),
          legacy-image-formats=(), magnetometer=(), microphone=(), midi=(), oversized-images=(self),
          payment=(), picture-in-picture=(), publickey-credentials-create=(self), publickey-credentials-get=(),
          speaker-selection=(self), sync-xhr=(), unoptimized-images=(self), unsized-media=(self),
          usb=(), screen-wake-lock=(), web-share=(), xr-spatial-tracking=(), clipboard-read=(),
          clipboard-write=(), hid=(), serial=(), cross-origin-isolated=(), execution-while-not-rendered=(self),
          execution-while-out-of-viewport=(self), keyboard-map=(), navigation-override=(self),
          identity-credentials-get=(), idle-detection=(), local-fonts=(), otp-credentials=(),
          window-management=(), storage-access=()
        content-security-policy: object-src 'none'; frame-ancestors 'self'; upgrade-insecure-requests
        tdm-reservation: "1"
      body:
        encoding: ""
        file: no
        string: '{"isPersonalDataResponsible":false,"displayName":"ccda25ce-8256-4c6f-ba71-7a4357dc6caf@apiclient","logoutLink":"/signout","isSuperUser":false,"isAuthenticated":true,"userType":"UNKNOWN_ROLE","hasAcceptedTos":true,"isSupportUser":false,"isAdministrativeUser":true,"isInLdapGroupUioTils":false}'
    recorded_at: 2025-06-06 12:11:47 GMT
    recorded_with: vcr/1.6.0, webmockr/2.0.0
```

There is a lot of information here, about the request made, the status code of the response, and the response it self.
This is great stuff!
Every time I ran the test, it was passing and I was happy.

Now, [Maëlle](https://masalmon.eu/) has of course read through this post and mentioned that there is not also [`vcr::local_cassette`](https://docs.ropensci.org/vcr/articles/vcr.html#testing-with-vcr) in the vcr development version, where you would not have to do all the code-wrapping stuff.
I don't mind too much wrapping, but I can see the readability improve with it and I'll likely implement it when its released.

Anyway, I committed my code and sent it off to GitHub, where all my package checking actions subsequently failed.
Which confused me, since I thought given I recorded the responses with vcr, that wouldn't happen?

Where I got my logic wrong, was that what was failing wasn't the API calls (or vcr's accessing of the cassettes), but rather my own checking function for whether authentication was set up (which it was not on GitHub Actions!)

Remember I made a `ns_has_auth` function, that checks whether authentication is set up?
Well, that's integrated in the `ns_client` function, meaning _before_ any calls to the API!
So my GitHub Actions. were failing before any cassettes were in play.

This is where the dreaded moment I knew was going to happen in this journey would indeed happen, I needed to figure out how to _mock_ a function.
Mocking in a test is used to circumvent a specific piece of code from testing.
This sounds counterintuitive, since we are supposed to be testing the code, but it is very necessary in certain cases.

In this particular case, I don't need to test the `ns_has_auth()` function, that is not the functionality I am after testing.
I can test that in another test specifically made to test it, where I can control input and results better.
In this case, I want to test the API call and make sure vcr has recorded a good cassette and that this cassette is used in instances where I need it to (like on GitHub Actions. and during CRAN checks).

With all that being said, I need to make sure that the `ns_has_auth()` function always returns true and can continue on to the remaining function where I ask it to during testing.
We create a function with `testthat::local_mocked_bindings` which we will wrap around any code where we want to test the other parts of the function rather than checking if authentication is set up.
The functions defined in the locked mocked bindings, will replace the function of the same name from the `.package` we specify.
This makes it possible to _mock_ any function from any package when needed.

```r
with_mocked_nettskjema_auth <- function(expr) {
  testthat::local_mocked_bindings(
    ns_has_auth = function(...) TRUE,
    .package = "nettskjemar"
  )
  force(expr)
}
```

This function uses the base R `force` function to run the code it's wrapped around, using the `ns_has_auth()` function that has been set up as a local mocked binding.
So anything wrapped in this code that calls `ns_has_auth()` will always return `TRUE` because I have mocked it that way.

Our final test code, therefore, became a layered structure: a testthat block wrapping a vcr cassette, which in turn enveloped our mocked function call.

```r
test_that("test user information", {
  vcr::use_cassette("ns_get_me", {
    with_mocked_nettskjema_auth(
      me <- ns_get_me()
    )
  })

  expect_is(me, "list")
  expect_length(me, 10)
})
```

So my GitHub Actions were failing before any cassettes were in play.

Now, the `ns_get_me` function I am trying to test, will always get to the API call part of the function, because I am circumventing the `ns_has_auth` function.
The cassette should thus finally be in use!
And indeed, when I sent the code out to GitHub, all my checks passed.

My tests now wrap all the API call tests with that specific mocked binding, except for the specific tests I have to check the `ns_has_auth()` function itself.
We create a function with [`testthat::local_mocked_bindings()`](https://testthat.r-lib.org/reference/local_mocked_bindings.html) which we will wrap around any code where we want to test the other parts of the function rather than checking if authentication is set up.

```r
test_that("ns_has_auth identifies variables", {
  withr::with_envvar(
    c(
      NETTSKJEMA_CLIENT_ID = "dummy_id",
      NETTSKJEMA_CLIENT_SECRET = "dummy_secret"
    ),
    {
      expect_true(ns_has_auth())
    }
  )

  withr::with_envvar(
    c(
      NETTSKJEMA_CLIENT_ID = "",
      NETTSKJEMA_CLIENT_SECRET = ""
    ),
    {
      expect_false(ns_has_auth())
    }
  )
})
```

Here I am not mocking, but explicitly setting environment variables for the tests with `withr::with_envvar()`.
Now, the `ns_get_me()` function I am trying to test, will always get to the API call part of the function, because I am circumventing the `ns_has_auth()` function.

## Periodically testing API Calls

My tests now wrap all the API call tests with that specific mocked binding, except for the specific tests I have to check the `ns_has_auth()` function itself.
But how do we discover if the API itself alters?
Now, the `ns_get_me()` function I am trying to test, will always get to the API call part of the function, because I am circumventing the `ns_has_auth()` function.
But we can be sure I won't do that unless someone reports errors, and ideally I'd like to be a little more pro-active than that.

Thankfully, vcr has a way to let us do that!
My tests now wrap all the API call tests with that specific mocked binding, except for the specific tests I have to check the `ns_has_auth()` function itself.
Neat!
Of course they would provide such a nice and neat solution to do this.
So I made a GitHub Action workflow that will run weekly and test against the API, so I make sure that things work.
I will only be notified on e-mail if it fails, so I can just forget about it until I get a notification.
Which is pretty nice, in my opinion.

```yaml
# Workflow derived from https://github.com/r-lib/actions/tree/v2/examples
# Need help debugging build failures? Start at https://github.com/r-lib/actions#where-to-find-help
on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: "30 2 * * 0"

name: Check API endpoints

permissions: read-all

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest

    name: Check API responses

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes

    steps:
      - uses: actions/checkout@v4
But how do we discover if the API itself alters?
      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: "release"
          http-user-agent: "release"
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: |
            any::rcmdcheck
            any::knitr
          needs: check

      - name: "Setup env for full test suite"
        run: |
          echo "NETTSKJEMA_CLIENT_ID=${{ secrets.CLIENT_ID }}" >> .Renviron
          echo "NETTSKJEMA_CLIENT_SECRET=${{ secrets.CLIENT_SECRET }}" >> .Renviron
          echo "VCR_TURN_OFF=true" >> .Renviron

      - uses: r-lib/actions/check-r-package@v2
        with:
          upload-snapshots: true
          build_args: 'c("--no-manual","--compact-vignettes=gs+qpdf","--as-cran")'

      - name: Build vignettes
        run: |
          install.packages(".", repos = NULL, type = "source")
          nettskjemar:::knit_vignettes()
        shell: Rscript {0}
```

## Making vignettes that call the API

The last bit of the puzzle, and which you will see in my github action above, is that I call the function `nettskjemar:::knit_vignettes()`.
This is an _internal_ function in my package that will knit my vignettes.

"But why aren't your vignettes knit on check or build as normal?", you may ask.
Because, the vignettes need the API credentials to knit.
I've made them so that they do, and that I can make sure the vignette code actually work.

How do I do that then?
I take a note from the [rOpenSci blog](https://ropensci.org/blog/2019/12/08/precompute-vignettes/#the-solution-locally-knitting-rmarkdown) on locally knitting the vignettes.
So rather than having a vignette called `nettskjemar.rmd` I have one called `nettskjemar.rmd.orig`.
By having this extra ending, R build will ignore the vignettes.
We rather build the vignettes our selves, which I do with the handy internal function I made:

```r
knit_vignettes <- function() {
  proc <- list.files(
    "vignettes",
    "orig$",
    full.names = TRUE
  )

  lapply(proc, function(x) {
    fig_path <- "static"
    knitr::knit(
      x,
      gsub("\\.orig$", "", x)
    )
    imgs <- list.files(fig_path, full.names = TRUE)
    sapply(imgs, function(x) {
      file.copy(
        x,
        file.path("vignettes", fig_path, basename(x)),
        overwrite = TRUE
      )
    })
    invisible(unlink(fig_path, recursive = TRUE))
  })

  list(
    "Knit vignettes",
    sapply(proc, basename)
  )
}
```

Ok, it's not that little, a lot is going on here.
First, we locate all files ending with `orig` in the vignettes folder, and then we make sure the output name is without the extra `.orig` extension.
Then we also make sure to carry over any images the vignettes may create into the vignettes folder.
Since, the knitting will happen in the project root, rather than in the vignettes folder, the output images will not be in the correct place.Making sure we carry over the output files is thus very important.

Again, Maëlle pointed out that there is also ways to [use cassettes in vignettes](https://docs.ropensci.org/vcr/articles/vcr.html#other-uses-examples-and-vignettes).
I had not noticed this when I set up my package, but I'm looking forward testing it out in my next package iteration.

I've found this code works well for this purpose, and I use it in a couple of my packages actually.
Hopefully, it may be of use to others.

## Conclusion

So that is it!
OAuth with a client, testing API calls with vcr and mocking, and explicitly setting environment variables for testing in specific situations.
Do you mock your API calls when testing?
