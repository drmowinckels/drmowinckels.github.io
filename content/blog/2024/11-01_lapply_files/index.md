---
editor_options: 
  markdown: 
    wrap: sentence
format: hugo-md
title: Reading in multiple files without loops
author: Dr. Mowinckel
date: '2024-11-01'
categories: 
  - apply-series
tags:
  - r
slug: lapply-files
image: index.markdown_strict_files/figure-markdown_strict/featured-1.png 
summary: |
  
---

I've written about how to use [apply-functions](/blog/2022/11-07-lets-get-applying) before, and did promise to expand on this topic.
Next on the list is how to use apply to read in multiple files without needing to loop to iterate over the files.

Let me tell you, looking at my old scripts from my PhD I did this in a very very cumbersome way.
To start exploring my journey of reading in files, we'll need some data files to work with.

I'm not gonna explain the code too much, I hope the comments and naming will be fairly straight forward.
The data is of an imaginary experiment on participants, where we have one data set (file) per participant.
The participants are shown on a computer screen a coloured shape, where they have already learned to associate a positive number with the shape, and a negative number with the colour.
Seeing the coloured shape, they are asked to accumulate as many points as possible by rejecting net negative objects and accept net positive objects.
They are asked to be as quick as possible, as we also log in milliseconds how long they take to respond.

``` r
#' Function to generate random data
#' @params n_rows how many rows the data should have
generate_data <- function(n_rows) {
  shapes <- c("square", "triangle", "circle", "rhombus", "diamond", "squiggle")
  shapes <- factor(1:length(shapes), labels = shapes)
  colours <- c("red", "blue", "green", "yellow", "purple", "orange")
  colours <- factor(1:length(colours), labels = colours)

  data <- data.frame(
    # Random age between 18 and 80
    age    = sample(18:80, 1), 
    trial  = 1:n_rows,
    shape  = sample(shapes, n_rows, replace = TRUE),
    colour = sample(colours, n_rows, replace = TRUE)
  )

  data$shape_value  <- as.numeric(data$shape)
  data$colour_value <- as.numeric(data$colour) * -1
  data$value  <- data$shape_value + data$colour_value
  data$choice <- ifelse(0 < rnorm(data$value, mean = 1, sd = 2), "accept", "reject")

  data$accuracy <- dplyr::case_when(
    data$value == 0 ~ 1,
    data$value > 0 & data$choice == "accept" ~ 1,
    data$value < 0 & data$choice == "reject" ~ 1,
    TRUE ~ 0
  )
  data$rt <- ceiling(rgamma(n_rows, shape = 2, scale = 600) + 300 )

  data
}

#' Generate files with data
#' @params i number to append to file name
generate_files <- function(i){
  # Generate a random number of rows between 10 and 15
  num_rows <- sample(75:100, 1)
  
  # Generate the data
  data <- generate_data(num_rows)
  
  # Construct the file name
  file_name <- sprintf(
    "%s/data_%02d.csv", 
    here::here("content/blog/2024/11-01_lapply_files/data"),
    i 
  )
  
  # Write the data to a CSV file, silentlyº
  invisible(write.csv(data, file = file_name, row.names = FALSE))
}

# Set the number of files
num_files <- 5

# iterate through sequence of file numbers to generate the files
sapply(1:num_files, generate_files)
```

    [[1]]
    NULL

    [[2]]
    NULL

    [[3]]
    NULL

    [[4]]
    NULL

    [[5]]
    NULL

Ok, now we have some files to work with!
And notice how I used an `apply` variant to generate the files?
Just to recap, that an `sapply` will iterate through the vector given as the first argument (`1:num_files`), and pass those values to the first argument of the given function (`generate_files`).

``` r
files <- list.files(here::here("content/blog/2024/11-01_lapply_files/data"), full.names = TRUE)
files
```

    [1] "/Users/athanasm/workspace/r-stuff/drmowinckels/content/blog/2024/11-01_lapply_files/data/data_01.csv"
    [2] "/Users/athanasm/workspace/r-stuff/drmowinckels/content/blog/2024/11-01_lapply_files/data/data_02.csv"
    [3] "/Users/athanasm/workspace/r-stuff/drmowinckels/content/blog/2024/11-01_lapply_files/data/data_03.csv"
    [4] "/Users/athanasm/workspace/r-stuff/drmowinckels/content/blog/2024/11-01_lapply_files/data/data_04.csv"
    [5] "/Users/athanasm/workspace/r-stuff/drmowinckels/content/blog/2024/11-01_lapply_files/data/data_05.csv"

## The loopy version

So during my PhD, which was early in my R learning, I would loop through to read in the files and append them together.
Let us start with noticing that in this specific example, the files are organised in the same way.
While containing different number of rows, the columns are named the same and contain the same type of data.
This makes them easy to combine so we can analyse it all together.

So how do we do that?
We want to combine the data **row-wise**, meaning we get a really **tall** dataset.

The way I used to do it with loops, would be something like this:

``` r
# initiate data with only headers
data <- read.csv(files[[1]], nrows=1)
data <- data[0, ]
for(file in files){
  # Read in the file
  tmp <- read.csv(file)
  # Add file name as src column
  tmp$src <- basename(file)
  # Bind rows together
  data <- rbind(data, tmp)
}

# Check thow the data look
str(data)
```

    'data.frame':   438 obs. of  11 variables:
     $ age         : int  47 47 47 47 47 47 47 47 47 47 ...
     $ trial       : int  1 2 3 4 5 6 7 8 9 10 ...
     $ shape       : chr  "triangle" "diamond" "square" "rhombus" ...
     $ colour      : chr  "blue" "green" "blue" "yellow" ...
     $ shape_value : int  2 5 1 4 4 1 5 4 2 6 ...
     $ colour_value: int  -2 -3 -2 -4 -4 -4 -2 -6 -6 -2 ...
     $ value       : int  0 2 -1 0 0 -3 3 -2 -4 4 ...
     $ choice      : chr  "accept" "accept" "accept" "accept" ...
     $ accuracy    : int  1 1 0 1 1 0 0 1 1 1 ...
     $ rt          : int  2049 1606 1122 1801 926 1005 995 1234 1241 3677 ...
     $ src         : chr  "data_01.csv" "data_01.csv" "data_01.csv" "data_01.csv" ...

See how our data is 443 rows and 11 columns?
This means all the data is appended together, exactly what I was wanting.

## The apply version

Let's explore how we can do this with apply!

``` r
data <- lapply(files, read.csv)

# Inspect what the data object contains
str(data)
```

    List of 5
     $ :'data.frame':   96 obs. of  10 variables:
      ..$ age         : int [1:96] 47 47 47 47 47 47 47 47 47 47 ...
      ..$ trial       : int [1:96] 1 2 3 4 5 6 7 8 9 10 ...
      ..$ shape       : chr [1:96] "triangle" "diamond" "square" "rhombus" ...
      ..$ colour      : chr [1:96] "blue" "green" "blue" "yellow" ...
      ..$ shape_value : int [1:96] 2 5 1 4 4 1 5 4 2 6 ...
      ..$ colour_value: int [1:96] -2 -3 -2 -4 -4 -4 -2 -6 -6 -2 ...
      ..$ value       : int [1:96] 0 2 -1 0 0 -3 3 -2 -4 4 ...
      ..$ choice      : chr [1:96] "accept" "accept" "accept" "accept" ...
      ..$ accuracy    : int [1:96] 1 1 0 1 1 0 0 1 1 1 ...
      ..$ rt          : int [1:96] 2049 1606 1122 1801 926 1005 995 1234 1241 3677 ...
     $ :'data.frame':   79 obs. of  10 variables:
      ..$ age         : int [1:79] 23 23 23 23 23 23 23 23 23 23 ...
      ..$ trial       : int [1:79] 1 2 3 4 5 6 7 8 9 10 ...
      ..$ shape       : chr [1:79] "rhombus" "rhombus" "circle" "square" ...
      ..$ colour      : chr [1:79] "purple" "orange" "purple" "yellow" ...
      ..$ shape_value : int [1:79] 4 4 3 1 4 1 2 6 4 6 ...
      ..$ colour_value: int [1:79] -5 -6 -5 -4 -6 -1 -5 -3 -6 -2 ...
      ..$ value       : int [1:79] -1 -2 -2 -3 -2 0 -3 3 -2 4 ...
      ..$ choice      : chr [1:79] "accept" "accept" "accept" "accept" ...
      ..$ accuracy    : int [1:79] 0 0 0 0 0 1 0 1 1 1 ...
      ..$ rt          : int [1:79] 1364 1408 3122 2952 1340 1690 389 5046 689 957 ...
     $ :'data.frame':   75 obs. of  10 variables:
      ..$ age         : int [1:75] 30 30 30 30 30 30 30 30 30 30 ...
      ..$ trial       : int [1:75] 1 2 3 4 5 6 7 8 9 10 ...
      ..$ shape       : chr [1:75] "diamond" "rhombus" "rhombus" "rhombus" ...
      ..$ colour      : chr [1:75] "red" "green" "purple" "purple" ...
      ..$ shape_value : int [1:75] 5 4 4 4 5 1 6 2 3 3 ...
      ..$ colour_value: int [1:75] -1 -3 -5 -5 -4 -1 -4 -6 -1 -6 ...
      ..$ value       : int [1:75] 4 1 -1 -1 1 0 2 -4 2 -3 ...
      ..$ choice      : chr [1:75] "accept" "accept" "accept" "reject" ...
      ..$ accuracy    : int [1:75] 1 1 0 1 1 1 1 1 0 0 ...
      ..$ rt          : int [1:75] 746 1526 672 1003 1547 1037 2878 1561 1711 750 ...
     $ :'data.frame':   100 obs. of  10 variables:
      ..$ age         : int [1:100] 20 20 20 20 20 20 20 20 20 20 ...
      ..$ trial       : int [1:100] 1 2 3 4 5 6 7 8 9 10 ...
      ..$ shape       : chr [1:100] "rhombus" "rhombus" "diamond" "square" ...
      ..$ colour      : chr [1:100] "red" "blue" "yellow" "green" ...
      ..$ shape_value : int [1:100] 4 4 5 1 5 3 6 4 1 5 ...
      ..$ colour_value: int [1:100] -1 -2 -4 -3 -1 -1 -4 -6 -6 -5 ...
      ..$ value       : int [1:100] 3 2 1 -2 4 2 2 -2 -5 0 ...
      ..$ choice      : chr [1:100] "reject" "accept" "accept" "reject" ...
      ..$ accuracy    : int [1:100] 0 1 1 1 1 1 1 1 1 1 ...
      ..$ rt          : int [1:100] 1236 1176 1199 1610 768 1799 1156 1758 1550 847 ...
     $ :'data.frame':   88 obs. of  10 variables:
      ..$ age         : int [1:88] 29 29 29 29 29 29 29 29 29 29 ...
      ..$ trial       : int [1:88] 1 2 3 4 5 6 7 8 9 10 ...
      ..$ shape       : chr [1:88] "rhombus" "squiggle" "rhombus" "triangle" ...
      ..$ colour      : chr [1:88] "red" "red" "purple" "purple" ...
      ..$ shape_value : int [1:88] 4 6 4 2 6 1 1 1 6 5 ...
      ..$ colour_value: int [1:88] -1 -1 -5 -5 -1 -4 -4 -3 -2 -6 ...
      ..$ value       : int [1:88] 3 5 -1 -3 5 -3 -3 -2 4 -1 ...
      ..$ choice      : chr [1:88] "reject" "accept" "accept" "accept" ...
      ..$ accuracy    : int [1:88] 0 1 0 0 0 0 0 0 1 1 ...
      ..$ rt          : int [1:88] 1289 5455 1270 689 514 1541 2682 1330 614 2322 ...

Ok.
So this is very different.
All the data is now in a *list*, where each data set is an element in the list.
So we have a *list* with 5 data.frames in them.
Cool, but how do we combine them?
Keeping to base R, we are going to use a function called `do.call`.
Now, I really struggle to explain `do.call` because it can do several things depending on what function you profide and what the list you give it is.
In all honestly, the only scenario I can use the function is this exact one.
How it works in my head is that it takes all the elements in the list you provide and applies the function you provide it to them all.

``` r
data <- do.call(rbind, data)
str(data)
```

    'data.frame':   438 obs. of  10 variables:
     $ age         : int  47 47 47 47 47 47 47 47 47 47 ...
     $ trial       : int  1 2 3 4 5 6 7 8 9 10 ...
     $ shape       : chr  "triangle" "diamond" "square" "rhombus" ...
     $ colour      : chr  "blue" "green" "blue" "yellow" ...
     $ shape_value : int  2 5 1 4 4 1 5 4 2 6 ...
     $ colour_value: int  -2 -3 -2 -4 -4 -4 -2 -6 -6 -2 ...
     $ value       : int  0 2 -1 0 0 -3 3 -2 -4 4 ...
     $ choice      : chr  "accept" "accept" "accept" "accept" ...
     $ accuracy    : int  1 1 0 1 1 0 0 1 1 1 ...
     $ rt          : int  2049 1606 1122 1801 926 1005 995 1234 1241 3677 ...

The only thing we are missing now, is the src column!
We'll need to do some adaptations to make that work.

``` r
data <- lapply(files, function(x){
  tmp <- read.csv(x)
  tmp$src <- basename(x)
  tmp
})
data <- do.call(rbind, data)
str(data)
```

    'data.frame':   438 obs. of  11 variables:
     $ age         : int  47 47 47 47 47 47 47 47 47 47 ...
     $ trial       : int  1 2 3 4 5 6 7 8 9 10 ...
     $ shape       : chr  "triangle" "diamond" "square" "rhombus" ...
     $ colour      : chr  "blue" "green" "blue" "yellow" ...
     $ shape_value : int  2 5 1 4 4 1 5 4 2 6 ...
     $ colour_value: int  -2 -3 -2 -4 -4 -4 -2 -6 -6 -2 ...
     $ value       : int  0 2 -1 0 0 -3 3 -2 -4 4 ...
     $ choice      : chr  "accept" "accept" "accept" "accept" ...
     $ accuracy    : int  1 1 0 1 1 0 0 1 1 1 ...
     $ rt          : int  2049 1606 1122 1801 926 1005 995 1234 1241 3677 ...
     $ src         : chr  "data_01.csv" "data_01.csv" "data_01.csv" "data_01.csv" ...

Here we did some magick straight in the `lapply`.
Because I wasn't expecting to use the reading function that adds the source file in any other instance, so I defined it straight in the `lapply`.

I think this code is so much more consise and clear than the for loop.
I also found that it iterates faster through a large number of files.

## The really pretty version

While this post is all about the `lapply`, I would be amiss if I didn't mention the most elegant solution of all.
I've mentioned lots of times that I work in an environment where sticking to base R can make life and reproducibility much easier.
But, when I can, I use the tidyverse version, which is just soo good.

``` r
library(readr)
library(dplyr)
```


    Attaching package: 'dplyr'

    The following objects are masked from 'package:stats':

        filter, lag

    The following objects are masked from 'package:base':

        intersect, setdiff, setequal, union

``` r
data <- read_csv(files, id = "src") |>
  mutate(src = basename(src))
```

    Rows: 438 Columns: 11

    ── Column specification ────────────────────────────────────────────────────────
    Delimiter: ","
    chr (3): shape, colour, choice
    dbl (7): age, trial, shape_value, colour_value, value, accuracy, rt

    ℹ Use `spec()` to retrieve the full column specification for this data.
    ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.

``` r
str(data)
```

    tibble [438 × 11] (S3: tbl_df/tbl/data.frame)
     $ src         : chr [1:438] "data_01.csv" "data_01.csv" "data_01.csv" "data_01.csv" ...
     $ age         : num [1:438] 47 47 47 47 47 47 47 47 47 47 ...
     $ trial       : num [1:438] 1 2 3 4 5 6 7 8 9 10 ...
     $ shape       : chr [1:438] "triangle" "diamond" "square" "rhombus" ...
     $ colour      : chr [1:438] "blue" "green" "blue" "yellow" ...
     $ shape_value : num [1:438] 2 5 1 4 4 1 5 4 2 6 ...
     $ colour_value: num [1:438] -2 -3 -2 -4 -4 -4 -2 -6 -6 -2 ...
     $ value       : num [1:438] 0 2 -1 0 0 -3 3 -2 -4 4 ...
     $ choice      : chr [1:438] "accept" "accept" "accept" "accept" ...
     $ accuracy    : num [1:438] 1 1 0 1 1 0 0 1 1 1 ...
     $ rt          : num [1:438] 2049 1606 1122 1801 926 ...

Look at that!
So clean, so fast!
It really is the absolutely best version in my opinion.
But the `lapply` variation I find to be just as satisfying when I need it.

Do you have any particular hacks for reading in this type of data?

``` r
library(ggplot2)
data |>
  ggplot() +
  geom_density(aes(x = rt, group = src, colour = src)) +
  scale_colour_viridis_d() + 
  theme_minimal()
```

<img src="index.markdown_strict_files/figure-markdown_strict/featured-1.png" width="768" />
