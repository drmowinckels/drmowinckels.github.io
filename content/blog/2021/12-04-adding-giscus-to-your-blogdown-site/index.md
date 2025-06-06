---
doi: 10.5281/zenodo.13273518
title: Adding giscus to your blogdown site
author: Athanasia M. Mowinckel
date: '2021-12-04'
categories: []
tags:
  - blogdown
output:
  html_document:
    keep_md: yes
always_allow_html: yes
image: jackson_popcorn.jpeg
slug: "adding-giscus-to-your-blogdown-site"
aliases:
  - '/blog/2021-12-04-adding-giscus-to-your-blogdown-site'
summary: Switch from Disqus to Giscus for comments on your Hugo site using blogdown. This guide shows how to integrate Giscus, a GitHub discussions-based comment section, into your blog seamlessly. Learn how to set up Giscus, modify your theme, and customize the comment section for a streamlined experience.
seo: Switch from Disqus to Giscus on Hugo with blogdown. Integrate GitHub discussions for comments and customize your theme.
---

This is going to be a short one.
I have been wanting to change my comment section from disqus to utterances for a long while, but have been postponing. Or procrastinating… with me, its usually the latter.
I’m not going to go into details of why I wanted to move away from disqus, [others](https://fatfrogmedia.com/delete-disqus-comments-wordpress/) have written better about it that I ever could.

I was procrastinating mainly because it felt like a little much to figure out [utterances](https://utteranc.es/) too, and the idea of using GitHub issues for comments felt awkward.

But, the other day, I saw Shannon Pileggi tweet about something new and exciting:
  
giscus sounded awesome. I already use github to not only store all my blog content, but also use github actions to [render and deploy](/blog/2021-03-23-using-github-actions-to-build-your-hugo-website/) my blog.

Off I went to the blogpost she links to, an awesome post by [Joel Nitta](https://www.joelnitta.com/posts/2021-11-24_using-giscus/), that made the whole process super smooth.

I followed all the steps he provides for getting giscus installed for your github repo, setting up GitHub discissions, and getting the information I needed to get it into my blog. I’m not going to re-iterate them, he does a great job describing it, so you should rather take a look there.

The difference between Joel and me, is that I am not going to switch away from blogdown to distill. I love blogdown too much, and I love hugo too much. So where he starts describing how to get giscus working with distill, I’ll take you through getting it working with blogdown/hugo!

# Creating a new layouts file

This will require some navigation in your hugo theme’s folders.
You will need to navigate to the html template for you blog/post sections or wherever your theme has the comments section defined.

**Unfortunately, I cannot tell you exactly where that is! It depends entirely on the developer of your theme, how that has been organised.**

In my case it was quite easy, I looked into the `themes/my-theme/layouts/blog/single.html` and found a line of code that said `{{ partial comments.html .}}` this is hugo-speak for inserting contents from another layout into the current file. So I navigated to `themes/my-theme/layouts/partials/comments.html` and found what I was looking for.

In my case, the theme creator had a little piece of code that would enable disqus if the disqus shortname was set in the config toml.

``` html
{{- if .Site.Config.Services.Disqus.Shortname }}
    <div class="container disqus">
        {{ template "_internal/disqus.html" . }}
    </div>
{{- end }}
```

We dont really need to deal with that, it can just stay there, I’ll be removing my disqus shortname from the config, so it wont appear anymore.
But I needed to add the giscus script that was provided to me following Joel’s instructions, below this.

``` html
<div class="container giscus my-4">
    <script src="https://giscus.app/client.js"
        data-repo="[YOUR REPO]"
        data-repo-id="[YOUR REPO ID]"
        data-category="[YOUR CATEGORY]"
        data-category-id="[YOUR CATEGORY ID]"
        data-mapping="pathname"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-theme="light"
        data-lang="[YOUR LANGUAGE]"
        crossorigin="anonymous"
        async>
    </script>
</div>
```

But we cannot (should not) add this to the theme files!
If you do this, it will break in the future when you update your theme. Don’t do it!

You copy the entire file, and in your main blogdown folder create the same path to the file as if the `theme/my-theme` part of the path did not exist. For me, that meant creating a file under my main project folder `layouts/partials/comments.html`.

``` sh
your_site/
  content/
  config.toml
  theme/
    my_theme/
      layouts/      --------
        partials/           | mimmick this
          comments.html ----
  layouts/    --------------
    partials/               | in your root project folder
      comments.html   ------           
```

What will happen, is that when hugo renders your site, it will use the layouts file in your folder rather than the theme’s folder. Its a way of customising hugo without disturbing the main theme.
I saved it, rendered the site and it worked! I had giscus installed on my page.

# Adding giscus to a theme

The theme for my site, is actually my own adaptation of the hugo theme [instoduction](https://github.com/victoriadrake/hugo-theme-introduction) by Victoria Drake. My version has a couple of extra features, like the options to have blogposts shown in a grid with images, rather than a simple list.

I called the theme [hugo chairome](https://github.com/Athanasiamo/hugo-chairome?organization=Athanasiamo&organization=Athanasiamo). “Chairome” is what we say in Greek when we make a new acquaintance.
I wanted to make sure anyone using my theme might also get giscus working easily through the config file rather than having to make their own workaround like explained above.

In the comments.html file in my theme, I added the following:

``` html
{{- if .Site.Params.giscus.repo }}
<div class="container giscus my-4">
    <script src="https://giscus.app/client.js"
        data-repo={{ .Site.Params.giscus.repo }}
        data-repo-id={{ .Site.Params.giscus.repo_id }}
        data-category={{ .Site.Params.giscus.category }}
        data-category-id={{ .Site.Params.giscus.category_id }}
        data-mapping={{ .Site.Params.giscus.mapping }}
        data-reactions-enabled={{ .Site.Params.giscus.reactions_enabled | default 0}}
        data-emit-metadata={{ .Site.Params.giscus.emit_metadata | default 0 }}
        data-theme={{ .Site.Params.giscus.theme }}
        data-lang={{ .Site.Params.giscus.lang }}
        crossorigin="anonymous"
        async>
    </script>
</div>
{{- end }}
```

And in the example config.toml I added the following:

``` toml
# To enable giscus, the github discussions based comment section,
# Follow the steps described to enable giscus and get the values
# needed to populate the below information.
# https://www.joelnitta.com/posts/2021-11-24_using-giscus/
[params.giscus]
  # repo = "github-user/github-repo" # Entering repo will enable giscus
  repo_id = "enter-repo-id"
  category = "Comments"
  category_id = "enter-category-id"
  mapping = "pathname"
  reactions-enabled = "1"
  emit-metadata = "0"
  theme = "light"
  lang = "en"
```

This connects the information placed in the config file with the information that the comments.html template needs to work.
This way, users of my theme need only fill in the correct information in the config.toml to get giscus working on their blog.

# Using a custom theme.

Giscus also allows users to specify a custom theme to the comment section. I still want to tweak mine a little, but adding a custom theme was really a matter of making a css file that the “theme” part of the script wl poing to, rather than a pre-defined theme (like the default “light” theme).

In my project folder I have extra css files that customise my website as I want it to look. Such files should always be placed in the `assets` folder of a hugo site. I added another file there `assets/css/giscus.css`, and entered the following:

``` css
/*! Custom CSS */
.gsc-comments > .gsc-comment-box {
  order: 2;
  margin-bottom: 1rem;
}

.gsc-comments > .gsc-timeline {
  order: 3;
}

.gsc-timeline {
  flex-direction: column-reverse;
}

.gsc-header {
  padding-bottom: 1rem;
}
```

Then, I needed to change where the `data-theme` portion of the giscus scrit was pointing to. Before it was just specifying “light” theme, and now I wanted it to use a file.
So I changed `data-theme="light"` to `data-theme="css/giscus.css`, my newly created custom css file.

For me, the theme for the giscus section magically tok on most of the colours from my site (because most things seem transparent!), even without specifying any colours in the css.
It looks nice, but I’ll need to figure out how to customize it a little more, right now it fades away a little too much in the background.

You can read more about the custom css options for giscus [on their website](https://github.com/giscus/giscus/blob/main/ADVANCED-USAGE.md#data-theme).
