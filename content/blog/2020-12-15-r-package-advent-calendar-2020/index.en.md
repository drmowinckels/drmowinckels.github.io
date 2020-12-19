---
title: R-Package Advent Calendar 2020
author: Dr. Mowinckel
date: '2020-12-19'
slug: r-package-advent-calendar-2020
categories: []
tags:
  - R
  - Advent calendar
  - Packages
output:
  html_document:
    keep_md: yes
always_allow_html: yes
image: index_files/
---

<style type="text/css">
  .tui-full-calendar-weekday-grid-date-decorator {
    background: #AD957F !important;
  }

.button {
  background-color: #AD957F;
  border: none;
  color: white;
  text-align: center;
  font-size: 14px;
  cursor: pointer;
}

.button:hover {
  background-color: #AD957Fb4;
}

.tui-calendar-today {
  background: #AD957F !important;
}

</style>



This year has been truly something different for us all. 
Blogging has definitely taken a toll, as real life has been quite something to handle.
So, in order to end the year with a bang, and something fun, I started a twitter advent calendar!

{{< tweet 1334052850037645314 >}}


The advent calendar is one R-package per day that I personally use and find very useful in my work. 
The hope is that it would give people a mix of familiar and less familiar packages that might help their work too. 
In each package sub-thread, I try to highlight some functions or functionality from the various packages that I like in particular.
There are so many packages on CRAN and other online repositories (BioConductor, GitHub, Gitlab, NeuroConductor etc.), that it can be hard to find something to help you along. 
I hope this atleast points you in a good direction.
There are other packages that could cover some or all of the same functionality as the ones listed here, but these are the ones I personally use.

Below I have placed it all in a neat calendar view using [tuicalendr](https://github.com/dreamRs/tuicalendr), a wrapper for Toast UI calendar java script through R.

<!--html_preserve--><div id="htmlwidget-a64562474fb3a3258328_menu">
<span id="htmlwidget-a64562474fb3a3258328_menu_navi">
<button type="button" class="btn bttn-no-outline action-button" id="htmlwidget-a64562474fb3a3258328_today">Today</button>
<button type="button" class="btn bttn-no-outline action-button" id="htmlwidget-a64562474fb3a3258328_prev">
<i class="fa fa-chevron-left"></i>
</button>
<button type="button" class="btn bttn-no-outline action-button" id="htmlwidget-a64562474fb3a3258328_next">
<i class="fa fa-chevron-right"></i>
</button>
</span>
<span id="htmlwidget-a64562474fb3a3258328_renderRange" class="render-range"></span>
</div>
<br/>
<div id="htmlwidget-a64562474fb3a3258328" style="width:100%;height:600px;" class="calendar html-widget" width="100%" height="600px"></div>
<script type="application/json" data-for="htmlwidget-a64562474fb3a3258328">{"x":{"options":{"defaultView":"month","taskView":false,"scheduleView":true,"useDetailPopup":true,"useCreationPopup":false,"isReadOnly":true,"usageStatistics":false,"calendars":[{"id":"advent_cal","name":"Advent calendar","color":"#FFF","bgColor":"#4E6769","borderColor":"#4E6769"}]},"schedules":[{"category":"time","dueDateClass":"","id":835876,"calendarId":"advent_cal","title":"distill","start":"2020-12-01","body":"<h2>distill<\/h2>\n<a href='https://rstudio.github.io/distill/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1334054102905593861' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":45863,"calendarId":"advent_cal","title":"here","start":"2020-12-02","body":"<h2>here<\/h2>\n<a href='https://here.r-lib.org' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1334055725644058624' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":563048,"calendarId":"advent_cal","title":"glue","start":"2020-12-03","body":"<h2>glue<\/h2>\n<a href='https://glue.tidyverse.org' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1334404923564437504' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":284651,"calendarId":"advent_cal","title":"holepunch","start":"2020-12-04","body":"<h2>holepunch<\/h2>\n<a href='https://karthik.github.io/holepunch/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1334770520953417729' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":327241,"calendarId":"advent_cal","title":"xaringan","start":"2020-12-05","body":"<h2>xaringan<\/h2>\n<a href='https://slides.yihui.org/xaringan/#1' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1335302958989398016' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":210655,"calendarId":"advent_cal","title":"usethis","start":"2020-12-06","body":"<h2>usethis<\/h2>\n<a href='https://usethis.r-lib.org' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1335691689764204544' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":999514,"calendarId":"advent_cal","title":"nettskjemar","start":"2020-12-07","body":"<h2>nettskjemar<\/h2>\n<a href='https://lcbc-uio.github.io/nettskjemar/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1335858603891232768' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":601097,"calendarId":"advent_cal","title":"stringr","start":"2020-12-08","body":"<h2>stringr<\/h2>\n<a href='https://stringr.tidyverse.org' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1336215088089493504' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":57484,"calendarId":"advent_cal","title":"kableExtra","start":"2020-12-09","body":"<h2>kableExtra<\/h2>\n<a href='https://haozhu233.github.io/kableExtra/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1336575636324954113' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":493154,"calendarId":"advent_cal","title":"patchwork","start":"2020-12-10","body":"<h2>patchwork<\/h2>\n<a href='https://patchwork.data-imaginist.com/articles/patchwork.html' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1336943011389992961' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":326205,"calendarId":"advent_cal","title":"rticles","start":"2020-12-11","body":"<h2>rticles<\/h2>\n<a href='https://github.com/rstudio/rticles' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1337305681385414656' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":426614,"calendarId":"advent_cal","title":"forcats","start":"2020-12-12","body":"<h2>forcats<\/h2>\n<a href='https://forcats.tidyverse.org' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1337869018129195012' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":558856,"calendarId":"advent_cal","title":"vitae","start":"2020-12-13","body":"<h2>vitae<\/h2>\n<a href='https://github.com/mitchelloharawild/vitae' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1338028973708677120' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":478008,"calendarId":"advent_cal","title":"pbmcapply","start":"2020-12-14","body":"<h2>pbmcapply<\/h2>\n<a href='https://github.com/kvnkuang/pbmcapply' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1338400483229261824' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":598412,"calendarId":"advent_cal","title":"lubridate","start":"2020-12-15","body":"<h2>lubridate<\/h2>\n<a href='https://lubridate.tidyverse.org/articles/lubridate.html' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1338802526955728896' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":35284,"calendarId":"advent_cal","title":"magick","start":"2020-12-16","body":"<h2>magick<\/h2>\n<a href='https://cran.r-project.org/web/packages/magick/vignettes/intro.html' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1339110009427423233' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":171123,"calendarId":"advent_cal","title":"papayar","start":"2020-12-17","body":"<h2>papayar<\/h2>\n<a href='https://cran.rstudio.com/web/packages/papayar/papayar.pdf' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1339491287003783169' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":450902,"calendarId":"advent_cal","title":"learnr","start":"2020-12-18","body":"<h2>learnr<\/h2>\n<a href='https://rstudio.github.io/learnr/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1339902456382296064' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"},{"category":"time","dueDateClass":"","id":739931,"calendarId":"advent_cal","title":"janitor","start":"2020-12-19","body":"<h2>janitor<\/h2>\n<a href='http://sfirke.github.io/janitor/' target='_blank'><button class='button'>Package page<\/button><\/a>\n<a href='https://twitter.com/DrMowinckels/status/1340205260317581312' target='_blank'><button class='button'>Twitter thread<\/button><\/a>"}],"useNav":false,"events":[],"bttnOpts":{"today_label":"Today","prev_label":"<i class=\"fa fa-chevron-left\"><\/i>","next_label":"<i class=\"fa fa-chevron-right\"><\/i>","class":" bttn-jelly bttn-sm bttn-primary"}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## How I selected a package per day

Before I started the calendar (one day late!), I sat down and wrote a list of all the packages I wanted in my advent calendar.

The rules were:

- One package per day  
- I must personally use it  
- I can find easy examples of why I like using it  

The point of the calendar was to do something fun, that others might find useful, and that would highlight and give credit to great packages.
But I also did not have the possibility of spending lots of time researching other alternative options or the like, it was to be a light-weight and easy thing for me to do. 

So i wrote down my list in R:



```r
pks <- c("usethis", "rio", "distill", 
         "boom", "patchwork", "holepunch",
         "learnr", "xaringan", "magick",
         "nettskjemar", "pkgdown", "here",
         "rticles", "vitae", "xaringanExtra",
         "stringr", "forcats", "lubridate", 
         "glue", "janitor", "pbmcapply",
         "kableExtra", "papayar", "reactable")
```

Then I made a little function that would draw a random one every time I ran it, while omitting the ones I had drawn before


```r
get_todays <- function(completed, pkgs){
  days <- 1:24
  days <- days[!days %in% completed]
  k <- sample(days, 1)  
  cat(pkgs[k], "\n")
  k
}
```


Now I had an itty bitty function that would draw from my list by random each day, so I did not have to think about the order of things. 
Every day I drew a new package, tweeted about it, and added it to the completed list.


```r
completed <- c(3, 12, 19, 6, 8, 1, 
               10, 16, 22, 5, 
               17, 21, 18, 9, 7)

get_todays(completed, pks)
```

```
## janitor
```

```
## [1] 20
```

Now, there is a slight problem with my function.
I forgot to add a random seed, as pointed out by [Tobias Busch](https://twitter.com/tobilottii)

{{< tweet 1334169186751410178 >}}

So, always room for improvement! If I do something similar next year, I'll be sure to add that!

Have a great Christmas, everyone!



