---
doi: 10.5281/zenodo.13273504
title: Changing your Blogdown Workflow
author: Dr. Mowinckel
date: '2020-05-25'
categories: []
tags:
  - R
  - hugo
  - blogdown
output:
  html_document:
    keep_md: yes
draft: false
image: "lucille_sassy.gif"
slug: "changing-you-blogdown-workflow"
aliases:
  - '/blog/2020-05-25-changing-you-blogdown-workflow'
summary: Updating my hugo setup on netlify took over a year of delays due to complexities. After extensive work, I transitioned from knitting `.html` to `.md`, fixed theme issues, and resolved netlify CSS problems. Follow my step-by-step guide to smoothly update your blogdown website. Learn to make use of hugo's page bundles, adjust configurations, and ensure seamless rendering both locally and on netlify. This guide addresses key changes you might face, from altering your workflow to understanding theme changes and troubleshooting rendering issues.
seo: Follow my guide to update blogdown from knitting `.html` to `.md`, fix theme issues, and ensure proper CSS rendering on netlify.
---



For more than a year now I have avoided updating my hugo-version on netlify and updating my theme because there was _a lot_ of work that needed to be done to make that happen. 
I did not really have enough time or motivation to actually get it sorted, as it involved understanding theme changes and hugo changes. 

But last week I finally got working on it, and decided I would not stop until I had it done. 
I hoped this would take a day or two, my [toggl](https://toggl.com/) tells me I did almost 5 days of work to get it working.
OK, some of that was also preparing for contributing some changes to my theme, but still.
I hit _a lot_ of extra hurdles, and I'll try to document them all here, so that others might benefit from my struggles and avoid having to spend so much time in getting their blogdown updated.

**Changes I did in short:**   
1. alter my workflow from knitting `.html` to knitting `.md`  
2. locate theme changes breaking the webpage  
3. figuring out why local rendering was fine, while netlify was not implementing css  

These things might not look like much, but figuring out what needed to be done was quite a toil.
So let's get to it!

## 1. alter my workflow from knitting `.html` to knitting `.md` 

![](https://media.giphy.com/media/3o7TKtZ6eYyq506j04/giphy.gif)<!-- -->

This was a major change to how I work. 
After discussions with [Maëlle Salmon](https://twitter.com/ma_salmon) and [Steph Locke](https://twitter.com/TheStephLocke) about the caveats of blogdown rendering directly from `.Rmd` to `.html`, I decided to follow their advice and change the way I make content for my webpage. 

To be concise, blogdown is usually used with [go hugo](https://gohugo.io/) a static webpage builder. 
Hugo renders markdown `.md` to `html` (plus some extra things, we will see some later), and basically sets up all the internal logics of your webpage as long as you theme is correctly set up. 
This is super convenient, and is one of the things that makes it popular. 
Blogdown renders directly from `.Rmd` to `.html`, meaning it circumvents hugo's processing of `md` to `html`. 
This can cause some unwanted issues when rendering pages, all depending on your theme.
It can also make it difficult to maintain your webpage over time, as small changes might prompt or make it necessary to re-knit old posts, and we all know how difficult it can be with R-versions and package-versions over time. 

Furthermore, blogdown does not take _real_ advantage of hugo [page bundles](https://gohugo.io/content-management/page-bundles/).
Page bundles are great as instead of making a single file for a post, you create a `subfolder` for the post (i.e. sub-folder is the posts slug), and the document file is simply called `index.Rmd`. 
Bundles will have all files within the sub-folder copied over to `public` (where hugo by default places all rendered website), meaning your post can work with relative file paths. 
Previously, you needed to have an awkward workflow having (for instance) data or image files in a location for your `.Rmd` to access, and _also_ in `static` for it to be copied over to the website resources. 
such a pain, using bundles makes all this a thing of the past!

Lastly, in my case my theme relied on using the code fencing in the `md`s (i.e. the back-ticks used in `md`'s to indicate that there piece of text is code) for it to format the code with code highlighting. 
Because blogdown renders directly to `html` there is not code fencing and all my code just looked like the normal blog text. 
This made for pretty hard to read posts.

function(s) s*100

That does not look as good or understandable as


```r
function(s) s*100
```

I was not the only blogdowner using this theme that met this [issue](https://github.com/victoriadrake/hugo-theme-introduction/issues/127). 
To get syntax highlighting working again, meant circumventing blogdowns html, and letting hugo do the `md -> html`

So what we are trying to do is to make `Rmd -> md` in R, so we can work with code chunks, then let hugo do the `md -> html`.

### So what does the change _mean_?

a) start using page bundles  
b) force `.Rmd` to knit to `.md`  
c) stop using `blogdown::serve_site()`  
d) apply small changes to `config.toml`  

Both of these are things we want to do to make sure that we make `.md`'s that hugo will convert to `.html` rather than having blogdown make the `.html`. 
This means we take advantage of lots of brilliant hugo features, that we are missing out of when using blogdown. 

#### a) start using page bundles  
I've already hinted as some of the brilliance of page bundles, but a great explanation of it can be found in [Alison Hill's post on page bundles](https://alison.rbind.io/post/2019-02-21-hugo-page-bundles/), where also I got the information on how to switch to page bundles.

To enable page bundles for blogdown you need to do some alteration in your `.Rprofile`, so that when you start a new post through the addin some information is already pre-chosen for you. 
That way you won't need to set it _each time_ your self. 


```r
# install.packages("usethis") 
usethis::edit_r_profile(scope = "project")
```

Mine looks like so: 


```r
# in .Rprofile of the website project
if (file.exists("~/.Rprofile")) {
  base::sys.source("~/.Rprofile", envir = environment())
}

options(blogdown.new_bundle = TRUE,        # force making page bundle (i.e folder instead of single file)
        blogdown.author = "Dr. Mowinckel", # Who the author of posts is
        blogdown.ext = '.Rmd',             # File extension for posts
        blogdown.subdir	 = "blog")         # subfolder for posts to be placed in

# Make sure to end the file in an empty line
```

You'll need to restart R for the profile to be implemented, and from then on you will be working with page bundles instead of single files. 
Just put your data and extra images, whatever you need, inside the post folder and they will be ported together with the post it self.

**What about all my old posts**?
Good question. 
In my case I needed to re-knit everything, so that I would get the files created correctly for the bundle.
Thankfully last year was unfruitful blog-wise due to a pretty abyssal personal year.
So the poor blogging was a saviour when doing this, as there was not too much to redo.

Before going through each individual post and making sure it was knitting as expected, I prepared things for bundling using a bash loop.


```bash
cd content/blog

for f in $(ls *Rmd); do     # loop through all Rmd
  mkdir -p ${f%.*}/;        # takes way the extension, and makes the folder
  mv $f ${f%.*}/index.Rmd;  # moved file into folder and renames it to index.Rmd
done
```

Now all folders and files were placed in correct bundles.
I "just" had to go through each and make sure I could knit them, while also applying **b)** below.

#### b) force `.Rmd` to knit to `.md`  

Second thing is to make sure you get an `.md` file of your post. 
Blogdown actually does render an `.md` before rendering the `.html` but that intermediary file is discarded once the `.html` is done.
We want to keep it, and thankfully we can tell blogdown to _not_ delete it. 

in the `yaml` of the post, you should replace `output: html_document` with:


```yaml
output:
  html_document:
    keep_md: yes
```

This will make the `md` remain after the `html` is rendered. 

Since we want this to happen to every post we make, we should make sure it ends up in each yaml.
To do so we should alter or create an archetype for the blogpost. 

Alison has also written a great post about [hugo archetypes](https://alison.rbind.io/post/2019-02-19-hugo-archetypes/), where you can get some great information about it.
Archetypes depend on your theme, so really you should look at the archetypes already existing in your theme and see what your options are. 

In this case, we are adding something to the archetype which does not already exist, we want to add the yaml bit above, so that is ends up in every new post. 

If your project does not already have an `archetypes` folder, make one, and create a file within that folder again with the name of your archetype.
You can have several archetypes, maybe you have a series of posts with some specific yaml content or the like, and you should therefore name them something that makes it obvious to you what the archetype contains. 


In my archetype for blogpost, it looks like so:

```

```

where I have made sure that I am the author, that date and title are auto-filled, and a reminder to me to add an `image` for my post, which is important to the adjustment I made to my theme (the grid of posts with the images). 
I'll get to `always_allow_html: true` later.

Notice also I have added the snippet of `yaml` from above. 
This means that every post based on this archetype will have a yaml containing the information I need to make sure it is keeping the `md` made. 


#### c) stop using `blogdown::serve_site()`  

now, we need to stop using `blogdown::serve_site()` because it messes up with the above workflow. 
If you have knit an `.Rmd` before you will have noticed that it makes a folder called `[title]_files/`. 
In this folder, all images, widgets etc. from your code chunks in the `.Rmd` are stored, so that the end document has access to what the code has made. 
Blogdown has a pipeline that takes this folder, renames it and places in static, and also alters come pieces in the `html` to access the files from this renames and relocated folder. 
We don't want this any more. 
Since we are bundling the page, the folder made for the post is within the bundled folder, meaning it will be ported with all other files and all paths are already working. 
If you run `blogdown::serve_site()` it will mess up the nice changes we have made!

The new way I work now is that I run `hugo serve` in the terminal tab of Rstudio,


```bash
hugo serve
```
```
Watching for changes in /Users/athanasm/R-stuff/DrMowinckels/{archetypes,assets,content,i18n,layouts,static,themes}
Watching for config changes in /Users/athanasm/R-stuff/DrMowinckels/config.toml
Environment: "development"
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

Then I can have the `http://localhost:1313/` page open in my browser, to watch the changes I make to my posts render. 
In Rstudio, I work with the `.Rmd` files, and when I want to see how things look, I render the page (i.e. knit it with `cmd/ctrl`+ `shift` `k`). 
After the page knits, the changes will appear in the browser. 

I find this to be just as convenient as before, actually a little more convenient that `serve_site`, because it will not do loops of doom when something is wrong in the code chunks, it will just fail to knit, and I can see the error message clearly. 


#### d) apply small changes to `config.toml` 

If you already have a blogdown page, or have started tinkering with one, you will have seen the `config.toml` already.
It is the main source for easily changing certain parameters for your page, personalizing it.
When you start a webpage using blogdown, this file will already have some small changes to it, so that it works well with blogdown.
If you change your workflow like I have, you will need to do some more changes.

The `ignoreFiles` list must be expanded. 
Because our posts are making `html` we have to tell hugo to ignore them, or else they will prevent hugo from turning the  `md`'s to `html`!
Hugo is smart, it will not render something already rendered, but in our case we want it to!
Since our posts are bundled we add `index\\.html` to the ignore list, and then it will not port those with the bundles pages, leaving the rendering to hugo. 

You might also need to add some more, depending on your theme and other pages. 
In my case, I want hugo to ignore the `about.html` also, to ignore some files in the static folder if they are made (i.e. this would happen if I ran serve_site by accident), and to ignore the `README` files which are just repository information. 

```
ignoreFiles = ["\\.Rmd$", "\\.Rmarkdown$", "_cache$", "index\\.html", "about\\.html", "static/blog/\\*_files/", "README"] 
```

Another thing for the toml is to make sure that html within the `md`s are rendered. 
By default, hugo will not render things written in html.
While plain markdown (`md`) does render it, hugo will omit it.

If you look into the `html` made by hugo, you will suddenly see a bit looking like this:


```html
<!-- raw html omitted -->
```

This was madness to me. I had no idea where this was coming from.
I first thought it was a blogdown thing, and was frantically searching around in blogdown forums and github issues to figure it out.
I found many people saying I needed `always_allow_html: true` in the yaml to make it work.
Which I did, and it did not really work, I say really because it worked for most but not all cases (I could not get html widgets to work).

Then i finally understood it was hugo!
In addition to adding `always_allow_html: true` to the yaml of the post (which is why it is now in my archetype), I also needed hugo to compile in a specific way!
I needed to tell hugo which markup (hugo's name for markdown) handler to use!
I found [this post](https://jdhao.github.io/2019/12/29/hugo_html_not_shown/) on jdhaos blog on this exact issue.
In my `config.toml` I added:


```toml
[markup]
  defaultMarkdownHandler = "blackfriday"
```

and presto! site was also rendering html content and widgets!

![](https://media.giphy.com/media/l8XYZYdlOHSrS/giphy.gif)<!-- -->

## 2. locate theme changes breaking the webpage  
 
Then once I had that in place, I needed to figure out what in my theme had changed, to work with newer hugo.
This was a bit of a pain, a lot of internal logic in my theme had changed, and I needed to find them to get it fixed.
One main thing was that projects, blog etc. were altered to work with page bundles. Once I understood this it became more clear what I needed to do.
Rather than have `content/projects/ggseg.Rmd` I needed to have `content/projects/ggseg/index.Rmd` just like the blogposts.
I did this for my projects, but they were still not displaying.

Then I realised that my theme needed another special index file within `contect/projects` for it to be rendered on the home page:

`content/projects/_index.Rmd`

This contains minimal information in my case:

```

Projects featured here are R-package development.
While I am a scientist and have lost of research projects ongoing, here I'd rather showcase the wonderful world of development I have started exploring.
```

This was also necessary for `contents/blog`. Once those were in place, the main bulk of my page was working again.
The remainder is very theme specific and a result of me tweaking my theme a lot within the `layouts` folder. 
I don't recommend doing many `layouts` changes, keep them minimal. In the new version I have now I have few extra layouts.

## 3. figuring out why local rendering was fine, while netlify was not implementing css  

After all this, `hudo serve` was rendering fine locally, and I started pushing a development branch to github so I could preview it on netlify.
Thank you for this option!
Again, Alison Hill has an [amazing post](https://alison.rbind.io/post/2019-03-04-hugo-troubleshooting/)  on troubleshooting your build.
I was seeing the problem she points to in #2, my page on netlify was not implementing the css, making the page look like some joke of a webpage from the early 90s (sans colours).
I tried everything in that post, to no avail. 
My css was not being applied.

[Maëlle Salmon](https://twitter.com/ma_salmon)  to the rescue again, telling me to have a look in my developers console. 
I am no developer, at least I don't' think of myself as one, so I forget about this. 
In the rendered netlify page, I right clicked, chose `Inspect` and in the pane that opened chose the `console`. 
I have used the `elements` page a lot, to figure out where I could tweak my css to look like I wanted, and do find where other issues might arise, but I've not really ever used the console!

and in the console was this beauty of an error:
```
blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource
```

I had (and still have) no idea what that meant, but goggling an error is easy, so I did.
And up popped [this post](https://community.netlify.com/t/access-control-allow-origin-policy/1813) on the netlify forums providing an answer.
Put a bit of information in your `netlify.toml`(not the `config.toml`!):

```
[[headers]]
  for = "/*"
  [headers.values]
    Access-Control-Allow-Origin = "*"
```

I'm really unsure what it does, or why it is needed. 
I know quite some bloggers using blogdown, hugo and netlify that have not had this issue. 
If you encounter it, I hope this pops up for you and you get it solved!

## Webpage updated!

Then finally, the webpage was up and running again.
On a newer hugo, with an updated theme, and new theme tweaks I'm really fond of.

![](lucille_sassy.gif)<!-- -->

In the future, perhaps we don't need to do a lot of this cumbersome stuff, if [hugodown](https://github.com/r-lib/hugodown) gets developed and matures. I have high hopes for this package!
