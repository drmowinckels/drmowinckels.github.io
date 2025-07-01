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

source(here::here(".github/scripts/utils.R"))
source(here::here(".github/scripts/linkedin.R"))
source(here::here(".github/scripts/kit_newsletter.R"))

create_message <- function(text, uri) {
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
tags <- tags2hash(frontmatter$tags)

# build URL
url <- sprintf(
  "https://drmowinckels.io/blog/%s/%s",
  basename(dirname(dirname(post))),
  frontmatter$slug
)
uri <- short_url(url)

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
  text = substr(
    create_message(frontmatter$seo, uri),
    1,
    (290 - strlength(uri))
  ),
  images = image,
  images_alt = frontmatter$image_alt
)


# Post to LinkedIn
li_post_write(
  author = li_urn_me(),
  image_alt = frontmatter$image_alt,
  image = image,
  text = create_message(frontmatter$summary, url)
)

# Post to Mastodon
rtoot::post_toot(
  status = create_message(frontmatter$seo, uri),
  media = image,
  alt_text = frontmatter$image_alt,
  visibility = "public",
  language = "US-en"
)


# Send Newsletter
send_newsletter(frontmatter, url)
