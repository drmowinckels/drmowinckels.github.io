#!/usr/bin/env Rscript

post <- commandArgs(trailingOnly = TRUE)

# Check if arguments are provided
if (length(post) == 0) {
  stop(
    "No arguments provided. Script needs a file to process.",
    call. = FALSE
  )
} else if (length(post) > 1) {
  warning(
    "Several arguments provided. Processing only first one.",
    call. = FALSE
  )
  post <- post[1]
}

short_url <- function(uri) {
  resp <- httr2::request("http://v.gd/create.php") |>
    httr2::req_url_query(
      format = "json",
      url = uri
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_string() |>
    jsonlite::fromJSON()
  resp$shorturl
}

strlength <- function(x) {
  strsplit(x, "") |>
    unlist() |>
    length()
}


source(here::here(".github/scripts/linkedin.R"))
source(here::here(".github/scripts/kit_newsletter.R"))

create_message <- function(text) {
  glue::glue(
    "📝 New post: '{frontmatter$title}'
    
    {emoji} {text} 
    
    👀 {uri} 
    
    {tags}"
  )
}

#post <- "content/blog/2025/01-01_longcovid/index.md"
frontmatter <- rmarkdown::yaml_front_matter(post)

# fix tags
tags <- paste0("#", frontmatter$tags)
tags <- sub("^#r$", "#rstats", tags, ignore.case = TRUE)
tags <- sub(" ", "", tags, ignore.case = TRUE)
tags <- paste(tags, collapse = " ")

# build URL
uri <- sprintf(
  "https://drmowinckels.io/blog/%s/%s",
  basename(dirname(dirname(post))),
  frontmatter$slug
) |>
  short_url()

# fmt: skip
emojis <- c(
  "🦄", "🦜", "🦣", "🦥", "🦦", "🦧", "🦨", "🦩", "🦪", "🦫", 
  "🦬", "🦭", "🦮", "🦯", "🦰", "🦱", "🦲", "🦳", "🦴", "🦵", 
  "🦶", "🦷", "🦸", "🦹", "🦺", "🦻", "🦼", "🦽", "🦾", "🦿", 
  "🧀", "🧁", "🧂", "🧃", "🧄", "🧅", "🧆", "🧇", "🧈", "🧉", 
  "🧊", "🧋", "🧌", "🧍", "🧎", "🧏", "🧐", "🧑", "🧒", "🧓", 
  "🧔", "🧕", "🧖", "🧗", "🧘", "🧙", "🧚", "🧛", "🧜", "🧝", 
  "🧞", "🧟", "🧠", "🧡", "🧢", "🧣", "🧤", "🧥", "🧦", "🧧", 
  "🧨", "🧩", "🧪", "🧫", "🧬", "🧭", "🧮", "🧯", "🧰", "🧱", 
  "🧲", "🧳", "🧴", "🧵", "🧶", "🧷", "🧸", "🧹", "🧺", "🧻", 
  "🧼", "🧽", "🧾", "🧿"
)
emoji <- sample(emojis, 1)

image <- here::here(dirname(post), frontmatter$image)

# Post to Bluesky
bskyr::bs_post(
  text = substr(create_message(frontmatter$seo), 1, (300 - strlength(uri))),
  images = image,
  images_alt = frontmatter$image_alt
)


# Post to LinkedIn
li_post_write(
  author = li_urn_me(),
  image_alt = frontmatter$image_alt,
  image = image,
  text = create_message(frontmatter$summary)
)

# Post to Mastodon
rtoot::post_toot(
  status = create_message(frontmatter$seo),
  media = image,
  alt_text = frontmatter$image_alt,
  visibility = "public",
  language = "US-en"
)


# Send Newsletter
send_newsletter(frontmatter)
