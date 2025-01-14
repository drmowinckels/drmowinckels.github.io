#!/usr/bin/env Rscript

post <- commandArgs(trailingOnly = TRUE)

# Check if arguments are provided
if (length(post) == 0) {
  stop(
    "No arguments provided. Script needs a file to process.", 
  call. = FALSE
  )
}else if(length(post) > 1) {
  warning("Several arguments provided. Processing only first one.", call. = FALSE)
  post <- post[1]
}

source(".github/scripts/linkedin.R", local = TRUE)
source(".github/scripts/kit_newsletter.R", local = TRUE)

create_message <- function(text){
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
tags <- sub("^#r$", "#rstats", tags)
tags <- paste(tags, collapse=" ")

# build URL
uri <- sprintf("https://drmowinckels.io/blog/%s/%s",
  basename(dirname(dirname(post))),
  frontmatter$slug
)

emojis <- c("🦄", "🦜", "🦣", "🦥", "🦦", "🦧", "🦨", "🦩", "🦪", 
"🦫", "🦬", "🦭", "🦮", "🦯", "🦰", "🦱", "🦲", "🦳", "🦴", 
"🦵", "🦶", "🦷", "🦸", "🦹", "🦺", "🦻", "🦼", "🦽", "🦾",
"🦿", "🧀", "🧁", "🧂", "🧃", "🧄", "🧅", "🧆", "🧇", "🧈",
"🧉", "🧊", "🧋", "🧌", "🧍", "🧎", "🧏", "🧐", "🧑", "🧒",
"🧓", "🧔", "🧕", "🧖", "🧗", "🧘", "🧙", "🧚", "🧛", "🧜",
"🧝", "🧞", "🧟", "🧠", "🧡", "🧢", "🧣", "🧤", "🧥", "🧦",
"🧧", "🧨", "🧩", "🧪", "🧫", "🧬", "🧭", "🧮", "🧯", "🧰",
"🧱", "🧲", "🧳", "🧴", "🧵", "🧶", "🧷", "🧸", "🧹", "🧺",
"🧻", "🧼", "🧽", "🧾", "🧿")
emoji <- sample(emojis, 1)

image <- here::here(dirname(post), frontmatter$image)

# Post to Mastodon
rtoot::post_toot(
  status = create_message(frontmatter$seo),
  media = image,
  alt_text = frontmatter$image_alt,
  visibility = "public",
  language = "US-en"
)

# Post to Bluesky
bskyr::bs_post(
  text = substr(create_message(frontmatter$seo), 1, 300),
  images = image,
  images_alt = frontmatter$image_alt,
  langs = "US-en"
)

# Post to LinkedIn
li_posts_write(
  author = li_urn_me(), 
  media_alt = frontmatter$image_alt,
  text = create_message(frontmatter$summary)
)

# Send Newsletter
send_newsletter(frontmatter)
