---
title: "Main Penguin document"
output: pdf_document
---




```r
# Define new environment
child_env <- new.env()
child_env$species <- "Adelie"

# knit the document and save the character output to an object
res <- knitr::knit_child(
  "species-child.Rmd",
  envir = child_env,
  quiet = TRUE
)

# Cat the object to make it render in your main document
cat(res, sep = '\n')
```






## Species Adelie

```
## Warning: Removed 2 rows containing missing values (geom_point).
```

<img src="/blog/2021-12-17-rmarkdown-child-templates/main-document_files/figure-html/unnamed-chunk-2-1.png" width="672" />

```
## # A tibble: 3 × 5
##   cols               mean   min   max     N
##   <chr>             <dbl> <dbl> <dbl> <int>
## 1 bill_depth_mm      17.2  13.1  21.5   342
## 2 bill_length_mm     43.9  32.1  59.6   342
## 3 flipper_length_mm 201.  172   231     342
```


## Species Chinstrap

```
## Warning: Removed 2 rows containing missing values (geom_point).
```

<img src="/blog/2021-12-17-rmarkdown-child-templates/main-document_files/figure-html/unnamed-chunk-5-1.png" width="672" />

```
## # A tibble: 3 × 5
##   cols               mean   min   max     N
##   <chr>             <dbl> <dbl> <dbl> <int>
## 1 bill_depth_mm      17.2  13.1  21.5   342
## 2 bill_length_mm     43.9  32.1  59.6   342
## 3 flipper_length_mm 201.  172   231     342
```


## Species Gentoo

```
## Warning: Removed 2 rows containing missing values (geom_point).
```

<img src="/blog/2021-12-17-rmarkdown-child-templates/main-document_files/figure-html/unnamed-chunk-8-1.png" width="672" />

```
## # A tibble: 3 × 5
##   cols               mean   min   max     N
##   <chr>             <dbl> <dbl> <dbl> <int>
## 1 bill_depth_mm      17.2  13.1  21.5   342
## 2 bill_length_mm     43.9  32.1  59.6   342
## 3 flipper_length_mm 201.  172   231     342
```
