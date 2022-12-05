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
## [1] "Adelie.csv"    "Chinstrap.csv" "csvs"          "Gentoo.csv"
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

## 3<sup>rd</sup> of December - Reading in lots of files

Now that we have managed to create lots of files, based on data groupings, let us also see how we can read them in efficiently.
I've made so many absolutely horrid pipelines to do this, before I figured out this way of doing it.

The pre-requisites for this is that all the files you are reading in all have the same columns, if they don't, the last bit will fail. 



```r
# list all files in the species folder,
# contiaing the ending "csv" and 
# keep the entire relative path.
list.files("csvs/species", "csv$", full.names = TRUE)
```

```
## [1] "csvs/species/adelie.csv"    "csvs/species/chinstrap.csv"
## [3] "csvs/species/gentoo.csv"
```

We have three files, and we want to read the all in, at once and get them into a list.
We've worked with `lapply()` before, and we will again here. 
We will use the list of file paths in lapply, and run the `read.csv` function on them all.
This should give us a list of three data sets.


```r
list.files("csvs/species", "csv$", full.names = TRUE) |> 
  lapply(read.csv)
```

```
## [[1]]
##   species    island bill_length_mm bill_depth_mm flipper_length_mm body_mass_g
## 1  Adelie Torgersen           39.1          18.7               181        3750
## 2  Adelie Torgersen           39.5          17.4               186        3800
## 3  Adelie Torgersen           40.3          18.0               195        3250
##      sex year
## 1   male 2007
## 2 female 2007
## 3 female 2007
##  [ reached 'max' / getOption("max.print") -- omitted 149 rows ]
## 
## [[2]]
##     species island bill_length_mm bill_depth_mm flipper_length_mm body_mass_g
## 1 Chinstrap  Dream           46.5          17.9               192        3500
## 2 Chinstrap  Dream           50.0          19.5               196        3900
## 3 Chinstrap  Dream           51.3          19.2               193        3650
##      sex year
## 1 female 2007
## 2   male 2007
## 3   male 2007
##  [ reached 'max' / getOption("max.print") -- omitted 65 rows ]
## 
## [[3]]
##   species island bill_length_mm bill_depth_mm flipper_length_mm body_mass_g
## 1  Gentoo Biscoe           46.1          13.2               211        4500
## 2  Gentoo Biscoe           50.0          16.3               230        5700
## 3  Gentoo Biscoe           48.7          14.1               210        4450
##      sex year
## 1 female 2007
## 2   male 2007
## 3 female 2007
##  [ reached 'max' / getOption("max.print") -- omitted 121 rows ]
```

Once that is done, we also want to have them all combined into a single data set, i.e. back to our full penguins data set.
To do that, we will use `do.call` and `rbind` to achieve this.
Now, `do.call` is a bit of magic, and I am not entirely sure of what it does in all contexts.
In this context, it will run through the list, and run `rbind` on each data set, so that we get a single one out.


```r
data_list <- list.files("csvs/species", "csv$", full.names = TRUE) |> 
  lapply(read.csv)

do.call(rbind, data_list)
```

```
##   species    island bill_length_mm bill_depth_mm flipper_length_mm body_mass_g
## 1  Adelie Torgersen           39.1          18.7               181        3750
## 2  Adelie Torgersen           39.5          17.4               186        3800
## 3  Adelie Torgersen           40.3          18.0               195        3250
##      sex year
## 1   male 2007
## 2 female 2007
## 3 female 2007
##  [ reached 'max' / getOption("max.print") -- omitted 341 rows ]
```

And now we have our data frame with 344 rows back!
But! Usually, I would want to know _which file each row comes from_.
In the penguins data here, that is not a huge issue, as the species column basically already tells us that.
But there might be lots of other reasons you'd like to know, for instance for debugging the original data (in case there are suspicious entries), or because the source file information is not inherent in the data. 
To do that, we need a little custom function.


```r
merge_files <- function(path, pattern, func = read.csv, ...){
  file_list <- list.files(path, pattern, full.names = TRUE)
  data_list <- lapply(file_list, func, ...)
  # loop through data_list length
  # apply new column with source information
  data_list <- lapply(seq_along(data_list), function(x){
    data_list[[x]]$src <- file_list[x]
    data_list[[x]]
  })
  do.call(rbind, data_list)
}
merged <- merge_files("csvs/species/", "csv")
merged[, c(1:3, 9)]
```

```
##   species    island bill_length_mm                      src
## 1  Adelie Torgersen           39.1 csvs/species//adelie.csv
## 2  Adelie Torgersen           39.5 csvs/species//adelie.csv
## 3  Adelie Torgersen           40.3 csvs/species//adelie.csv
## 4  Adelie Torgersen             NA csvs/species//adelie.csv
## 5  Adelie Torgersen           36.7 csvs/species//adelie.csv
## 6  Adelie Torgersen           39.3 csvs/species//adelie.csv
## 7  Adelie Torgersen           38.9 csvs/species//adelie.csv
##  [ reached 'max' / getOption("max.print") -- omitted 337 rows ]
```

Now we have it all!
The function does quite a lot, in little space, but it also allows quite some customisation.
Like, we can our selves define which `read` function to use, in case the data has a different delimiter than csv, and we can also add any other named argument to that function in our main function call.


## 4<sup>th</sup> of December - fixing column names
I love the [janitor](https://cran.r-project.org/web/packages/janitor/vignettes/janitor.html) package.
It has some cleaning functions for data that just make my world so much easier. 
And while janitor's dependencies are small enough that I can often get it when I need, I still have install issues in certain cases.
In those cases, I need to do some simple steps to improve my data dealings.

Depending on how bad things are, there are some small things we can to to help with column naming.
I'm being a little cheeky an borrowing the example data from janitor.
I will not be able to make it _as neat_ as janitor, but we can make it much better!


```r
test_df <- as.data.frame(matrix(ncol = 6, nrow = 5))
names(test_df) <- c("first_name", "bc", "successful_2009", "repeat_value", "repeat_value", "v6")

# add some data
test_df[1, ] <- c("jane", "JANE", TRUE, NA, 10, NA)
test_df[2, ] <- c("elleven", "011", FALSE, NA, NA, NA)
test_df[3, ] <- c("Henry", "001", NA, NA, NA, NA)
test_df
```

```
##   first_name   bc successful_2009 repeat_value repeat_value   v6
## 1       jane JANE            TRUE         <NA>           10 <NA>
## 2    elleven  011           FALSE         <NA>         <NA> <NA>
## 3      Henry  001            <NA>         <NA>         <NA> <NA>
## 4       <NA> <NA>            <NA>         <NA>         <NA> <NA>
## 5       <NA> <NA>            <NA>         <NA>         <NA> <NA>
```

I think we can all agree this is no fun column names to deal with!
Keeping to base R and some [regular expression](https://www.wikiwand.com/en/Regular_expression) (oh man, I need to google those expressions every time!), we can do a decent bit of cleaning.


```r
clean_names <- function(data, col_prefix = "v"){
  colnames <- names(data)
  
  # turn camelCase to snake_case
  colnames <- gsub("(?![A-Z])(\\G(?!^)|\\b[a-zA-Z][a-z]*)([A-Z][a-z]*|\\d+)", 
       "\\1_\\2", colnames, ignore.case = FALSE, perl = TRUE)
  
  # turn white space into _
  colnames <- gsub(" ", "_", colnames)
  
  # turn to lower case
  colnames <- tolower(colnames)
  
  # remove punctuations except _
  colnames <- gsub("[^a-z0-9_]+", "", colnames)
  
  # trim _ from beginning and end
  colnames <- gsub("^_|_$", "", colnames)

  # add column names to columns missing them
  k <- sapply(match("", colnames), function(x){
    colnames[x] <<- paste0(col_prefix, x)
  })
  
  # apply name changes
  names(data) <- colnames
  
  # returned the renamed data
  data
}
clean_names(test_df)
```

```
##   first_name   bc successful_2009 repeat_value repeat_value  v_6
## 1       jane JANE            TRUE         <NA>           10 <NA>
## 2    elleven  011           FALSE         <NA>         <NA> <NA>
## 3      Henry  001            <NA>         <NA>         <NA> <NA>
## 4       <NA> <NA>            <NA>         <NA>         <NA> <NA>
## 5       <NA> <NA>            <NA>         <NA>         <NA> <NA>
```

Ok, we get pretty close to what I was after.
camelCase turned into snake_case, all lower case, and weird punctuations removed. 
We also manage to name columns without names.
What we miss is that the `á` in "ábc@!*" is removed.
This is because my regular expression is interpreting as a weird special character to remove.
To replace it with an `a` I'd need to get a library that would know how to translate it, and I don't/can't do that. 
So, I'll have to deal with that manually.

## 5<sup>th</sup> of December - removing empty columns

In the type of data I deal with, I do also quite often have to deal with columns containing no data.
Either because the subsetted data are missing a variable, or because a file I read in thinks there is another column, when there truly is not.
I want a nice easy way to deal with that.
Again [janitor](https://cran.r-project.org/web/packages/janitor/vignettes/janitor.html) would be my "online" solution, but when offline, I need to deal in my own code.


```r
test_df
```

```
##   first_name   bc successful_2009 repeat_value repeat_value   v6
## 1       jane JANE            TRUE         <NA>           10 <NA>
## 2    elleven  011           FALSE         <NA>         <NA> <NA>
## 3      Henry  001            <NA>         <NA>         <NA> <NA>
## 4       <NA> <NA>            <NA>         <NA>         <NA> <NA>
## 5       <NA> <NA>            <NA>         <NA>         <NA> <NA>
```

We made a data.frame yesterday with missing values completely from rows 4 and 5, and partial missing data from 2 and 3, while row 1 is the only complete row of data.
And in columns 4 and 6 we are completely missing any data.
We want a simple way to remove all columns that have no information, so we have something simpler to work with.


```r
na_rm_col <- function(data){
  # find columns with only missing values
  idx <- apply(data, 2, function(x) all(is.na(x)))
  
  # keep only columns where there is data
  data[, !idx]
}
test_df <- na_rm_col(test_df)
test_df
```

```
##   first_name   bc successful_2009 repeat_value
## 1       jane JANE            TRUE           10
## 2    elleven  011           FALSE         <NA>
## 3      Henry  001            <NA>         <NA>
## 4       <NA> <NA>            <NA>         <NA>
## 5       <NA> <NA>            <NA>         <NA>
```

With this function we first apply across the columns (apply dimension 2) and check if all values are `NA`. 
If they are, we make sure we don't return a data.frame with those columns.
The function is neither long nor particularly complicated (though `apply` does take a little time to get the hang of), and its super quick!


## 6<sup>th</sup> of December - removing empty rows
Yesterday we removed empty columns, but we might also need to remove empty rows!
Imagine having subsetted columns, and now, lots of your rows actually don't contain meaningful information any more.
No use in having them around, lets just get rid of them!

The code is _remarkably_ similar to yesterdays code,


```r
na_rm_row <- function(data){
  # find columns with only missing values
  idx <- apply(data, 1, function(x) all(is.na(x)))
  
  # keep only rows where there is data
  data[!idx, ]
}
test_df <- na_rm_row(test_df)
test_df
```

```
##   first_name   bc successful_2009 repeat_value
## 1       jane JANE            TRUE           10
## 2    elleven  011           FALSE         <NA>
## 3      Henry  001            <NA>         <NA>
```
We are still using `apply`, but this time along the `1` dimension, which is rows.
And we are using the exact same function inside apply!
Then, we subset the rows with the inverse of that output, giving us only the rows we want.
