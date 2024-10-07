---
doi: 10.5281/zenodo.13897972
editor_options: 
  markdown: 
    wrap: sentence
format: hugo-md
title: Creating post summary with AI from Hugging Face
author: Dr. Mowinckel
date: '2024-10-07'
tags:
  - r
  - LLM
  - AI
  - API
slug: ai-blog-summary
image: images/hf-logo.png
summary: |
  When you have lots of old blog posts, writing good summaries for SEO can be very tedious. Using AI, we can get summaries for our posts easily. Using httr2 we can access models through the Hugging Face API.
---

After my last post, I got to thinking about the summaries of my posts.
I am not the best at summarising what my posts are about, and also my post summaries are used for SEO.
"What is SEO", you ask?
It stands for Search Enginge Optimization, and it one of the major factors for what gets listed first in search engine results.
And, I really would like my stuff to have good results there.
Furthermore, as my last post was about archiving my posts on Zenodo, I realise that having a good description of the post is also very important for the Zenodo meta-data.
Currently, for all posts that I haven't provided a (poor) summary, the first paragraph of the post is used.
And I don't think that usually reflects what the post is actually about.

I saw a colleague at my University post about him [creating summaries for his blog using OpenAI API](https://www.arj.no/2024/07/13/blog-descriptions/), and I thought that sounded like a cool idea!
Now, he uses python, and openAI, which is not what I am going to do.
I will give this a go through R and using [Hugging Face](https://huggingface.co/) as my model server.

## Hugging Face Community

Hugging Face is a leading company in the field of artificial intelligence and natural language processing (NLP).
It provides an open-source platform and extensive libraries known as "Transformers" that enables developers and researchers to utilize pre-trained language models for various applications.
I heard about Hugging Face for the first time through a Posit blogpost about [them releasing Hugging Face integrations](https://blogs.rstudio.com/ai/posts/2023-07-12-hugging-face-integrations/).

I had a peek, and saw that Hugging Face has a nice API, that seemed quite simple to deal with.
It also is free, at least for my needs (just summarising a post once in a while).
I signed up, and dived into it!

## Using the Hugging Face API

First step was to just manage to connect to the API and get some data back as expected.
We'll proceede much like we did in the Zenodo post, grabbing the API key for Hugging Face API (that I retrieved from my account), and putting that in the `.Renviron` file for secure and easy access.

``` r
# Get API key
api_key <- Sys.getenv("HUGGING_KEY")
```

Then we need to define what to send to the model to process.
It needs at minimum `inputs` which is the text we want summarised.
Then, I'll add a minimum and maximum length ot the summary.
SEO is usually best limited to 155 characters, which is what Google will preview for you when you search.

``` r
# Define the API request body
body <- list(
  inputs = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
  max_length = 155, 
  min_length = 140
)
```

Creating the request again is also really similar to what we've seen for the Zenodo post.
We start defining the main URL of the API, then that we want to send it to a model, which I chose as [facebook/bart-large-cnn](https://huggingface.co/facebook/bart-large-cnn), which is well-known and used text-summariser.
We make sure we use the "POST" method, and that we send the data as json, which is what the API expects.
You likely *always* want `auto_unbox = TRUE` in this, as it makes sure the data is more likely to be formatted correctly.
Lastly, we add `req_retry` because when I was testing this, I periodically hit `503 service unavailable` back from the API.
After a little digging, I learned that that could happen where there when there no servers available to run the model.
This is something you have to learn to live with when you want free tier stuff.
So, I set up the code to retry 10 times before giving up, just so I can make sure I actually get a response back.

``` r
# Make the API request using httr2
response <- httr2::request("https://api-inference.huggingface.co/") |>
  httr2::req_url_path_append("models") |>
  httr2::req_url_path_append("facebook/bart-large-cnn") |>
  httr2::req_auth_bearer_token(api_key) |>
  httr2::req_method("POST") |>
  httr2::req_body_json(body, auto_unbox = TRUE) |>
  httr2::req_retry(max_tries = 10) |>
  httr2::req_perform()
httr2::resp_body_json(response)
```

    [[1]]
    [[1]]$summary_text
    [1] "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. It has survived not only five centuries, but also the leap into electronic typesetting. It was popularised in the 1960s with the release of Letraset sheets. More recently with desktop publishing software like Aldus PageMaker."

A summary!
Now, you'll notice its more than 155 characters.
I can't say that I understand why, but I've tried several iterations and still get more back than I ask for.
But it's a summary so I'll take it :P

## Preparing content for summarising

As in the [last post](/blog/2024/fair-blog), we need to figure out which posts needs a summary.
Now, while I won't set this up to run on Github Actions (I can make sure to write my summaries from now own), I was thinking about making sure the code can be used for several things.
Like abstracting it a little so I could reuse the code for the Zenodo process too (and maybe other things in the future too).

First thing is to figure out what posts need a summary.
It should not be a draft, and not have a summary from before.

``` r
#' Check if post is draft
#' 
#' @params x path to markdown file
#' @return logical true if needs summary, false if not
is_draft <- function(x){
  frontmatter <- readLines(x, 30)

  draft <- frontmatter[grep("^draft:", frontmatter)]
  if(length(draft) != 0){
    if(grepl("true", draft))
      return(TRUE) 
  }

  return(FALSE)
}

#' Check if post needs summary
#' 
#' Checks if post does not have a summary
#' and is no longer a draft.
#' 
#' @params x path to markdown file
#' @return logical true if needs summary, false if not
needs_summary <- function(x){
  frontmatter <- readLines(x, 30)

  # Don't process if draft
  if(is_draft(x)){
    return(FALSE) 
  }

  # Don't process if already has summary
  if(any(grep("^summary:", frontmatter))){
    return(FALSE)
  }

  return(TRUE)
}
```

With those functions in place, we can make sure we can find the posts that need processing.
For convenience, and for possible use in other cases, I'll also set up a function to find the posts I'm after.
This one is a fun one though, because one of the arguments we will pass to out function, is the `needs_summary` function we just made!
This is much like the `apply`-family of functions do, or [purrr](https://purrr.tidyverse.org/)-functions.

In this function, we pass the path we want to search for index files in, and the function that will be applied on the found files to check if they are what we are after.
Using this means I can write any function to check if a file is what we are after for any other condition I am interested in.
So it's really nice and flexible.

``` r
#' Find all posts without summaries
#' 
#' Searches the given path for index.md files
#' 
#' 
#' @params x path to search in
#' @params fun function to apply that returns TRUE
#'    or FALSE for whether posts should be included.
#' @return vector of paths to files
find_posts <- function(x, fun){
  posts <- list.files(x, 
    "^index.md", 
    recursive = TRUE,
    full.names = TRUE
  )
  # Only return wanted posts
  posts[sapply(posts, fun)]
}
posts <- find_posts(
  here::here("content/blog/"),
  needs_summary
)
posts
```

    character(0)

Now that we have found all the files that need a summary, we need to prepare the content for generating that summary.
I found that the yaml frontmatter usually made some pretty weird summaries, so I made a function that would return the content of the file without the yaml, just with the remaning post content.

``` r
#' Read the contents of file
#' 
#' Turns the content of a text file into a single
#' character object.
#' 
#' @params path path to file to read in
#' @return single character object with markdown content.
get_content <- function(path){
  x <- readLines(path, warn = FALSE) 
  end_yaml <- grep("^---", x)[2]
  title <- rmarkdown::yaml_front_matter(path)$title
  paste0(title, x[end_yaml:length(x)], collapse = " ")
}
```

## Writing summary to file

Once we have the summary, we'll want to write them to the markdown file's frontmatter.
To do that, we need another convenience function to help us get it in the right spot.
I'll again make it more general, so that if I want I can use it for more in the future.
This little function will place any key: value information at the bottom of the frontmatter of a markdown file, and write it back to the path it came from.
I'm pretty content with this little snippet.

``` r
#' Add key value pair to yaml frontmatter
#' 
#' Adds a key-value pair to the frontmatter
#' of a markdown file. Both reads and writes
#' from the path specified.
#' 
#' @params path path to markdown file
#' @params key parameter name
#' @params value value of the parameter
add_frontmatter <- function(path, key, value){
  post <- readLines(path)
  end_yaml <- grep("^---", post)[2]
  new_content <- c(
    post[1:(end_yaml-1)],
    sprintf("%s: %s", key, value),
    post[end_yaml:length(post)]
  )
  writeLines(new_content, path)
}
```

And then we of course need the actual function to do it all!

``` r
#' Function to get a summary from Hugging Face
#' 
#' Reads in a markdown file and passes the content to 
#' the set model on Hugging Face to get a summary of 
#' the text
#' 
#' @params paths path to a markdown file
#' @params model model on Hugging Face to summarise
#'   a text
#' @return Summary text
add_summary <- function(paths, model) {
  if(missing(model))
    stop("You need to specify a model to summarise the text.", call. = FALSE)

  if(missing(paths))
    stop("You need to specify markdown file to summarise.", call. = FALSE)

  # Make sure path is expanded and readable
  paths <- normalizePath(paths)
  
  # Get API key
  api_key <- Sys.getenv("HUGGING_KEY")

  contents <- lapply(paths, get_content)
  #contents <- paste("make an SEO summary of the following text:", contents)
  
  # Define the API request body
  body <- list(
    inputs     = contents,
    max_length = 130, 
    min_length = 30
  )

  cache <- tempdir()
  print(cache)

  # Make the API request using httr2
  response <- httr2::request("https://api-inference.huggingface.co/") |>
    httr2::req_url_path_append("models") |>
    httr2::req_url_path_append(model) |>
    httr2::req_auth_bearer_token(api_key) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_retry(max_tries = 10) |>
    httr2::req_cache(cache, max_age = 1) |>
    httr2::req_perform()

  # Parse the response
  result <- httr2::resp_body_json(response) |>
    unlist()
  result <- gsub("<n>", " ", result)
  names(result) <- paths

  mapply(add_frontmatter,
    path = paths,
    value = result,
    MoreArgs = list(
      key = "summary"
    )
  )
  return(result)
}
```

What is neat here is that the model accepts several inputs at once, meaning I don't have to call the API a bunch of times.
Just a single time with all the posts I want summarised.
The function takes two arguments, the paths to the posts, and which model I want to use.
I added this last bit because there are [quite some summarising models](https://huggingface.co/models?pipeline_tag=summarization) to choose from and they don't give equal results (duh!).

I started out trying with the facebook model, but it had a cap on the number of characters that was just too little for my use.
So I played around until I found a model that seemed to do the jobs nicely.

## The entire process

So, now I will have summaries for all my posts!
They might not be the absolute best (nothing made with AI ever is), but at least there are summaries there.
I just need to remember to always write my own post summaries from now on,
which should be easy enough :P
And I also need to figure out how to update all those Zenodo descriptions, with these new summaries.

``` r
#' Check if post is draft
#' 
#' @params x path to markdown file
#' @return logical true if needs summary, false if not
is_draft <- function(x){
  frontmatter <- readLines(x, 30)

  draft <- frontmatter[grep("^draft:", frontmatter)]
  if(length(draft) != 0){
    if(grepl("true", draft))
      return(TRUE) 
  }

  return(FALSE)
}

#' Check if post needs summary
#' 
#' Checks if post does not have a summary
#' and is no longer a draft.
#' 
#' @params x path to markdown file
#' @return logical true if needs summary, false if not
needs_summary <- function(x){
  frontmatter <- readLines(x, 30)

  # Don't process if draft
  if(is_draft(x)){
    return(FALSE) 
  }

  # Don't process if already has summary
  if(any(grep("^summary:", frontmatter))){
    return(FALSE)
  }

  return(TRUE)
}

#' Find all posts without summaries
#' 
#' Searches the given path for index.md files
#' 
#' 
#' @params x path to search in
#' @params fun function to apply that returns TRUE
#'    or FALSE for whether posts should be included.
#' @return vector of paths to files
find_posts <- function(x, fun){
  posts <- list.files(x, 
    "^index.md", 
    recursive = TRUE,
    full.names = TRUE
  )
  # Only return wanted posts
  posts[sapply(posts, fun)]
}

#' Read the contents of file
#' 
#' Turns the content of a text file into a single
#' character object.
#' 
#' @params path path to file to read in
#' @return single character object with markdown content.
get_content <- function(path){
  x <- readLines(path, warn = FALSE) 
  end_yaml <- grep("^---", x)[2]
  title <- rmarkdown::yaml_front_matter(path)$title
  paste0(title, x[end_yaml:length(x)], collapse = " ")
}

#' Add key value pair to yaml frontmatter
#' 
#' Adds a key-value pair to the frontmatter
#' of a markdown file. Both reads and writes
#' from the path specified.
#' 
#' @params path path to markdown file
#' @params key parameter name
#' @params value value of the parameter
add_frontmatter <- function(path, key, value){
  post <- readLines(path)
  end_yaml <- grep("^---", post)[2]
  new_content <- c(
    post[1:(end_yaml-1)],
    sprintf("%s: %s", key, value),
    post[end_yaml:length(post)]
  )
  writeLines(new_content, path)
}

#' Function to get a summary from Hugging Face
#' 
#' Reads in a markdown file and passes the content to 
#' the set model on Hugging Face to get a summary of 
#' the text
#' 
#' @params paths path to a markdown file
#' @params model model on Hugging Face to summarise
#'   a text
#' @return Summary text
add_summary <- function(paths, model) {
  if(missing(model))
    stop("You need to specify a model to summarise the text.", call. = FALSE)

  if(missing(paths))
    stop("You need to specify markdown file to summarise.", call. = FALSE)

  # Make sure path is expanded and readable
  paths <- normalizePath(paths)
  
  # Get API key
  api_key <- Sys.getenv("HUGGING_KEY")

  contents <- lapply(paths, get_content)
  #contents <- paste("make an SEO summary of the following text:", contents)
  
  # Define the API request body
  body <- list(
    inputs     = contents,
    max_length = 130, 
    min_length = 30
  )

  cache <- tempdir()
  print(cache)

  # Make the API request using httr2
  response <- httr2::request("https://api-inference.huggingface.co/") |>
    httr2::req_url_path_append("models") |>
    httr2::req_url_path_append(model) |>
    httr2::req_auth_bearer_token(api_key) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body, auto_unbox = TRUE) |>
    httr2::req_retry(max_tries = 10) |>
    httr2::req_cache(cache, max_age = 1) |>
    httr2::req_perform()

  # Parse the response
  result <- httr2::resp_body_json(response) |>
    unlist()
  result <- gsub("<n>", " ", result)
  names(result) <- paths

  mapply(add_frontmatter,
    path = paths,
    value = result,
    MoreArgs = list(
      key = "summary"
    )
  )
  return(result)
}

posts <- find_posts(
  here::here("content/blog/"),
  needs_summary
)

#summaries <- lapply(posts, get_seo_summary, model = "Falconsai/text_summarization")
summary <- add_summary(posts, model = "sshleifer/distilbart-cnn-12-6")
summary
```
