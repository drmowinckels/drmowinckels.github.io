---
title: Let's Get Apply'ing
author: Dr. Mowinckel
date: '2022-11-07'
categories: []
tags:
  - R
  - apply
image: blobby_bricks_TradingCard.jpg
slug: "lets-get-applying"
aliases:
  - '/blog/2022-11-07-lets-get-applying'
---

When programming we want to write code that iterates well.
In many languages, we do this through loops.
I was introduced to loops both in MatLab and in the Bourne Again Shell (bash).

So naturaly, when I started working in R, I was looping all over the place. 
Especially before I learned [tidyverse](https://www.tidyverse.org/), I was looping over columns and rows in data.frames to manipulate data into how I needed things to be. 
I was looping through files to read them in, looping through list elements to grab or change their content.

## Looptee loopy loop.

We can have a look an example of what that could look like.
We can base it of the very well-known `mtcars` dataset built-in to R.
We'll only use two columns, just to keep it simple. 


```r
mtcars <- mtcars[, c("cyl", "mpg")]
```

Let's say we want to demean the _miles per gallon_  to the _number of cylinders_ the cars have. 
So we'll mean to calculate the mean `mpg` for the number of cylinders and subtract the mpg from the mean.


```r
for(i in 1:nrow(mtcars)){
  # Number of cylinders for this cars
  cylinders <- mtcars$cyl[i]
  
  # subset data to only cars with that cylinder
  tmp <- subset(mtcars, cyl == cylinders)
  
  # mean of mpg for this cylinder type
  mcyl <- mean(tmp$mpg)
  
  mtcars$mpg_dm[i] <- mtcars$mpg[i] - mcyl
}

# Look at the results
mtcars
```

```
##                     cyl  mpg      mpg_dm
## Mazda RX4             6 21.0  1.25714286
## Mazda RX4 Wag         6 21.0  1.25714286
## Datsun 710            4 22.8 -3.86363636
## Hornet 4 Drive        6 21.4  1.65714286
## Hornet Sportabout     8 18.7  3.60000000
## Valiant               6 18.1 -1.64285714
## Duster 360            8 14.3 -0.80000000
## Merc 240D             4 24.4 -2.26363636
## Merc 230              4 22.8 -3.86363636
## Merc 280              6 19.2 -0.54285714
## Merc 280C             6 17.8 -1.94285714
## Merc 450SE            8 16.4  1.30000000
## Merc 450SL            8 17.3  2.20000000
## Merc 450SLC           8 15.2  0.10000000
## Cadillac Fleetwood    8 10.4 -4.70000000
## Lincoln Continental   8 10.4 -4.70000000
## Chrysler Imperial     8 14.7 -0.40000000
## Fiat 128              4 32.4  5.73636364
## Honda Civic           4 30.4  3.73636364
## Toyota Corolla        4 33.9  7.23636364
## Toyota Corona         4 21.5 -5.16363636
## Dodge Challenger      8 15.5  0.40000000
## AMC Javelin           8 15.2  0.10000000
## Camaro Z28            8 13.3 -1.80000000
## Pontiac Firebird      8 19.2  4.10000000
## Fiat X1-9             4 27.3  0.63636364
## Porsche 914-2         4 26.0 -0.66363636
## Lotus Europa          4 30.4  3.73636364
## Ford Pantera L        8 15.8  0.70000000
## Ferrari Dino          6 19.7 -0.04285714
## Maserati Bora         8 15.0 -0.10000000
## Volvo 142E            4 21.4 -5.26363636
```

This is all well and fine, it's doing what we are after.
But there are some pit-falls.

First of all we are creating some objects in our environment that are not really useful in any other context: `tmp`, `mcyl` and `cylinders`. 
We are indexing with the loop `i` in three places, so if we change the iterating object from `i` to something else (like `k`), we need to change all those places.
The whole loop also has access to the entire global R environment. 
The more complex your script gets, the more complex your loop gets, the more likely something is going to "bleed" into your loop and mess it up.

It's happened to us all!

## Disclaimer

Some of you will be familiar with the [purrr](https://purrr.tidyverse.org/) package, and use that to iterate over in a vectorised manner.
I'm not covering purrr here. 
I very often work on making tools that are in an environment where I can't control C++ compatibility and as such I tend to try to keep dependencies as low as possible.
Keeping with the base R apply's are a way to run vectorised iterations without purrr.

## Applying
We could do an `apply` in stead, which can iterate without an indexing number, when we do it correctly.
But to apply we also need to think `function`al. 

Functional programming means applying a function to every element of a vector (at least that's how my brain thinks of it).
Apply's tend to be faster than loops, but I'm not going to spend time on that aspect here.

Let us start with a simpler example, just to get a feel for it. 
As a stupid thing to do, the data in our mtcars subset into characters with `as.character()`.

We `apply` over the `mtcars` dataset, in a column-wise fashion (`MARGIN = 2` , margin `1` is over rows), and apply the function `as.character` on these vectors.

```r
cars <- apply(mtcars, 
      MARGIN = 2, 
      FUN = as.character)
cars
```

```
##       cyl mpg    mpg_dm               
##  [1,] "6" "21"   "1.25714285714286"   
##  [2,] "6" "21"   "1.25714285714286"   
##  [3,] "4" "22.8" "-3.86363636363636"  
##  [4,] "6" "21.4" "1.65714285714285"   
##  [5,] "8" "18.7" "3.6"                
##  [6,] "6" "18.1" "-1.64285714285714"  
##  [7,] "8" "14.3" "-0.799999999999999" 
##  [8,] "4" "24.4" "-2.26363636363637"  
##  [9,] "4" "22.8" "-3.86363636363636"  
## [10,] "6" "19.2" "-0.542857142857144" 
## [11,] "6" "17.8" "-1.94285714285714"  
## [12,] "8" "16.4" "1.3"                
## [13,] "8" "17.3" "2.2"                
## [14,] "8" "15.2" "0.0999999999999996" 
## [15,] "8" "10.4" "-4.7"               
## [16,] "8" "10.4" "-4.7"               
## [17,] "8" "14.7" "-0.4"               
## [18,] "4" "32.4" "5.73636363636363"   
## [19,] "4" "30.4" "3.73636363636363"   
## [20,] "4" "33.9" "7.23636363636363"   
## [21,] "4" "21.5" "-5.16363636363636"  
## [22,] "8" "15.5" "0.4"                
## [23,] "8" "15.2" "0.0999999999999996" 
## [24,] "8" "13.3" "-1.8"               
## [25,] "8" "19.2" "4.1"                
## [26,] "4" "27.3" "0.636363636363637"  
## [27,] "4" "26"   "-0.663636363636364" 
## [28,] "4" "30.4" "3.73636363636363"   
## [29,] "8" "15.8" "0.700000000000001"  
## [30,] "6" "19.7" "-0.0428571428571445"
## [31,] "8" "15"   "-0.0999999999999996"
## [32,] "4" "21.4" "-5.26363636363637"
```

The output here is not a data.frame, so we would have to make it one later

```r
as.data.frame(cars)
```

```
##    cyl  mpg              mpg_dm
## 1    6   21    1.25714285714286
## 2    6   21    1.25714285714286
## 3    4 22.8   -3.86363636363636
## 4    6 21.4    1.65714285714285
## 5    8 18.7                 3.6
## 6    6 18.1   -1.64285714285714
## 7    8 14.3  -0.799999999999999
## 8    4 24.4   -2.26363636363637
## 9    4 22.8   -3.86363636363636
## 10   6 19.2  -0.542857142857144
## 11   6 17.8   -1.94285714285714
## 12   8 16.4                 1.3
## 13   8 17.3                 2.2
## 14   8 15.2  0.0999999999999996
## 15   8 10.4                -4.7
## 16   8 10.4                -4.7
## 17   8 14.7                -0.4
## 18   4 32.4    5.73636363636363
## 19   4 30.4    3.73636363636363
## 20   4 33.9    7.23636363636363
## 21   4 21.5   -5.16363636363636
## 22   8 15.5                 0.4
## 23   8 15.2  0.0999999999999996
## 24   8 13.3                -1.8
## 25   8 19.2                 4.1
## 26   4 27.3   0.636363636363637
## 27   4   26  -0.663636363636364
## 28   4 30.4    3.73636363636363
## 29   8 15.8   0.700000000000001
## 30   6 19.7 -0.0428571428571445
## 31   8   15 -0.0999999999999996
## 32   4 21.4   -5.26363636363637
```


Doing this in a loop could look like so:


```r
cars2 <- mtcars
for(i in seq_along(mtcars)){
  cars2[[i]] <- as.character(mtcars[[i]])
}
cars2
```

```
##                     cyl  mpg              mpg_dm
## Mazda RX4             6   21    1.25714285714286
## Mazda RX4 Wag         6   21    1.25714285714286
## Datsun 710            4 22.8   -3.86363636363636
## Hornet 4 Drive        6 21.4    1.65714285714285
## Hornet Sportabout     8 18.7                 3.6
## Valiant               6 18.1   -1.64285714285714
## Duster 360            8 14.3  -0.799999999999999
## Merc 240D             4 24.4   -2.26363636363637
## Merc 230              4 22.8   -3.86363636363636
## Merc 280              6 19.2  -0.542857142857144
## Merc 280C             6 17.8   -1.94285714285714
## Merc 450SE            8 16.4                 1.3
## Merc 450SL            8 17.3                 2.2
## Merc 450SLC           8 15.2  0.0999999999999996
## Cadillac Fleetwood    8 10.4                -4.7
## Lincoln Continental   8 10.4                -4.7
## Chrysler Imperial     8 14.7                -0.4
## Fiat 128              4 32.4    5.73636363636363
## Honda Civic           4 30.4    3.73636363636363
## Toyota Corolla        4 33.9    7.23636363636363
## Toyota Corona         4 21.5   -5.16363636363636
## Dodge Challenger      8 15.5                 0.4
## AMC Javelin           8 15.2  0.0999999999999996
## Camaro Z28            8 13.3                -1.8
## Pontiac Firebird      8 19.2                 4.1
## Fiat X1-9             4 27.3   0.636363636363637
## Porsche 914-2         4   26  -0.663636363636364
## Lotus Europa          4 30.4    3.73636363636363
## Ford Pantera L        8 15.8   0.700000000000001
## Ferrari Dino          6 19.7 -0.0428571428571445
## Maserati Bora         8   15 -0.0999999999999996
## Volvo 142E            4 21.4   -5.26363636363637
```

For something like this, the loop seems like a good idea, we do actually keep the rownames too, as we cone the original object first. 
But, the indexing is an issue, the more complex your pipeline gets. 
Avoiding the need of the indexes is a great thing. 

Let us get back to our original example. 
we do quite a lot there, and we need to turn it into a funtion to make it work in apply.

The loop needs two things, the `mtcars` data set it is based on, and the `element` it is demeaning. 
This means we need to make a function with two arguments, one for each.


```r
demean <- function(x, data){
  
}
```


When we create a function, the object name is the function's name, and we use the `function()` function to construct it. 
The arguments of  _your_ function, are added in the function call, and what your function will _do_ with these two arguments, is specified in the following section within the curly braces.


```r
demean <- function(i, data){
  # Number of cylinders for this cars
  cylinders <- data$cyl[i]
  
  # subset data to only cars with that cylinder
  tmp <- subset(data, cyl == cylinders)
  
  # mean of mpg for this cylinder type
  mcyl <- mean(tmp$mpg)
  
  return(data$mpg[i] - mcyl)
}
```

In our code, which was previously a loop, we have changed two things:
1) we no longer refer to `mtcars` directly, but to `data`, which is the input data provided.
2) in stead of assigning the output of the demeaned element into the data again, we return the demeaned value as the output of the function.


```r
demean(1, mtcars)
```

```
## [1] 1.257143
```

```r
demean(10, mtcars)
```

```
## [1] -0.5428571
```

```r
demean(13, mtcars)
```

```
## [1] 2.2
```
 
We can then apply this to all the elements in an apply.


```r
apply(1:nrow(mtcars), demean)
```

```
## Error in match.fun(FUN): argument "FUN" is missing, with no default
```

We get an error!
why?
Because `apply()` expects an data.frame, and a `MARGIN` specification.
We are providing a single vector (of indices), there is no margin to provide and its failing.

We need to switch to another in the apply family to get it working.
We have some choose from, but in this case, we have a single vector , we'll use `sapply` which in my head means "simple apply".


```r
sapply(1:nrow(mtcars), demean)
```

```
## Error in FUN(X[[i]], ...): argument "data" is missing, with no default
```

Its still erroring. This time we have another error.
The error comes from _our_ function, it doesn't know which data to use!
We've given `sapply` the `i` argument, and its missing something for the `data` argument.

In `sapply` the first argument in is the vector your are applying over, the second is the function you are applying, and _after that_ you can provide any single _named_ argument into the applying function.


```r
sapply(1:nrow(mtcars), demean, data = mtcars)
```

```
##  [1]  1.25714286  1.25714286 -3.86363636  1.65714286  3.60000000 -1.64285714
##  [7] -0.80000000 -2.26363636 -3.86363636 -0.54285714 -1.94285714  1.30000000
## [13]  2.20000000  0.10000000 -4.70000000 -4.70000000 -0.40000000  5.73636364
## [19]  3.73636364  7.23636364 -5.16363636  0.40000000  0.10000000 -1.80000000
## [25]  4.10000000  0.63636364 -0.66363636  3.73636364  0.70000000 -0.04285714
## [31] -0.10000000 -5.26363636
```

It works!
Since we are getting back a single vector as long as there are rows in mtcars, we can assign the vector straight into mtcars if we want.


```r
mtcars$dm <- sapply(1:nrow(mtcars), demean, data = mtcars)
mtcars
```

```
##                     cyl  mpg      mpg_dm          dm
## Mazda RX4             6 21.0  1.25714286  1.25714286
## Mazda RX4 Wag         6 21.0  1.25714286  1.25714286
## Datsun 710            4 22.8 -3.86363636 -3.86363636
## Hornet 4 Drive        6 21.4  1.65714286  1.65714286
## Hornet Sportabout     8 18.7  3.60000000  3.60000000
## Valiant               6 18.1 -1.64285714 -1.64285714
## Duster 360            8 14.3 -0.80000000 -0.80000000
## Merc 240D             4 24.4 -2.26363636 -2.26363636
## Merc 230              4 22.8 -3.86363636 -3.86363636
## Merc 280              6 19.2 -0.54285714 -0.54285714
## Merc 280C             6 17.8 -1.94285714 -1.94285714
## Merc 450SE            8 16.4  1.30000000  1.30000000
## Merc 450SL            8 17.3  2.20000000  2.20000000
## Merc 450SLC           8 15.2  0.10000000  0.10000000
## Cadillac Fleetwood    8 10.4 -4.70000000 -4.70000000
## Lincoln Continental   8 10.4 -4.70000000 -4.70000000
## Chrysler Imperial     8 14.7 -0.40000000 -0.40000000
## Fiat 128              4 32.4  5.73636364  5.73636364
## Honda Civic           4 30.4  3.73636364  3.73636364
## Toyota Corolla        4 33.9  7.23636364  7.23636364
## Toyota Corona         4 21.5 -5.16363636 -5.16363636
## Dodge Challenger      8 15.5  0.40000000  0.40000000
## AMC Javelin           8 15.2  0.10000000  0.10000000
## Camaro Z28            8 13.3 -1.80000000 -1.80000000
## Pontiac Firebird      8 19.2  4.10000000  4.10000000
## Fiat X1-9             4 27.3  0.63636364  0.63636364
## Porsche 914-2         4 26.0 -0.66363636 -0.66363636
## Lotus Europa          4 30.4  3.73636364  3.73636364
## Ford Pantera L        8 15.8  0.70000000  0.70000000
## Ferrari Dino          6 19.7 -0.04285714 -0.04285714
## Maserati Bora         8 15.0 -0.10000000 -0.10000000
## Volvo 142E            4 21.4 -5.26363636 -5.26363636
```

And we can see its giving the exact same output as our loop.

Now, lets say we want to do this on just a subsample of mtcars.
We can give sapply the subset, and have it run it on that.


```r
cars <- mtcars[1:20, ]
cars
```

```
##                     cyl  mpg     mpg_dm         dm
## Mazda RX4             6 21.0  1.2571429  1.2571429
## Mazda RX4 Wag         6 21.0  1.2571429  1.2571429
## Datsun 710            4 22.8 -3.8636364 -3.8636364
## Hornet 4 Drive        6 21.4  1.6571429  1.6571429
## Hornet Sportabout     8 18.7  3.6000000  3.6000000
## Valiant               6 18.1 -1.6428571 -1.6428571
## Duster 360            8 14.3 -0.8000000 -0.8000000
## Merc 240D             4 24.4 -2.2636364 -2.2636364
## Merc 230              4 22.8 -3.8636364 -3.8636364
## Merc 280              6 19.2 -0.5428571 -0.5428571
## Merc 280C             6 17.8 -1.9428571 -1.9428571
## Merc 450SE            8 16.4  1.3000000  1.3000000
## Merc 450SL            8 17.3  2.2000000  2.2000000
## Merc 450SLC           8 15.2  0.1000000  0.1000000
## Cadillac Fleetwood    8 10.4 -4.7000000 -4.7000000
## Lincoln Continental   8 10.4 -4.7000000 -4.7000000
## Chrysler Imperial     8 14.7 -0.4000000 -0.4000000
## Fiat 128              4 32.4  5.7363636  5.7363636
## Honda Civic           4 30.4  3.7363636  3.7363636
## Toyota Corolla        4 33.9  7.2363636  7.2363636
```

```r
cars$dm_sub <- sapply(1:nrow(cars), demean, data = cars)
cars
```

```
##                     cyl  mpg     mpg_dm         dm    dm_sub
## Mazda RX4             6 21.0  1.2571429  1.2571429  1.250000
## Mazda RX4 Wag         6 21.0  1.2571429  1.2571429  1.250000
## Datsun 710            4 22.8 -3.8636364 -3.8636364 -4.983333
## Hornet 4 Drive        6 21.4  1.6571429  1.6571429  1.650000
## Hornet Sportabout     8 18.7  3.6000000  3.6000000  4.025000
## Valiant               6 18.1 -1.6428571 -1.6428571 -1.650000
## Duster 360            8 14.3 -0.8000000 -0.8000000 -0.375000
## Merc 240D             4 24.4 -2.2636364 -2.2636364 -3.383333
## Merc 230              4 22.8 -3.8636364 -3.8636364 -4.983333
## Merc 280              6 19.2 -0.5428571 -0.5428571 -0.550000
## Merc 280C             6 17.8 -1.9428571 -1.9428571 -1.950000
## Merc 450SE            8 16.4  1.3000000  1.3000000  1.725000
## Merc 450SL            8 17.3  2.2000000  2.2000000  2.625000
## Merc 450SLC           8 15.2  0.1000000  0.1000000  0.525000
## Cadillac Fleetwood    8 10.4 -4.7000000 -4.7000000 -4.275000
## Lincoln Continental   8 10.4 -4.7000000 -4.7000000 -4.275000
## Chrysler Imperial     8 14.7 -0.4000000 -0.4000000  0.025000
## Fiat 128              4 32.4  5.7363636  5.7363636  4.616667
## Honda Civic           4 30.4  3.7363636  3.7363636  2.616667
## Toyota Corolla        4 33.9  7.2363636  7.2363636  6.116667
```

The `cars` dataset only has 20 rows, and the values in the new demeaned column is different from the other two.
why?
Because we base it on the means in the current data, and those have changed as we reduced the data.

A great bit here is, that we did _not_ copy and paste the loop to run on a new dataset. 
We could use the exact same function in both applies.
This is another way of reducing error.
If you find a bug in your function, you change it once, in one place, and all code using it applies the bug fix.
If you copy and paste your loops, you'll need to fix your bugs in all of them... and I promise you, you won't find them all! (I have been there).

But we are still using indices.
It's not really very neat.
I _do_ some times apply over indices, in very rare cases, but these are mostly cases where I need the value of a previous index to compute what I am after. 
If what you are doing does not depend on a previous iteration, you technically don't need a loop, you want an apply. 

So, why are we indexing?
In this case, we need to know how many cylinders a specific car has, so we can get the mean of mpg for those cars with that many cylinders.
So we use the index to get that.
But if we inputed the cylinder as a argument to our function, we could deal with it differently.


```r
demean <- function(x, cylinders, data){
  # subset data to only cars with that cylinder
  tmp <- subset(data, cyl == cylinders)
  
  # mean of mpg for this cylinder type
  mcyl <- mean(tmp$mpg)
  
  return(x - mcyl)
}
```

ok, I've changed several things here.
Main input into our function is now `x` rather than `i`.
The name does not really matter, but its more common to name an input element `x`, so we keep to that here.
The difference being that `i` was the index of an element, while `x` is now the value it self.
And we've added the `cylinders` argument, so we can input how many cylinders the car has.
We could then use it like so:


```r
demean(x = 21, cylinders = 6, data = mtcars)
```

```
## [1] 1.257143
```

```r
demean(10.4, 4, mtcars)
```

```
## [1] -16.26364
```

How can we use that in `sapply` then?
Remember that any more arguments given to `sapply` have to be singular and named.


```r
sapply(c(21, 10.4), demean, data = mtcars, cylinders = 6)
```

```
## [1]  1.257143 -9.342857
```
But doing it like this, we cannot account for different cylinders of different cars.
We _have set it up so we could run it several times, each for each cylinder type, but that is not as elegant as I'd like, and harder to get back into its original form.

This means that `sapply` is not the function we are looking for.
What we want is `mapply`, which in my head stands for "matrix apply".
And I use this _a lot_!

`mapply` has a slightly different order of arguments, because of how it works.
It first takes the function you can to apply, then all the vectors you want to apply over, and then you can add other named arguments.


```r
mapply(demean,
       x = mtcars$mpg,
       cylinders = mtcars$cyl,
       MoreArgs = list(
         data = mtcars
       ))
```

```
##  [1]  1.25714286  1.25714286 -3.86363636  1.65714286  3.60000000 -1.64285714
##  [7] -0.80000000 -2.26363636 -3.86363636 -0.54285714 -1.94285714  1.30000000
## [13]  2.20000000  0.10000000 -4.70000000 -4.70000000 -0.40000000  5.73636364
## [19]  3.73636364  7.23636364 -5.16363636  0.40000000  0.10000000 -1.80000000
## [25]  4.10000000  0.63636364 -0.66363636  3.73636364  0.70000000 -0.04285714
## [31] -0.10000000 -5.26363636
```

What is happening here? 
We first tell `mapply` we want to `demean()` the data,
then we say that `x` is all the values in the mpg column of mtcars, then that the cylinders are from the cyl column in mtcars.
These have to be of equal length.
`mapply` will match them together. 
The first `x` goes with the first `cylinders`, the second `x` with the second `cylinders` and so on. 
But we have a _single_ data source. 
This is provided as a named list to the `MoreArgs` argument. 



```r
mtcars$dm_m <- mapply(demean,
       x = mtcars$mpg,
       cylinders = mtcars$cyl,
       MoreArgs = list(
         data = mtcars
       ))
mtcars
```

```
##                     cyl  mpg      mpg_dm          dm        dm_m
## Mazda RX4             6 21.0  1.25714286  1.25714286  1.25714286
## Mazda RX4 Wag         6 21.0  1.25714286  1.25714286  1.25714286
## Datsun 710            4 22.8 -3.86363636 -3.86363636 -3.86363636
## Hornet 4 Drive        6 21.4  1.65714286  1.65714286  1.65714286
## Hornet Sportabout     8 18.7  3.60000000  3.60000000  3.60000000
## Valiant               6 18.1 -1.64285714 -1.64285714 -1.64285714
## Duster 360            8 14.3 -0.80000000 -0.80000000 -0.80000000
## Merc 240D             4 24.4 -2.26363636 -2.26363636 -2.26363636
## Merc 230              4 22.8 -3.86363636 -3.86363636 -3.86363636
## Merc 280              6 19.2 -0.54285714 -0.54285714 -0.54285714
## Merc 280C             6 17.8 -1.94285714 -1.94285714 -1.94285714
## Merc 450SE            8 16.4  1.30000000  1.30000000  1.30000000
## Merc 450SL            8 17.3  2.20000000  2.20000000  2.20000000
## Merc 450SLC           8 15.2  0.10000000  0.10000000  0.10000000
## Cadillac Fleetwood    8 10.4 -4.70000000 -4.70000000 -4.70000000
## Lincoln Continental   8 10.4 -4.70000000 -4.70000000 -4.70000000
## Chrysler Imperial     8 14.7 -0.40000000 -0.40000000 -0.40000000
## Fiat 128              4 32.4  5.73636364  5.73636364  5.73636364
## Honda Civic           4 30.4  3.73636364  3.73636364  3.73636364
## Toyota Corolla        4 33.9  7.23636364  7.23636364  7.23636364
## Toyota Corona         4 21.5 -5.16363636 -5.16363636 -5.16363636
## Dodge Challenger      8 15.5  0.40000000  0.40000000  0.40000000
## AMC Javelin           8 15.2  0.10000000  0.10000000  0.10000000
## Camaro Z28            8 13.3 -1.80000000 -1.80000000 -1.80000000
## Pontiac Firebird      8 19.2  4.10000000  4.10000000  4.10000000
## Fiat X1-9             4 27.3  0.63636364  0.63636364  0.63636364
## Porsche 914-2         4 26.0 -0.66363636 -0.66363636 -0.66363636
## Lotus Europa          4 30.4  3.73636364  3.73636364  3.73636364
## Ford Pantera L        8 15.8  0.70000000  0.70000000  0.70000000
## Ferrari Dino          6 19.7 -0.04285714 -0.04285714 -0.04285714
## Maserati Bora         8 15.0 -0.10000000 -0.10000000 -0.10000000
## Volvo 142E            4 21.4 -5.26363636 -5.26363636 -5.26363636
```

And now we can see we have the exact same output from all the different approaches, but the last one leaves somewhat less room for error in the long run. 

Of course, if you are tidyverseing, this is all void.
There is a _much_ neater way of doing it.


```r
library(tidyverse)
```

```
## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.2 ──
## ✔ ggplot2 3.3.6      ✔ purrr   0.3.5 
## ✔ tibble  3.1.8      ✔ dplyr   1.0.10
## ✔ tidyr   1.2.1      ✔ stringr 1.4.1 
## ✔ readr   2.1.2      ✔ forcats 0.5.2 
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
```

```r
mtcars |> 
  group_by(cyl) |> 
  mutate(dm_t = mpg - mean(mpg))
```

```
## # A tibble: 32 × 6
## # Groups:   cyl [3]
##      cyl   mpg mpg_dm     dm   dm_m   dm_t
##    <dbl> <dbl>  <dbl>  <dbl>  <dbl>  <dbl>
##  1     6  21    1.26   1.26   1.26   1.26 
##  2     6  21    1.26   1.26   1.26   1.26 
##  3     4  22.8 -3.86  -3.86  -3.86  -3.86 
##  4     6  21.4  1.66   1.66   1.66   1.66 
##  5     8  18.7  3.6    3.6    3.6    3.6  
##  6     6  18.1 -1.64  -1.64  -1.64  -1.64 
##  7     8  14.3 -0.800 -0.800 -0.800 -0.800
##  8     4  24.4 -2.26  -2.26  -2.26  -2.26 
##  9     4  22.8 -3.86  -3.86  -3.86  -3.86 
## 10     6  19.2 -0.543 -0.543 -0.543 -0.543
## # … with 22 more rows
```


But as I said in the beginning, some ties, we work on systems where our tools of choice are hard to get working, so knowing base-R equivalents are a great way of working around that.
I will quite often start development working with tidyverse, then slowly start swapping out dependencies where I can if I know this tool will be used in a hard-to-install place.

This concludes my first bit in the "apply"-series.
Next time I'll show a bit more about how I use apply to read in multiple files at once and start preparing them for merging. 

<img src="blobby_bricks_TradingCard.jpg" alt="[Created with WOMBO Dream](https://www.wombo.art/listing/ff57e347-4214-4c9e-80b4-3b5ffd8cec6e)" width="540" />


