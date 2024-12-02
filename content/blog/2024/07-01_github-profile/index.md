---
doi: 10.5281/zenodo.13274239
title: Improving your GitHub Profile
author: Dr. Mowinckel
date: '2024-07-01'
categories: []
tags:
  - r
  - GitHub
  - GitHub Actions
slug: "github-profile"
summary: Improve your GitHub profile with these tips. Learn how to create a repository with your username, add stats, coding skills, preferred IDEs, blog stats, and more. Customize your profile to make it engaging and showcase your skills and interests effectively.
seo: Improve your GitHub profile with these tips. Learn to add GitHub stats, coding skills, preferred IDEs, and blog stats. Customize your profile to showcase your skills and interests.
---

I've been meaning to improve my GitHub profile for a while, but I never got around to it.
I've seen some really cool ones, and I wanted to make one myself.
I finally got around to it, and I'm really happy with the result.

I've written a short tutorial on how I did it, and how you can too.

## What is a GitHub profile?

GitHub profiles are a way to showcase your work on GitHub.
It's a great way to show off your work, and to show your skills.
It's also a great way to learn new skills, and to learn how to use GitHub.


## How do I make a GitHub profile?
To create a GitHub profile, the landing page when you go to your GitHub account, you need to create a repository with the same name as your GitHub username.
For me, that's `drmowinckels`, so I created a repository called `drmowinckels`.
This repository needs to be public, and it needs to have a README.md file.
This README.md file is what will be displayed on your GitHub profile.

## How do I make a cool GitHub profile?
There are many ways to make a cool GitHub profile.
I've seen some really cool ones, and I've seen some really simple ones.
Until recently, mine was one of the simple ones.
I wanted to make a cool one, but I never got around to it.
I finally did, and I'm really happy with the result and would like to share what I've done!

## How I made my cool GitHub profile

My inspiration was coming across a blog post by [Kshyun28](https://dev.to/kshyun28/how-to-make-your-awesome-github-profile-hog) on how to make your GitHub profile awesome.
This popped up in my google chrome news feed, and it got me intrigued!

After that, I kind of went on down a rabbit hole of GitHub profile READMEs and found some really cool ones, based on all the links Kshyun28 provide in their blogpost.

### Github stats

I started by adding my GitHub stats to my profile.
There are several options, but I went with [anuraghazra/github-readme-stats](https://github.com/anuraghazra/github-readme-stats).

It's somewhat customizable, and it's easy to use, customization basically happen by adding query parameters to the URL.

[![GitHub stats](https://github-readme-stats.vercel.app/api?username=drmowinckels&show_icons=true&theme=transparent)](https://github.com/anuraghazra/github-readme-stats)

### Coding languages/skills

I also added a section with my coding languages and skills.
Here, I divided things into three categories:
- Skills I have
- Skills I'm learning
- Skills in the memorybanks

There were a couple of considerations while I was making that.
First, I wanted to make it look nice.
So I made it as a table, with each category its own column.
Now, since this is made in a README.md file, you think I'd make a markdown table.
But that just looked terrible in plain text, and hard to tell which sections belonged to which category.
Since, markdown takes html code, I decided to make it as an html table instead.
This made it easier to see everything that fit in the same cateogry, and it looked a lot nicer.

Second, I wanted to use icons rather than text, as it looks more fun.
I wanted them to similar to each other, adhering to the same style.
This meant I couldn't just google for logos, as they would be in different styles.
There are lots of different icon libraries out there, and I could not find a single one that had all the badges I wanted.
So I ended up using a combination of [Image Shield](https://img.shields.io/badge/) and [Simple Icons](https://simpleicons.org/).

That created the following table:

<table border="1px solid black" style="margin: 5px">
 <tr>
    <td><b style="font-size:30px">I have</b></td>
    <td><b style="font-size:30px">I'm learning</b></td>
    <td><b style="font-size:30px">In the memory banks</b></td>
 </tr>
 <tr>
    <td>
        <img src="https://skillicons.dev/icons?i=r,bash,git,sass,html,css,bootstrap,github,githubactions,md&perline=3" />
    </td>
    <td>
      <img src="https://skillicons.dev/icons?i=js,php,regex&perline=3" />
      <br>
      <img src="https://img.shields.io/badge/Airtable-18BFFF?style=for-the-badge&logo=Airtable&logoColor=white" /><br>
      <img src="https://img.shields.io/badge/Airflow-017CEE?style=for-the-badge&logo=Apache%20Airflow&logoColor=white" /><br>
      <img src="https://img.shields.io/badge/Jenkins-D24939?style=for-the-badge&logo=Jenkins&logoColor=white" /><br>
    </td>
    <td>
      <img src="https://skillicons.dev/icons?i=matlab" />
    </td>
 </tr>
</table>

Downside was that there were badges I could not find in either of the libraries. 
Which sucked, and it means they are missing.
I've opened issue tickets on both libraries, so hopefully they will be added soon.

### The IDE's I prefer
If you've followed me a while, you know I have _opinions_ on IDE's.
So I thought I'd showcase the IDE's I prefer also.

<p align="center">
  <img src="https://img.shields.io/badge/Visual_Studio_Code-0078D4?style=for-the-badge&logo=visual%20studio%20code&logoColor=white" />
  <img src="https://img.shields.io/badge/RStudio-75AADB?style=for-the-badge&logo=RStudio&logoColor=white" />
  <img src="https://img.shields.io/badge/Inkscape-000000?style=for-the-badge&logo=Inkscape&logoColor=white" />
</p>

### What I do in my down time

Now, this again will only pertain to tech stuff I use in my down time.
I love lots of things that are not tech related, but finding badges for those was a bit harder.
So I decided to stick to tech stuff.

<p align="center">
  <img src="https://img.shields.io/badge/Amazon%20Prime-00A8E1?style=for-the-badge&logo=netflix&logoColor=white" />
  <img src="https://img.shields.io/badge/Netflix-E50914?style=for-the-badge&logo=netflix&logoColor=white" />
  <img src="https://img.shields.io/badge/Steam-000000?style=for-the-badge&logo=steam&logoColor=white" />
  <img src="https://img.shields.io/badge/Spotify-1ED760?&style=for-the-badge&logo=spotify&logoColor=white" />
  <img src="https://camo.githubusercontent.com/0ff8e3b5f017aed3d006a903cb50b7d7d6fd1fa6bf8e1c020270c6c7c76d0870/68747470733a2f2f696d672e736869656c64732e696f2f7374617469632f76313f7374796c653d666f722d7468652d6261646765266d6573736167653d4170706c652b545626636f6c6f723d303030303030266c6f676f3d4170706c652b5456266c6f676f436f6c6f723d464646464646266c6162656c3d" />
</p>

But I really would love to add badges for carpentry, ballet, gardening, and cooking.

### Blog post stats

I have a blog on my website, and I wanted to showcase some stats from that.
I already have a [README workflow](https://github.com/drmowinckels/drmowinckels.github.io/blob/main/.github/workflows/render-readme.yml) on my website repository, where a github action renders a `README.Rmd` file to a `README.md` file, which includes some information regarding my blog posts.

Here's where the R stuff comes in!
The Rmd file includes R code that lists blogpost files,
and summarises some stats based on that.
The full file can be seen on [the github repo](https://github.com/drmowinckels/DrMowinckels/blob/main/README.Rmd), but I will highlight the part that is relevant for this post.

````
```{r, echo = FALSE}
posts <- list.files("website/content/blog", 
           "^index.md",
           recursive = TRUE, 
           full.names = TRUE)
posts <- lapply(posts, readLines)

find_key <- function(x, key){
  j <- lapply(x, function(x){
    k <- grep(sprintf("^%s:", key), 
            x, value = TRUE)
    k <- gsub(sprintf("^%s: |'", key), "", k)
    k[1] 
  })
  unlist(j)
}

postdf <- data.frame(
  n = seq_along(posts),
  draft = find_key(posts, "draft") |> 
    grepl(pattern = "true", x = _),
  date = as.Date(find_key(posts, "date")),
  slug = find_key(posts, "slug") |> 
    gsub('\\"', "", x = _),
  title = find_key(posts, "title")
) |> 
  subset(subset = !draft)
postdf$link <-  sprintf("[%s](https://drmowinckels.io/blog/%s)", 
                  postdf$title,
                  postdf$slug)

today    <- Sys.Date()
min_date <- min(postdf$date)
last_post <- as.numeric(max(postdf$date) - today)

postavg <- nrow(postdf)/as.numeric(today - min_date) * 30
postavg <- sprintf("%0.2f", postavg)

postbtw <- as.numeric(today - min_date) / nrow(postdf)
postbtw <- sprintf("%s", round(postbtw, digits = 0))

```


🎉 [DrMowinckels.io](https://drmowinckels.io/) has **`r nrow(postdf)`** posts since **`r min_date`**!

📅 That's a post roughly every **`r postbtw`** days, or about **`r postavg`** posts per month, since `r min_date`.

✍️ The last post was published **`r last_post`** days ago (`r tail(postdf, 1)$link`).

```{r 'plot', echo = FALSE,  fig.width=10, fig.height=2.5}
library(lattice)

postdf$ones <- 1

# Assuming postdf is loaded and has a 'date' column
xyplot(ones ~ date, data = postdf,
       type = 'p',
       pch = "|",  
       cex = 5,   
       col = "cyan3",
       xlab = "",
       ylab = "",
       main = "Published posts",
       scales = list(x = list(cex = 1.4), y = list(draw = FALSE)),
       strip = FALSE,  # Removes strip labels
       axis.line = list(col = "transparent"),
       layout = c(1, 1),  # Single panel
       par.settings = list(
         strip.border = list(col = "transparent"), #making the border transparent
         axis.line = list(col = "transparent") #making the axes transparent
       )
      )

```

<details><summary>📂 Click to expand a full list of posts</summary>

```{r posts-table, results='asis', echo = FALSE}
data.frame(
  Date = rev(postdf$date),
  Title = rev(postdf$link)
) |> 
  knitr::kable()
```
</details>

````




![](github_profile.png)

## Conclusion

You can see my [GitHub profile](https://github.com/drmowinckels) as it's rendered, and look at the [source code](https://github.com/drmowinckels/DrMowinckels/blob/main/README.md?plain=1) for it too.
Since GitHub is such a massive platform, it's a great place to showcase your skills and interests, particularly if you are on the job marked or looking for collaborators.

Have you seen any GitHub profiles with fun and interesting features?
How about your own?
