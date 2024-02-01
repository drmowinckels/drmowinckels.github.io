library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(ggimage)

dt <- tribble(
  ~day, ~title,         ~twitter,               ~url,
  1,    "distill",    "1334054102905593861", "https://rstudio.github.io/distill/",
  2,    "here",       "1334055725644058624", "https://here.r-lib.org",
  3,    "glue",       "1334404923564437504", "https://glue.tidyverse.org",
  4,    "holepunch",  "1334770520953417729", "https://karthik.github.io/holepunch/",
  5,    "xaringan",   "1335302958989398016", "https://slides.yihui.org/xaringan/#1",
  6,    "usethis",    "1335691689764204544", "https://usethis.r-lib.org",
  7,    "nettskjemar","1335858603891232768", "https://lcbc-uio.github.io/nettskjemar/",
  8,    "stringr",    "1336215088089493504", "https://stringr.tidyverse.org",
  9,    "kableExtra", "1336575636324954113", "https://haozhu233.github.io/kableExtra/",
  10,   "patchwork",  "1336943011389992961", "https://patchwork.data-imaginist.com/articles/patchwork.html",
  11,   "rticles",    "1337305681385414656", "https://github.com/rstudio/rticles",
  12,   "forcats",    "1337869018129195012", "https://forcats.tidyverse.org",
  13,   "vitae",      "1338028973708677120", "https://github.com/mitchelloharawild/vitae",
  14,   "pbmcapply",  "1338400483229261824", "https://github.com/kvnkuang/pbmcapply",
  15,   "lubridate",  "1338802526955728896", "https://lubridate.tidyverse.org/articles/lubridate.html",
  16,   "magick",     "1339110009427423233", "https://cran.r-project.org/web/packages/magick/vignettes/intro.html",
  17,   "papayar",    "1339491287003783169", "https://cran.rstudio.com/web/packages/papayar/papayar.pdf",
  18,   "learnr",     "1339902456382296064", "https://rstudio.github.io/learnr/",
  19,   "janitor",    "1340205260317581312", "http://sfirke.github.io/janitor/",
  20,   "xaringanExtra",    "1340566661712257030", "https://pkg.garrickadenbuie.com/xaringanExtra/#/",
  21,   "reactable",    "1340938927734222848", "https://glin.github.io/reactable/",
  22,   "broom",    "1341293669001932805", "https://broom.tidymodels.org/",
  23,   "rio",    "1341655830337302531", "https://github.com/leeper/rio",
  24,   "pkgdown",    "", "https://pkgdown.r-lib.org"
) %>% 
  mutate(
    date = as.Date(sprintf("2020-12-%02d", day)),
    image = paste0("hex/", title, ".png"),
    weekday = weekdays(date, abbreviate(TRUE)),
    weekday = factor(weekday, 
                     levels = c("Mon", "Tue", "Wed", 
                                "Thu", "Fri", "Sat", "Sun")),
    category = "other"
  ) %>% 
  group_by(weekday) %>% 
  mutate(rows = row_number(),
         rows = ifelse(weekday == "Mon", rows+1, rows))
jsonlite::write_json(dt, "calendar.json", pretty = TRUE)
jsonlite::write_json(dt, here::here("data/2020-advent-calendar.json"), pretty = TRUE)
