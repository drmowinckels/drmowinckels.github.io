---
doi: 10.5281/zenodo.13273516
title: External Images to Heatplots
author: Dr. Mowinckel
date: '2021-04-02'
draft: true
categories: []
tags:
  - R
  - plot
slug: "external-images-to-heatplots"
aliases:
  - '/blog/2021-04-02-external-images-to-heatplots'
summary: Enhance your ggplot heatmaps with images using the {ggimage} package. This guide explores adding neuroimaging pictures to heatplots, replacing tedious custom annotations with a more efficient method. Learn how to integrate {ggimage} to visualize correlation matrices alongside network images.
seo: Improve your ggplot heatmaps with images using {ggimage} in R. Add neuroimaging pictures to heatplots for better visualization.
---

I've written posts before about adding images to ggplot, but in those cases I used the `annotate_custom` function, and loops. This procedure works pretty well, and its been a life saver for me in many places where I do this sort of plotting.

But there is a better way! I had vaguely seen something about a {ggimage} package around, but it was not until I saw it on Thomas Mock's [The Mockup Blog](https://themockup.blog/posts/2020-10-11-embedding-images-in-ggplot/) that I saw how cool it was! 

And so, I thought we'd have a look at using that now, for adding neuroimaging pictures to heatplots!

In neuroimaging, heatplots are quite common. We use them often to show the correlation between networks, or even the correlations between network correlations.


```r
library(ggimage)
```

```
## Loading required package: ggplot2
```

```r
library(tidyverse)
```

```
## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──
```

```
## ✓ tibble  3.1.5     ✓ dplyr   1.0.7
## ✓ tidyr   1.1.4     ✓ stringr 1.4.0
## ✓ readr   1.4.0     ✓ forcats 0.5.1
## ✓ purrr   0.3.4
```

```
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## x dplyr::filter() masks stats::filter()
## x dplyr::lag()    masks stats::lag()
```

```r
# I'm just making up some mock data to make the correlation matrix
mat <- tibble(
  network_01 = rnorm(100),
  network_02 = rnorm(100, mean = 300, sd = 66 ),
  network_03 = rnorm(100, mean = 3, sd = .5),
  network_04 = rnorm(100, mean = -4, sd = 100 )
)

# make correlation matrix
cor_dt <- cor(mat)

# Make correlation matrix into images frame and start adding variables
dt <- as.data.frame(cor_dt) %>% 
  
  # turn rownames into a column in the images
  rownames_to_column(var = "nw_1") %>%
  
  # pivot data longer so its in a ggplot compatible format
  pivot_longer(starts_with("network"),
               names_to = "nw_2",
               values_to = "cor") %>% 
  
  # cleanup names a little
  mutate(
    across(starts_with("nw"), 
           ~ str_remove(.x, "network_")),
    across(starts_with("nw"), 
           ~ str_pad(.x, 4, "left", "0")),
  ) 
# Create a tibble containing the image paths and short names
images = tibble(
  image = list.files("brainSlices/single", 
                     full.names = TRUE)
) %>% 
  mutate(
    nw = gsub("[a-zA-Z]|[[:punct:]]","", image),
    image = normalizePath(image),
    x = row_number()-1,
    y = row_number()-1
  ) %>% 
  filter(nw %in% dt$nw_1) %>% 
  pivot_longer(all_of(c("x", "y")),
               names_to = "axis")

# Because we want to make a specific section indicating network through colour,
# We also need to make this second images frame with _only_ the network images.
# This is because the correlation matrix has a different shape than what we use for other graphs

ggplot(data = images) + 
  geom_tile(
    data = dt, 
    aes(nw_1, nw_2, fill = cor),
    size = 5) +
  geom_segment(
    size = 30,
    alpha = .6,
    show.legend = FALSE,
    aes(
      x    = if_else(axis == "x", value-.4, 0), 
      xend = if_else(axis == "x", value+.4, 0),
      y    = if_else(axis == "y", value-.4, -.12), 
      yend = if_else(axis == "y", value+.4, -.12),
      colour = nw
    )
  ) +
  geom_image(
    aes(image = image,
        x = if_else(axis == "x", value, 0), 
        y = if_else(axis == "y", value, 0)),
    size = .1,
    by = "width", 
    asp = 1.2
  ) + 
  coord_cartesian(
    xlim = c(0.2, nrow(images)/2),
    ylim = c(0.2, nrow(images)/2)
  ) +
  scale_fill_continuous(na.value = "transparent") +
  theme_minimal() +
  labs(x = "", y = "",
       fill = "correlation",
       colour = "network") +
  theme(axis.text.y = element_text(angle = 90, hjust = 0.5))
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-1-1.png" width="672" />

