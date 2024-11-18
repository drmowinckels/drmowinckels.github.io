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

frontmatter <- rmarkdown::yaml_front_matter(post)

# fix tags
tags <- paste0("#", frontmatter$tags)
tags <- sub("^#r$", "#rstats", tags)
tags <- paste(tags, collapse=", ")

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

# Create message
message <- glue::glue(
  "📝 New blog post 📝 

  '{frontmatter$title}'
  
  {emoji} {frontmatter$summary} 
  
  👀  Read at: {uri} 
  
  {tags}"
)

image <- here::here(dirname(post), frontmatter$image)

# Post to Mastodon
rtoot::post_toot(
  status = message,
  media = image,
  alt_text = "Blogpost featured image",
  visibility = "public",
  language = "US-en"
)


# Post to Bluesky
bskyr::bs_post(
  text = message,
  images = image,
  images_alt = "Blogpost featured image",
  langs = "US-en",
  user = "drmowinckels.io"
)


# Post to LinkedIn


# Send Newsletter
newsletter <- glue::glue('
  <div>
    <h1 class="" style="font-weight:bold;font-style:normal;font-size:1em;margin:0;font-size:2em;font-weight:normal;font-family:Georgia,Times,\'Times New Roman\',serif;color:#023f3c;line-height:1.5">{frontmatter$title}</h1>

    <div style="text-align:center;padding:0.05px"><figure style="margin:1em 0;margin-top:12px;margin-bottom:12px;margin-left:0;margin-right:0;display:inline-block;max-width:800px;width:100%;vertical-align:top"><div style="display:block">​<img contenteditable="false" src="{uri}/{frontmatter$image}" width="800" height="auto" style="border:0 none;display:block;height:auto;line-height:100%;outline:none;-webkit-text-decoration:none;text-decoration:none;max-width:100%;opacity:1;border-radius:4px 4px 4px 4px;width:800px;height:auto;object-fit:contain"></div>

    <p class="ck-paragraph" style="margin:1em 0;font-size:18px;line-height:1.5em;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Oxygen-Sans,Ubuntu,Cantarell,\'Helvetica Neue\',sans-serif;color:#0c4848;font-size:16px;line-height:1.5">{frontmatter$summary}</p>

    <div style="width:100%;display:flow-root;text-align:center;margin-top:8px;margin-bottom:8px"><a href="{uri}" target="_blank" rel="noopener noreferrer" class="ck-button" style="color:#0875c1;color:#825a83;display:inline-block;text-decoration:none;border-style:solid;text-align:center;background-color:#0f6261;color:#ffffff;font-size:16px;border-color:#0f6261;padding:12px 20px;border-radius:4px 4px 4px 4px">Read more</a></div>
  </div>
')


resp <- httr2::request("https://api.convertkit.com/v3/broadcasts") |> 
  httr2::req_body_json(
    list(
      public        = TRUE,
      api_secret    = Sys.getenv("KIT_SECRET"),
      description   = frontmatter$summary,
      thumbnail_url = file.path(uri, frontmatter$image),
      subject       = frontmatter$title,
      content       = newsletter
    )
  ) |> 
  httr2::req_perform()



