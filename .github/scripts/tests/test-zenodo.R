describe("doi_record_id()", {
  it("reads the record id from a bare DOI", {
    expect_equal(doi_record_id("10.5281/zenodo.20489086"), "20489086")
  })

  it("reads the record id from a resolver URL", {
    expect_equal(
      doi_record_id("https://doi.org/10.5281/zenodo.13273516"),
      "13273516"
    )
  })

  it("tolerates surrounding whitespace", {
    expect_equal(doi_record_id("  10.5281/zenodo.42  "), "42")
  })

  it("errors on anything that is not a Zenodo DOI", {
    expect_error(doi_record_id("10.1234/elsewhere.99"), "Cannot read")
    expect_error(doi_record_id(NA), "Cannot read")
    expect_error(doi_record_id(""), "Cannot read")
  })
})

describe("find_end()", {
  it("finds the line the first paragraph ends on", {
    expect_equal(find_end(c("one", "two", "", "three")), 2)
  })

  it("returns the last line when there is only one paragraph", {
    expect_equal(find_end(c("one", "two")), 2)
  })

  it("returns zero when there is no content", {
    expect_equal(find_end(c("", "")), 0)
  })
})

describe("is_published()", {
  it("accepts a post dated today or earlier", {
    expect_true(is_published(list(date = "2020-01-01")))
    expect_true(is_published(list(date = as.character(Sys.Date()))))
  })

  it("rejects a post dated in the future", {
    expect_false(is_published(list(date = as.character(Sys.Date() + 1))))
  })

  it("rejects a draft", {
    expect_false(is_published(list(date = "2020-01-01", draft = TRUE)))
  })

  it("ignores a draft flag that is switched off", {
    expect_true(is_published(list(date = "2020-01-01", draft = FALSE)))
  })
})

describe("find_post()", {
  it("resolves a post from its own index.md", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    expect_equal(find_post(post), post)
  })

  it("resolves a post from a sibling image", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    file.create("content/blog/2020/01-01_a-post/featured.png")
    expect_equal(
      find_post("content/blog/2020/01-01_a-post/featured.png"),
      post
    )
  })

  it("resolves a post from a nested figure directory", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    dir.create(
      "content/blog/2020/01-01_a-post/index_files/figure",
      recursive = TRUE
    )
    file.create("content/blog/2020/01-01_a-post/index_files/figure/plot.png")
    expect_equal(
      find_post("content/blog/2020/01-01_a-post/index_files/figure/plot.png"),
      post
    )
  })

  it("resolves posts sitting directly under the content root", {
    local_blog_repo()
    post <- write_post("content/blog/a-loose-post", published_frontmatter())
    expect_equal(find_post(post), post)
  })

  it("returns NA for files outside the content root", {
    local_blog_repo()
    dir.create("themes/hugo-igloo", recursive = TRUE)
    file.create("themes/hugo-igloo/index.html")
    expect_true(is.na(find_post("themes/hugo-igloo/index.html")))
  })

  it("returns NA when the post has been deleted", {
    local_blog_repo()
    expect_true(is.na(find_post("content/blog/2020/01-01_gone/index.md")))
  })
})

describe("post_bundle()", {
  it("lists the rendered markdown ahead of its source", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter()
    )
    expect_equal(
      basename(post_bundle(post)),
      c("index.md", "index.qmd")
    )
  })

  it("picks up Rmd sources", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "Rmd",
      published_frontmatter()
    )
    expect_equal(basename(post_bundle(post)), c("index.md", "index.Rmd"))
  })

  it("ignores other files in the post directory", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    file.create("content/blog/2020/01-01_a-post/featured.png")
    dir.create("content/blog/2020/01-01_a-post/index.markdown_strict_files")
    expect_equal(basename(post_bundle(post)), "index.md")
  })
})

describe("write_doi()", {
  it("inserts the DOI as the first frontmatter entry", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    expect_true(write_doi(post, "10.5281/zenodo.42"))
    expect_equal(readLines(post)[1:2], c("---", "doi: 10.5281/zenodo.42"))
  })

  it("leaves a file that already records a DOI untouched", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    before <- readLines(post)
    expect_false(write_doi(post, "10.5281/zenodo.99"))
    expect_equal(readLines(post), before)
  })

  it("refuses a file with no frontmatter", {
    local_blog_repo()
    dir.create("content/blog/2020/01-01_a-post", recursive = TRUE)
    path <- "content/blog/2020/01-01_a-post/index.md"
    writeLines(c("Just prose.", "No frontmatter."), path)
    expect_warning(
      expect_false(write_doi(path, "10.5281/zenodo.42")),
      "no frontmatter"
    )
  })
})

describe("bundle_doi()", {
  it("finds a DOI recorded only in the source", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    expect_equal(bundle_doi(post), "10.5281/zenodo.42")
  })

  it("returns NA when no file records one", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    expect_true(is.na(bundle_doi(post)))
  })

  it("warns and prefers the rendered markdown when the DOIs disagree", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter("doi: 10.5281/zenodo.99")
    )
    expect_warning(
      expect_equal(bundle_doi(post), "10.5281/zenodo.42"),
      "more than one DOI"
    )
  })
})

describe("sync_doi()", {
  it("copies the DOI from the rendered markdown into the source", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    source_path <- write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter()
    )
    suppressMessages(sync_doi(post))
    expect_equal(frontmatter_doi(source_path), "10.5281/zenodo.42")
  })

  it("repairs a rendered markdown that lost its DOI", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    suppressMessages(sync_doi(post))
    expect_equal(frontmatter_doi(post), "10.5281/zenodo.42")
  })

  it("does nothing for a post that has no DOI yet", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    source_path <- write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter()
    )
    expect_true(is.na(suppressMessages(sync_doi(post))))
    expect_true(is.na(frontmatter_doi(source_path)))
  })
})

describe("update_post()", {
  it("records the DOI in the source as well as the markdown", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    source_path <- write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter()
    )
    suppressMessages(update_post(post, "10.5281/zenodo.42"))
    expect_equal(frontmatter_doi(post), "10.5281/zenodo.42")
    expect_equal(frontmatter_doi(source_path), "10.5281/zenodo.42")
  })
})

describe("needs_doi()", {
  it("wants a DOI for a published post that has none", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    expect_true(needs_doi(post))
  })

  it("leaves a post that already has a DOI alone", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    expect_false(needs_doi(post))
  })

  it("will not mint a second DOI when only the source records one", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    write_source(
      "content/blog/2020/01-01_a-post",
      "qmd",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    expect_false(needs_doi(post))
  })

  it("leaves drafts and future posts alone", {
    local_blog_repo()
    draft <- write_post(
      "content/blog/2020/01-01_draft",
      published_frontmatter("draft: true")
    )
    future <- write_post(
      "content/blog/2030/01-01_future",
      c("title: Later", "date: '2030-01-01'", "slug: later")
    )
    expect_false(needs_doi(draft))
    expect_false(needs_doi(future))
  })
})

describe("needs_update()", {
  it("wants a new version for a published post with a DOI", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    git_commit_all("Add post")
    expect_true(needs_update(post))
  })

  it("skips a post that has no DOI yet", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    git_commit_all("Add post")
    expect_false(needs_update(post))
  })

  it("skips drafts and future posts", {
    local_blog_repo()
    draft <- write_post(
      "content/blog/2020/01-01_draft",
      published_frontmatter("doi: 10.5281/zenodo.42", "draft: true")
    )
    future <- write_post(
      "content/blog/2030/01-01_future",
      c(
        "title: Later",
        "date: '2030-01-01'",
        "slug: later",
        "doi: 10.5281/zenodo.43"
      )
    )
    git_commit_all("Add posts")
    expect_false(needs_update(draft))
    expect_false(needs_update(future))
  })

  it("honours [skip zenodo] in the commit that changed the post", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    git_commit_all("Add post")
    write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42"),
      body = c("Fixed a typo.", "", "Second paragraph.")
    )
    git_commit_all("Fix typo [skip zenodo]")
    expect_false(needs_update(post))
  })
})

describe("changed_posts()", {
  it("finds a post whose prose changed", {
    local_blog_repo()
    write_post("content/blog/2020/01-01_a-post", published_frontmatter())
    base <- git_commit_all("Add post")
    write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter(),
      body = c("Rewritten.", "", "Second paragraph.")
    )
    git_commit_all("Edit post")

    expect_equal(
      changed_posts(base),
      "content/blog/2020/01-01_a-post/index.md"
    )
  })

  it("finds a post whose image changed", {
    local_blog_repo()
    write_post("content/blog/2020/01-01_a-post", published_frontmatter())
    writeLines("one", "content/blog/2020/01-01_a-post/featured.svg")
    base <- git_commit_all("Add post")
    writeLines("two", "content/blog/2020/01-01_a-post/featured.svg")
    git_commit_all("Swap image")

    expect_equal(
      changed_posts(base),
      "content/blog/2020/01-01_a-post/index.md"
    )
  })

  it("reports each changed post once", {
    local_blog_repo()
    write_post("content/blog/2020/01-01_one", published_frontmatter())
    write_post("content/blog/2020/02-01_two", published_frontmatter())
    base <- git_commit_all("Add posts")
    writeLines("a", "content/blog/2020/01-01_one/extra.txt")
    write_post(
      "content/blog/2020/01-01_one",
      published_frontmatter(),
      body = "Edited."
    )
    write_post(
      "content/blog/2020/02-01_two",
      published_frontmatter(),
      body = "Edited."
    )
    git_commit_all("Edit both")

    expect_equal(
      changed_posts(base),
      c(
        "content/blog/2020/01-01_one/index.md",
        "content/blog/2020/02-01_two/index.md"
      )
    )
  })

  it("ignores changes outside the content root", {
    local_blog_repo()
    write_post("content/blog/2020/01-01_a-post", published_frontmatter())
    base <- git_commit_all("Add post")
    dir.create("assets/css", recursive = TRUE)
    writeLines("body {}", "assets/css/main.css")
    git_commit_all("Style tweak")

    expect_equal(changed_posts(base), character(0))
  })

  it("returns nothing when the commit that follows adds the DOI", {
    local_blog_repo()
    write_post("content/blog/2020/01-01_a-post", published_frontmatter())
    base <- git_commit_all("Add post")
    write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("doi: 10.5281/zenodo.42")
    )
    doi_commit <- git_commit_all("Add doi")

    expect_equal(changed_posts(doi_commit), character(0))
  })
})

describe("get_metadata()", {
  it("uses the frontmatter summary as the description", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter("summary: A curated summary.")
    )
    metadata <- suppressMessages(get_metadata(post))
    expect_equal(
      metadata$metadata$description,
      "Dr. Mowinckel's blog: A curated summary."
    )
  })

  it("falls back to the first paragraph when there is no summary", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter(),
      body = c("Opening line.", "", "Later paragraph.")
    )
    metadata <- suppressMessages(get_metadata(post))
    expect_equal(
      metadata$metadata$description,
      "Dr. Mowinckel's blog: Opening line."
    )
  })

  it("builds the post url from the date and slug", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    metadata <- suppressMessages(get_metadata(post))
    expect_equal(
      metadata$metadata$url,
      "https://drmowinckels.io/blog/2020/a-post"
    )
  })

  it("carries the tags through as keywords", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    metadata <- suppressMessages(get_metadata(post))
    expect_equal(metadata$metadata$keywords, list("r", "hugo"))
  })

  it("keeps a single tag an array rather than a bare string", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      c("title: A Post", "date: '2020-01-01'", "slug: a-post", "tags:", "  - r")
    )
    metadata <- suppressMessages(get_metadata(post))
    payload <- as.character(jsonlite::toJSON(metadata, auto_unbox = TRUE))
    expect_match(payload, '"keywords":["r"]', fixed = TRUE)
  })

  it("records the version it was given", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    metadata <- suppressMessages(get_metadata(post, version = "abc1234"))
    expect_equal(metadata$metadata$version, "abc1234")
  })

  it("leaves the version out when none is given", {
    local_blog_repo()
    post <- write_post(
      "content/blog/2020/01-01_a-post",
      published_frontmatter()
    )
    metadata <- suppressMessages(get_metadata(post))
    expect_null(metadata$metadata$version)
  })
})

describe("zenodo_request()", {
  it("targets the deposition endpoint", {
    withr::local_envvar(ZENODO_API_TOKEN = "token")
    expect_equal(
      zenodo_request()$url,
      "https://zenodo.org/api/deposit/depositions"
    )
  })

  it("appends path segments", {
    withr::local_envvar(ZENODO_API_TOKEN = "token")
    expect_equal(
      zenodo_request(123L, "actions", "publish")$url,
      "https://zenodo.org/api/deposit/depositions/123/actions/publish"
    )
  })

  it("follows ZENODO_BASE_URL so the sandbox can be used", {
    withr::local_envvar(
      ZENODO_API_TOKEN = "token",
      ZENODO_BASE_URL = "https://sandbox.zenodo.org"
    )
    expect_equal(
      zenodo_request("7")$url,
      "https://sandbox.zenodo.org/api/deposit/depositions/7"
    )
  })

  it("refuses to build a request without a token", {
    withr::local_envvar(ZENODO_API_TOKEN = "")
    expect_error(zenodo_request(), "ZENODO_API_TOKEN is not set")
  })
})

describe("zenodo_dry_run()", {
  it("is off by default", {
    withr::local_envvar(ZENODO_DRY_RUN = NA)
    expect_false(zenodo_dry_run())
  })

  it("accepts the usual affirmative spellings", {
    for (value in c("true", "TRUE", "1", "yes")) {
      withr::local_envvar(ZENODO_DRY_RUN = value)
      expect_true(zenodo_dry_run())
    }
  })

  it("treats anything else as off", {
    withr::local_envvar(ZENODO_DRY_RUN = "false")
    expect_false(zenodo_dry_run())
  })
})

describe("zenodo_error_body()", {
  it("reports the Zenodo message and per-field errors", {
    response <- httr2::response_json(
      status_code = 400,
      body = list(
        status = 400,
        message = "Validation error.",
        errors = list(list(field = "metadata.title", message = "Required."))
      )
    )
    expect_equal(
      zenodo_error_body(response),
      c(
        "Zenodo said: 400 - Validation error.",
        "- metadata.title: Required."
      )
    )
  })

  it("copes with a response that is not JSON", {
    response <- httr2::response(
      status_code = 502,
      headers = list(`Content-Type` = "text/html"),
      body = charToRaw("<html>nope</html>")
    )
    expect_match(zenodo_error_body(response), "Zenodo said")
  })
})
