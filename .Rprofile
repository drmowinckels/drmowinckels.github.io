source("renv/activate.R")

# in .Rprofile of the website project
if (file.exists("~/.Rprofile")) {
  base::sys.source("~/.Rprofile", envir = environment())
}

options(
  blogdown.new_bundle = TRUE,
  blogdown.author = "Dr. Mowinckel",
  blogdown.ext = '.Rmd',
  blogdown.method = "markdown",
  blogdown.subdir = "blog",
  blogdown.hugo.version = "0.138.0",
  blogdown.knit.on_save = TRUE
)

if ("ggplot2" %in% installed.packages()) {
  options(
    ggplot2.discrete.colour = scale_colour_viridis_d,
    ggplot2.discrete.fill = scale_fill_viridis_d,
    ggplot2.continuous.colour = scale_colour_viridis_c,
    ggplot2.continuous.fill = scale_fill_viridis_c
  )
}
