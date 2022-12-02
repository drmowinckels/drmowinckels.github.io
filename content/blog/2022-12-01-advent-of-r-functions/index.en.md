---
title: Advent of R Functions
author: Dr. Mowinckel
date: '2022-12-01'
slug: 2022-12-01-advent-of-r-functions
categories: []
tags:
  - Advent calendar
  - R
  - R functions 2022
image: 'featured.jpg'
---


It is advent!
And we all know by now how much I LOVE advent and Christmas. 
Keeping true to who I am and that I finally have some extra energy for things like this, this advent brings you a series of 24 pieces of code I often use in my work, and that I hope can be of interest and help to you.

## 1<sup>st</sup> of December - Creating a directory
I often find myself doing quite some file handling in my work, often leading to many of the same things happening over and over in slightly different contexts. 
If you try to create files in a directory that does not exists, R will throw an error


```r
penguins <- palmerpenguins::penguins
write.table(penguins, "new_folder/penguins.csv")
```

```
## Warning in file(file, ifelse(append, "a", "w")): cannot open file 'new_folder/
## penguins.csv': No such file or directory
```

```
## Error in file(file, ifelse(append, "a", "w")): cannot open the connection
```

So, I very often have this piece of code in any file-writing function I make to create the folder. 
But R will also throw annoying warnings if the folder already exists, which I also don't like.


```r
dir.create("new_folder") # no warning
dir.create("new_folder") # produces warning
```

```
## Warning in dir.create("new_folder"): 'new_folder' already exists
```



The solution, is to check if the directory already exists, and make it if it does not.



```r
if(!dir.exists("new_folder")) dir.create("new_folder")
```


Actually, I often end up using a little convenience function for this, since I do it quite often.


```r
dir_create <- function(x, ...){
  if(!dir.exists(x)) 
    dir.create(x, recursive = TRUE, ...)
}
dir_create("new_folder")
dir_create("new_folder")
```


Here, I can have a function to easily create new folders, with any extra arguments to `dir.create` passed along using the `...` (ellipsis), and only make the directory if it does not already exist.
This is a staple bit of code for me.
Hope it will help you get your scripts tidier!


## 2<sup>nd</sup> of December - Writing subsetted data to files

I'll continue in the same line as the first day, with working with the file system.
I've shown how I create a utility function to create new directories if they don't exist, and now we want to write files to them!

I'll continue using base-R, as for this first part of the calendar, I am emulating work I do on our offline server where I often struggle with getting dependencies installed in stable ways. 

We have our lovely penguins data set, and I want to save one file per penguin species in the data.table.
That is, I want to split the data.frame into three data.frames each containing only the data from a single penguin species.
Then I want to save each of those to file. 

First we need to split the data set. 
Usually, when not on the server, I'd do some {dplyr} `nest_by` magic, but I cannot in this case.
So we need to deal with what we have.
Neatly, base-R has the `split` function, which does exactly what I want.


```r
penguins |> 
  split(~species)
```

```
## $Adelie
## # A tibble: 152 × 8
##    species island    bill_length_mm bill_depth_mm flipper_…¹ body_…² sex    year
##    <fct>   <fct>              <dbl>         <dbl>      <int>   <int> <fct> <int>
##  1 Adelie  Torgersen           39.1          18.7        181    3750 male   2007
##  2 Adelie  Torgersen           39.5          17.4        186    3800 fema…  2007
##  3 Adelie  Torgersen           40.3          18          195    3250 fema…  2007
##  4 Adelie  Torgersen           NA            NA           NA      NA <NA>   2007
##  5 Adelie  Torgersen           36.7          19.3        193    3450 fema…  2007
##  6 Adelie  Torgersen           39.3          20.6        190    3650 male   2007
##  7 Adelie  Torgersen           38.9          17.8        181    3625 fema…  2007
##  8 Adelie  Torgersen           39.2          19.6        195    4675 male   2007
##  9 Adelie  Torgersen           34.1          18.1        193    3475 <NA>   2007
## 10 Adelie  Torgersen           42            20.2        190    4250 <NA>   2007
## # … with 142 more rows, and abbreviated variable names ¹​flipper_length_mm,
## #   ²​body_mass_g
## 
## $Chinstrap
## # A tibble: 68 × 8
##    species   island bill_length_mm bill_depth_mm flipper_l…¹ body_…² sex    year
##    <fct>     <fct>           <dbl>         <dbl>       <int>   <int> <fct> <int>
##  1 Chinstrap Dream            46.5          17.9         192    3500 fema…  2007
##  2 Chinstrap Dream            50            19.5         196    3900 male   2007
##  3 Chinstrap Dream            51.3          19.2         193    3650 male   2007
##  4 Chinstrap Dream            45.4          18.7         188    3525 fema…  2007
##  5 Chinstrap Dream            52.7          19.8         197    3725 male   2007
##  6 Chinstrap Dream            45.2          17.8         198    3950 fema…  2007
##  7 Chinstrap Dream            46.1          18.2         178    3250 fema…  2007
##  8 Chinstrap Dream            51.3          18.2         197    3750 male   2007
##  9 Chinstrap Dream            46            18.9         195    4150 fema…  2007
## 10 Chinstrap Dream            51.3          19.9         198    3700 male   2007
## # … with 58 more rows, and abbreviated variable names ¹​flipper_length_mm,
## #   ²​body_mass_g
## 
## $Gentoo
## # A tibble: 124 × 8
##    species island bill_length_mm bill_depth_mm flipper_len…¹ body_…² sex    year
##    <fct>   <fct>           <dbl>         <dbl>         <int>   <int> <fct> <int>
##  1 Gentoo  Biscoe           46.1          13.2           211    4500 fema…  2007
##  2 Gentoo  Biscoe           50            16.3           230    5700 male   2007
##  3 Gentoo  Biscoe           48.7          14.1           210    4450 fema…  2007
##  4 Gentoo  Biscoe           50            15.2           218    5700 male   2007
##  5 Gentoo  Biscoe           47.6          14.5           215    5400 male   2007
##  6 Gentoo  Biscoe           46.5          13.5           210    4550 fema…  2007
##  7 Gentoo  Biscoe           45.4          14.6           211    4800 fema…  2007
##  8 Gentoo  Biscoe           46.7          15.3           219    5200 male   2007
##  9 Gentoo  Biscoe           43.3          13.4           209    4400 fema…  2007
## 10 Gentoo  Biscoe           46.8          15.4           215    5150 male   2007
## # … with 114 more rows, and abbreviated variable names ¹​flipper_length_mm,
## #   ²​body_mass_g
```
Out comes three data.frames with each data set in them, preserved in a list. 
Awesome!

Then, I need to save them to files. 
I will use `lapply` (list apply) to loop through the list, and save each file.
I send each data set into the lapply function, giving them the placeholder name `x`.
So, `x` will be one data.frame. 
Then I write the csv to file, using the species name.


```r
penguins |> 
  split(~species) |> 
  lapply(function(x){
    write.csv(x, paste0(unique(x$species), ".csv"), row.names = FALSE)
  })
```

```
## $Adelie
## NULL
## 
## $Chinstrap
## NULL
## 
## $Gentoo
## NULL
```

```r
list.files(".", "csv")
```

```
## [1] "Adelie.csv"    "Chinstrap.csv" "Gentoo.csv"
```

Ok. so the files are there, but I am not super happy with this. 
I don't like capitalisation in my file names, and they are not in a folder. 
I also cannot easily change the grouping factor, if I for instance wanted to save by island or sex in stead.
To do that, I'll construct a function that will do my work for me in a standardised way.
It's going to be quite a doozy, but its such a convenient thing for me!



```r
save_files <- function(data, group, directory) {
  # get column name from formula
  colname <- as.character(group)[-1]
  
  # Create directory
  dir <- file.path(directory, colname)
  dir_create(dir)

  # split the data
  tmp <- split(data, group)

  # internal file name constructor
  .filename <- function(data){
    # get unique value, make lower, append .csv
    g <- unique(data[[colname]]) |> 
      tolower() |> 
      paste0(".csv")
    # construct file path with directory, grouping and dataset
    file.path(dir, g)
  }
  
  # apply file names to the split data
  # makes `sapply` give a really nice output
  names(tmp) <- sapply(tmp, .filename)

  # write the filees!
  sapply(tmp, function(x) {
    write.csv(x,
              .filename(x),
              row.names = FALSE)
  })
}
save_files(penguins, ~species, "csvs")
```

```
## $`csvs/species/adelie.csv`
## NULL
## 
## $`csvs/species/chinstrap.csv`
## NULL
## 
## $`csvs/species/gentoo.csv`
## NULL
```

```r
save_files(penguins, ~island, "csvs")
```

```
## $`csvs/island/biscoe.csv`
## NULL
## 
## $`csvs/island/dream.csv`
## NULL
## 
## $`csvs/island/torgersen.csv`
## NULL
```

```r
list.files("csvs", recursive = TRUE)
```

```
## [1] "island/biscoe.csv"     "island/dream.csv"      "island/torgersen.csv" 
## [4] "species/adelie.csv"    "species/chinstrap.csv" "species/gentoo.csv"
```


See? 
Now we have everything I wanted. 
The files are all in neatly ordered folders, named neatly, and it just makes my organisatory heart happy!
Admittedly, it is kind of a large function, but it is also very convenient for quite some stuff I do.
For instance, while I regularly run analyses on complete datasets, some times I need to get some things done in subgroups of the data to inspect possible origins of effects that can be hard when I look at the entire data as a whole. 
And many of the analyses I run are heavy computing, so I need to prepare files to send analyses to a computing cluster. 

This tidbit of code is nice to have to create these datafiles I need.

<!-- Let's kick it off by a piece of code that I often use on our offline server, where we store and use sensitive human data.  -->
<!-- Here, I have less options in terms of R packages, so I often rely on base-R funcitonality, to avoid issues with compilers not being equal between my workflows.  -->
<!-- And if you have no idea what I just said, ignore it, be happy you don't need to deal with stuff like that! -->

<!-- Ok, so we kick of with being able to easily split a data.frame by some grouping and save them into separate files. -->
<!-- I'll first show you the entire code, then we will start breaking it down. -->

<!-- ```{r} -->
<!-- penguins <- palmerpenguins::penguins -->
<!-- save_files <- function(data, group, directory) { -->
<!--   # Create directory to place files in, called "csvs" -->
<!--   if(!dir.exists(directory)) dir.create(directory) -->

<!--   tmp <- palmerpenguins::penguins |> -->
<!--     split(group) -->

<!--   .filename <- function(data){ -->
<!--     species <- paste0(unique(data$species), ".csv") -->
<!--     species <- tolower(species) -->
<!--     file.path(directory, species) -->
<!--   } -->
<!--   names(tmp) <- sapply(tmp, .filename) -->

<!--   sapply(tmp, function(x) { -->
<!--     write.csv(x, -->
<!--               .filename(x), -->
<!--               row.names = FALSE) -->
<!--   }) -->
<!-- } -->
<!-- save_files(penguins, ~species, "csvs") -->

<!-- # Check that they are there -->
<!-- list.files("csvs", full.names = TRUE) -->
<!-- ``` -->

<!-- ### Splitting into several data.frames -->
<!-- Let start by how I'm breaking up the penguins dataset into several data.frames -->

<!-- ```{r} -->
<!-- penguins |>  -->
<!--   split(~species) -->
<!-- ``` -->

<!-- The `split()` function is super neat for things like this.  -->
<!-- When done on a data.frame, you can provide a formula to split by variables in your data.  -->
<!-- In this case, we are telling it to split by species, and therefore it produces one data.frame per species in the original dataset, each data.frame reduced to rows only containing that species.  -->
<!-- Really neat, if you ask me! -->


