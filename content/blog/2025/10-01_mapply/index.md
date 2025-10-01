---
title: 'Mapply: When You Need to Iterate Over Multiple Inputs'
author: Dr. Mowinckel
date: '2025-10-01'
categories:
  - apply-series
tags:
  - R
  - apply
slug: mapply
format: hugo-md
summary: >-
  Learn when and how to use mapply for applying functions with multiple varying
  arguments. This guide shows practical examples of processing data when you
  need to pair multiple inputs element-wise.
seo: >-
  Use mapply in R for functions with multiple varying arguments. Learn when
  sapply isn't enough and mapply shines.
---


In [an older post](./blog/2022/lets-get-applying/), I showed the basics of replacing loops with apply functions.
I briefly touched on `mapply` at the end, but it deserves its own explanation because it's incredibly useful once you understand when to reach for it.

> The key difference: `sapply` works with one varying input, `mapply` works with multiple varying inputs that need to be paired up.

## When `sapply` isn't enough

Let's start with a scenario where `sapply` works fine, then see where it breaks down.

Say we want to generate some random samples with different sample sizes:

``` r
sample_sizes <- c(10, 20, 15, 30)
samples <- sapply(
  sample_sizes,
  function(n) rnorm(n, mean = 0, sd = 1),
  simplify = FALSE
)

# Look at the lengths
sapply(samples, length)
```

    [1] 10 20 15 30

This works because we're only varying one thing: the sample size.
The mean and sd stay constant.

But what if we want different means for each sample?

``` r
sample_sizes <- c(10, 20, 15, 30)
means <- c(5, 10, 7, 12)

# This won't work as intended
samples <- sapply(sample_sizes, function(n) rnorm(n, mean = ???, sd = 1))
sapply(samples, mean)
```

We're stuck.
`sapply` can only iterate over one vector at a time.

## Enter mapply

`mapply` is designed exactly for this situation - when you need to pair up multiple vectors element-wise:

``` r
generate_samples <- function(n, mean_val) {
  rnorm(n, mean = mean_val, sd = 1)
}

sample_sizes <- c(10, 20, 15, 30)
means <- c(5, 10, 7, 12)

samples <- mapply(
  generate_samples,
  n = sample_sizes,
  mean_val = means,
  SIMPLIFY = FALSE
)

# Check the means of our samples
sapply(samples, mean)
```

    [1]  5.112995  9.896735  6.904238 12.074860

Perfect!
The first sample has `~10` observations with mean `~5`, the second has `~20` observations with mean `~10`, and so on.
An important thing with `mapply` is that the vectors you pass in must be the same length, as they are paired element-wise.
It will recycle shorter vectors, but that can lead to unexpected results if you're not careful.

``` r
# Only 2 means for 4 sizes
short_means <- c(5, 10)
samples <- mapply(
  generate_samples,
  n = sample_sizes,
  mean_val = short_means,
  SIMPLIFY = FALSE
)
sapply(samples, mean)
```

    [1]  4.880864  9.393517  5.050365 10.164239

You can see that the means are recycled, which may not be what you want.
So it's best to add a check to ensure your vectors are the same length before using `mapply`, if you are getting inputs from elsewhere.

``` r
if (length(sample_sizes) != length(means)) {
  stop("sample_sizes and means must be the same length")
}
```

## A more complex example: Scaling data

Let's work with something more realistic.
Say we have test scores from different classes, and we want to standardize each class separately, but with different target means and standard deviations.

``` r
# Create some test data
set.seed(42)
class_a <- rnorm(25, mean = 75, sd = 10)
class_b <- rnorm(30, mean = 82, sd = 8)
class_c <- rnorm(20, mean = 78, sd = 12)

scores <- list(class_a, class_b, class_c)
class_names <- c("Math", "Science", "English")
scores
```

    [[1]]
     [1] 88.70958 69.35302 78.63128 81.32863 79.04268 73.93875 90.11522 74.05341
     [9] 95.18424 74.37286 88.04870 97.86645 61.11139 72.21211 73.66679 81.35950
    [17] 72.15747 48.43545 50.59533 88.20113 71.93361 57.18692 73.28083 87.14675
    [25] 93.95193

    [[2]]
     [1] 78.55625 79.94184 67.89470 85.68078 76.88004 85.64360 87.63870 90.28083
     [9] 77.12859 86.03964 68.26393 75.72433 75.19274 62.68634 82.28898 83.64799
    [17] 79.11154 88.06531 76.18636 71.05375 85.46254 75.50885 93.55281 78.54843
    [25] 87.24518 84.57540 75.72929 94.60582 87.14319 82.71809

    [[3]]
     [1] 81.31861 86.15147 79.07799 42.08292 81.41860 73.59318 80.22277 84.98188
     [9] 94.79684 69.27250 93.63051 82.03018 90.46207 89.04874 86.65054 65.48257
    [17] 76.91776 85.48222 66.55772 71.48605

``` r
# Look at original means and sds
sapply(scores, mean)
```

    [1] 76.87536 80.76653 79.03326

``` r
sapply(scores, sd)
```

    [1] 13.063647  7.590105 12.118638

Now let's say we want to rescale each class to have specific target means and standard deviations:

``` r
# Math=80, Science=85, English=75
target_means <- c(80, 85, 75)

# Different spreads for each subject
target_sds <- c(5, 8, 10)
```

Here's the scaling function:

``` r
rescale_scores <- function(scores, target_mean, target_sd) {
  # Standardize to mean=0, sd=1
  standardized <- (scores - mean(scores)) / sd(scores)
  standardized * target_sd + target_mean
}
```

Using a loop would mean using a counter to index each vector, and would look like this:

``` r
rescaled_scores <- list()
for (i in seq_along(scores)) {
  rescaled_scores[[i]] <- rescale_scores(
    scores[[i]],
    target_means[i],
    target_sds[i]
  )
}
```

I'll be honest, this isn't too bad.
I've done it plenty of times, especially when the logic is more complex.
But once I got more comfortable creating my own functions, I found `mapply` to be a cleaner solution.
With `mapply`, we can do this cleanly without indexing:

``` r
rescaled_scores <- mapply(
  rescale_scores, # the function you want to apply
  scores = scores, # The varying inputs
  target_mean = target_means,
  target_sd = target_sds,
  SIMPLIFY = FALSE # to keep the output as a list
)

# Check our results
sapply(rescaled_scores, mean)
```

    [1] 80 85 75

``` r
sapply(rescaled_scores, sd)
```

    [1]  5  8 10

Exactly what we wanted!
No indexing, no temporary variables.
It really is a very clean solution.
Another nice thing about it is that since we are not relying in indexing, we can easily change the order of our inputs without breaking anything.

## Adding more arguments

What if we also want to add class identifiers?
We can add more vectors to match:

``` r
rescale_and_label <- function(scores, target_mean, target_sd, class_name) {
  rescaled <- rescale_scores(scores, target_mean, target_sd)
  data.frame(
    score = rescaled,
    class = class_name,
    student_id = seq_along(rescaled)
  )
}

result_data <- mapply(
  rescale_and_label,
  scores = scores,
  target_mean = target_means,
  target_sd = target_sds,
  class_name = class_names,
  SIMPLIFY = FALSE
)

# Combine into one data.frame
final_data <- do.call(rbind, result_data)
head(final_data)
```

         score class student_id
    1 84.52945  Math          1
    2 77.12089  Math          2
    3 80.67206  Math          3
    4 81.70445  Math          4
    5 80.82952  Math          5
    6 78.87604  Math          6

## When you have some constant arguments

Sometimes you have multiple varying inputs AND some constant ones.
That's where `MoreArgs` comes in, which lets you pass a list of constant arguments to your function.
This now becomes very powerful.

``` r
rescale_with_bounds <- function(
  scores,
  target_mean,
  target_sd,
  min_score,
  max_score
) {
  rescaled <- rescale_scores(scores, target_mean, target_sd)
  # Apply bounds
  pmax(min_score, pmin(max_score, rescaled))
}

# All classes have same score bounds
bounded_scores <- mapply(
  rescale_with_bounds,
  scores = scores,
  target_mean = target_means,
  target_sd = target_sds,
  MoreArgs = list(
    min_score = 0,
    max_score = 100
  ),
  SIMPLIFY = FALSE
)

# Check that we don't exceed bounds
sapply(bounded_scores, function(x) c(min = min(x), max = max(x)))
```

            [,1]     [,2]     [,3]
    min 69.11486 65.94341 44.50950
    max 88.03416 99.58667 88.00772

That's it!
You can mix and match varying and constant arguments easily.

## The mapply pattern

I find `mapply` most useful for:

1.  **Simulation studies** - varying multiple parameters simultaneously  
2.  **Data processing** - when different groups need different treatments  
3.  **Modeling** - fitting the same model type with different parameters

The pattern is always:

1.  Write a function that takes multiple arguments  
2.  Create vectors for each varying argument (same length)  
3.  Use `mapply` to pair them up  
4.  Add any constant arguments via `MoreArgs`

## Tidyverse equivalent

For completeness, the `purrr` equivalent uses `pmap`, which stands for "parallel map".
A map is a function that applies a function to each element of a list or vector, so acts like `lapply` or `sapply`.
The name "map" comes from other functional programming languages, and is therefore a name for this same concept that is more widely used outside of R.
In purrr, there are several types of map functions, which also validates the output type (e.g. `map_dbl` for numeric output, `map_chr` for character output, etc.).
The standard `map` function returns a list, like `lapply`.

As noted in the purrr documentation, "parallel" here does not refer to parallel computing, but rather that multiple inputs are processed together.
To use `pmap`, you need to put your varying inputs into a list, and in standard tidyverse fashion, the input is the first argument (contrary to the applies where it is further down the argument tree).

``` r
library(purrr)

result_data <- list(
  scores = scores,
  target_mean = target_means,
  target_sd = target_sds,
  class_name = class_names
) |>
  pmap(rescale_and_label)
result_data
```

    [[1]]
          score class student_id
    1  84.52945  Math          1
    2  77.12089  Math          2
    3  80.67206  Math          3
    4  81.70445  Math          4
    5  80.82952  Math          5
    6  78.87604  Math          6
    7  85.06744  Math          7
    8  78.91992  Math          8
    9  87.00757  Math          9
    10 79.04219  Math         10
    11 84.27650  Math         11
    12 88.03416  Math         12
    13 73.96647  Math         13
    14 78.21518  Math         14
    15 78.77195  Math         15
    16 81.71627  Math         16
    17 78.19427  Math         17
    18 69.11486  Math         18
    19 69.94154  Math         19
    20 84.33484  Math         20
    21 78.10859  Math         21
    22 72.46441  Math         22
    23 78.62422  Math         23
    24 83.93129  Math         24
    25 86.53591  Math         25

    [[2]]
          score   class student_id
    1  82.67036 Science          1
    2  84.13078 Science          2
    3  71.43304 Science          3
    4  90.17964 Science          4
    5  80.90363 Science          5
    6  90.14045 Science          6
    7  92.24329 Science          7
    8  95.02811 Science          8
    9  81.16560 Science          9
    10 90.55788 Science         10
    11 71.82221 Science         11
    12 79.68550 Science         12
    13 79.12521 Science         13
    14 65.94341 Science         14
    15 86.60467 Science         15
    16 88.03707 Science         16
    17 83.25564 Science         17
    18 92.69294 Science         18
    19 80.17249 Science         19
    20 74.76270 Science         20
    21 89.94962 Science         21
    22 79.45839 Science         22
    23 98.47679 Science         23
    24 82.66212 Science         24
    25 91.82853 Science         25
    26 89.01457 Science         26
    27 79.69073 Science         27
    28 99.58667 Science         28
    29 91.72103 Science         29
    30 87.05695 Science         30

    [[3]]
          score   class student_id
    1  76.88582 English          1
    2  80.87377 English          2
    3  75.03692 English          3
    4  44.50950 English          4
    5  76.96832 English          5
    6  70.51099 English          6
    7  75.98155 English          7
    8  79.90866 English          8
    9  88.00772 English          9
    10 66.94566 English         10
    11 87.04529 English         11
    12 77.47298 English         12
    13 84.43078 English         13
    14 83.26453 English         14
    15 81.28559 English         15
    16 63.81831 English         16
    17 73.25435 English         17
    18 80.32152 English         18
    19 64.70550 English         19
    20 68.77224 English         20

Several things about `pmap` that I like a lot when I don't have to worry about dependencies:

1.  The input is the first argument, which I find more intuitive.  
2.  You can use the pipe operator to build up your inputs, which I find makes it easier to read.  
3.  You can use anonymous functions with the `~` syntax, which I find cleaner for short functions.  
4.  Additional constant arguments can be passed directly in the `pmap` call, without needing a separate `MoreArgs` list.  
5.  You can toggle progress bars with the `.progress` argument, which is nice for long-running tasks.  
6.  You can [easily add parallell processing](https://www.tidyverse.org/blog/2025/07/purrr-1-1-0-parallel/) using the {mirai} package.

Base R `mapply` keeps your dependencies minimal and works everywhere, if that is a concern.
But if you are already using the tidyverse, `pmap` is a great alternative, and in my opinion, is more readable.

## Wrapping up

Think of `mapply` as the tool for when you need to "zip" multiple vectors together and apply a function to each matched set.
If you find yourself writing loops where you're indexing into multiple vectors with the same `i`, that's usually a sign that `mapply` would be cleaner.
