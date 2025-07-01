send_newsletter <- function(frontmatter, url) {
  newsletter <- glue::glue(
    '
    <div>
      <h1 class="" style="font-weight:bold;font-style:normal;font-size:1em;margin:0;font-size:2em;font-weight:normal;font-family:Georgia,Times,\'Times New Roman\',serif;color:#023f3c;line-height:1.5">{frontmatter$title}</h1>

      <div style="text-align:center;padding:0.05px"><figure style="margin:1em 0;margin-top:12px;margin-bottom:12px;margin-left:0;margin-right:0;display:inline-block;max-width:800px;width:100%;vertical-align:top"><div style="display:block">​<img contenteditable="false" src="{url}/{frontmatter$image}" width="800" style="border:0 none;display:block;height:auto;line-height:100%;outline:none;-webkit-text-decoration:none;text-decoration:none;max-width:100%;opacity:1;border-radius:4px 4px 4px 4px;width:800px;height:auto;object-fit:contain"></div>

      <p class="ck-paragraph" style="margin:1em 0;font-size:18px;line-height:1.5em;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,Oxygen-Sans,Ubuntu,Cantarell,\'Helvetica Neue\',sans-serif;color:#0c4848;font-size:16px;line-height:1.5">{frontmatter$summary}</p>

      <div style="width:100%;display:flow-root;text-align:center;margin-top:8px;margin-bottom:8px"><a href="{uri}" target="_blank" rel="noopener noreferrer" class="ck-button" style="color:#0875c1;color:#825a83;display:inline-block;text-decoration:none;border-style:solid;text-align:center;background-color:#0f6261;color:#ffffff;font-size:16px;border-color:#0f6261;padding:12px 20px;border-radius:4px 4px 4px 4px">Read more</a></div>
    </div>
  '
  )

  httr2::request("https://api.convertkit.com/v3/broadcasts") |>
    httr2::req_body_json(
      list(
        public = TRUE,
        api_secret = Sys.getenv("KIT_SECRET"),
        description = frontmatter$seo,
        thumbnail_url = file.path(url, frontmatter$image),
        subject = frontmatter$title,
        content = newsletter,
        send_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
      )
    ) |>
    httr2::req_perform()
}
