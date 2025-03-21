---
name: Athanasia Monika Mowinckel
date: "`r format(Sys.time(), '%B, %Y')`"
qualifications: PhD
position: Staff Scientist
email: a.m.mowinckel@psykologi.uio.no
profilepic: ../profile.png
www: "drmowinckels.io/"
github: drmowinckels
linkedin: drmowinckels
twitter: DrMowinckels
headcolor: "008080"
urlcolor:  "008080"
linkcolor: "008080"
citecolor: "008080"
docname: mowinckel_cv
output: 
  vitae::awesomecv:
    keep_tex: true
---

```{r setup, include=FALSE}
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(vitae)
library(rorcid)
library(glue)
knitr::opts_chunk$set(echo = FALSE, 
                      warning = FALSE, 
                      error = FALSE, 
                      message = FALSE)
options(tinytex.verbose = TRUE)
orcid <- "0000-0002-5756-0223"
scholar_id <- "7NkxgWQAAAAJ"
```

# Education

```{r education}
bind_rows(
  orcid_educations(orcid)[[1]]$`affiliation-group`$summaries
) %>%
  mutate(
    thesis =  paste0("Thesis title: ",
                     c("Neurocognitive Processes of Decision-making in Adults with ADHD",
                       "Default Mode Resting-State Functional Connectivity of the Aging Brain",
                       "Attention Deficits in Mild Cognitive Impairment and Dementia of the Alzheimer Type")),
    when = glue("{`education-summary.start-date.year.value`} - {`education-summary.end-date.year.value`}"),
    with = glue("{`education-summary.role-title`} - {`education-summary.organization.name`} - Norway")) %>%
  detailed_entries(thesis, when, with)
```

# Research positions

```{r "research-pos"}

bind_rows(
  orcid_employments(orcid)[[1]]$`affiliation-group`$summaries
) %>%
  mutate(end_date = ifelse(is.na(`employment-summary.end-date.year.value`),
                           "present",
                           as.character(`employment-summary.end-date.year.value`)),
         why = c(tibble(x = c("Creation and maintenance of LCBC data-base",
                              "Data sharing and management in Lifebrain EU-project (WP2)",
                              "Oversee data quality in ongoing data-collection")),
                 tibble(x = c("Coordinating data collection, data-management, and research collaborations",
                              "Running analyses and data preparations")),
                 tibble(x = c("Work with functional MRI-analysis, supervising students, and transitioning lab from windows to a Linux",
                              "Scripting of experiments, testing of participants and work on application for grants and ethical approval")))
  ) %>%
  unnest(why) %>%
  detailed_entries(
    what = `employment-summary.role-title`,
    when = glue("{`employment-summary.start-date.year.value`} - {end_date}"),
    with = glue("{`employment-summary.organization.name`} - {`employment-summary.department-name`}"),
    where = `employment-summary.organization.address.city`,
    why = why
  )
```

# Memberships & Services

```{r results='asis'}
cat("\\footnotesize
I am passionate about increasing the representation and retention of women in science, and in improving the formal training and competencies taught at the University. These interests are evident from task force and board memberships, and in activities I engage in outside of work, like R-Ladies.
")
```

```{r "services"}

do.call(bind_rows,
        orcid_memberships(orcid)[[1]]$`affiliation-group`$summaries
) %>%
  detailed_entries(
    what = `membership-summary.role-title`,
    when = glue("{`membership-summary.start-date.year.value`} - present"),
    with = glue("{`membership-summary.organization.name`}"),
    where = `membership-summary.organization.address.city`,
    why = c(
      "Global coordination of R-Ladies as a non-profit organisation",
      "Assisting in daily coordination and webpage maintenance of R-Ladies globally",
      "Initiative running events for coding, networking and support of minority genders in the R-community")
  )

do.call(
  bind_rows,
        orcid_services(orcid)[[1]]$`affiliation-group`$summaries
)  %>%
  detailed_entries(
    what = `service-summary.role-title`,
    when = glue("{`service-summary.start-date.year.value`} - {`service-summary.end-date.year.value`}"),
    with = glue("{`service-summary.organization.name`}"),
    where = `service-summary.organization.address.city`,
    why = `service-summary.department-name`
  )
```

# Teaching & Dissemination

```{r results='asis'}
cat("\\footnotesize
In addition to teaching and workshops, I run a coding and neuroscience blog, \\href{https://drmowinckels.io}{drmowinckels.io \\faicon{globe} }, that includes tutorials in R and neuroimaging. I am also a certified \\href{https://software-carpentry.org/}{Software Carpentry Instructor \\faicon{globe}}.
")
```

## University

```{r tutoring}
tribble(
  ~ role, ~ uni, ~ campus, ~ dates, ~ details,
  "Seminar teacher", "University of Oslo", "Oslo, Norway", "2012 - 2015", "Introduction to research methods (PSY1010/PSYC1100)",
  "Seminar teacher", "University of Oslo", "Oslo, Norway", "2012 - 2015", "Experimental Cognitive Psychology (PSYC2102)",
  "Supervisor", "University of Oslo", "Oslo, Norway", "2012 - 2015", "Bachelor thesis",
  "Seminar teacher", "University of Oslo", "Oslo, Norway", "2009 - 2011", "Introduction to research methods (PSY1010/PSYC1100)",
  "Seminar teacher", "University of Oslo", "Oslo, Norway", "2009 - 2011", "Introduction to social psychology (PSY1100)",
) %>%
  detailed_entries(role, dates, uni, campus, details)
```

## Workshops

```{r workshops}
tribble(
  ~ role, ~ course, ~ location, ~ dates, ~ details,
  "Instructor", "Monthly internal R-workshops for LCBC", "Center for Lifespan Changes in Brain and Cognition", "Monthly 2018 - present", "2 hour workshops in using R for analysis, visualization, dissemination etc.",
  "Instructor", "Workshop: Straightforward introduction to mixed models \\href{https://www.meetup.com/rladies-london/events/259655336/}{\\faicon{globe}}", "Oslo UseR!", "June 5, 2019", "A short workshop in the use of Mixed-models for repeated measurement data",
  "Instructor", "Linear Mixed models on repeated measurement data
\\href{https://www.meetup.com/Oslo-useR-Group/events/260303778/}{\\faicon{globe}}", "R-Ladies London", "March 28, 2019", "A short workshop in the use of Mixed-models for repeated measurement data",
"Co-instructor", "TidyVerse R \\href{https://www.ub.uio.no/english/courses-events/courses/other/Carpentry/software-carpentry/time-and-place/180925-26_TidyR}{\\faicon{globe}}", "University of Oslo - Software Carpentry", "Sept.  25 - 26, 2018", "Two-day workshop on using R and the Tidyverse-packages for data handling and analysis",
) %>%
  detailed_entries(role, dates, course, location, details, .protect = FALSE)
```

# Research software development

```{r results='asis'}
cat("\\footnotesize
A recent interest and professional endeavor is creating R-packages to improve data workflows and visualization in R. Icons link to package websites with documentation (\\faicon{globe}), and github repositories (\\faicon{github}) where source code is openly available.
")
```

```{r r-pkgs}
tribble(
  ~ pkg, ~ docs, ~ github, ~ when, ~ role, ~ details,
  "ggseg", "\\href{https://lcbc-uio.github.io/ggseg/}{\\faicon{globe}}", "\\href{https://github.com/LCBC-UiO/ggseg}{\\faicon{github}}", "2018 - present", "Lead developer", "Visualization tool for brain atlas segmentations through R",
  "ggeg3d",  "\\href{https://lcbc-uio.github.io/ggseg3d/}{\\faicon{globe}}", "\\href{https://github.com/LCBC-UiO/ggseg3d}{\\faicon{github}}","2018 - present", "Lead developer", "3 dimensional visualization tool for brain atlas segmentations through R",
  "ggegExtra", "\\href{https://lcbc-uio.github.io/ggsegExtra/}{\\faicon{globe}}", "\\href{https://github.com/LCBC-UiO/ggsegExtra}{\\faicon{github}}", "2018 - present", "Lead developer", "Repository of atlas data for the ggseg-packages",
  "nettskjemar",  "\\href{https://lcbc-uio.github.io/nettskjemar/}{\\faicon{globe}}", "\\href{https://github.com/LCBC-UiO/nettskjemar}{\\faicon{github}}","2019 - present", "Lead developer", "Package to retrieve data and meta-data from the nettskjema questionnaire tool developed by the University of Oslo",
  "metagam",  "\\href{https://lifebrain.github.io/metagam/}{\\faicon{globe}}", "\\href{https://github.com/Lifebrain/metagam}{\\faicon{github}}","2020", "Contributor", "Meta-Analysis of Generalized Additive Models in Neuroimaging Studies",
  
) %>%
  brief_entries(glue("\\textbf{<pkg> <github> <docs>}: <role> \\newline <details>", .open = "<", .close = ">"), when, .protect = FALSE)
```

<!-- # Awards & Achievements -->

<!-- ## Awards -->

<!-- ```{r} -->

<!-- tribble( -->

<!--   ~ award, ~ from, ~ year, -->

<!--   "Commerce Dean's Honour", "Monash", "2017", -->

<!--   "Commerce Dean's Commendation", "Monash", "2016", -->

<!--   "Science Dean’s List", "Monash", "2014-2016", -->

<!--   "International Institute of Forecasters Award", "IIF", "2014", -->

<!--   "Rotary Youth Leadership Award", "Rotary", "2013" -->

<!-- ) %>% -->

<!--   brief_entries(award, year, from) -->

<!-- ``` -->

\newpage

# Publications & Preprints

```{r "pubPlot", dev.args = list(bg = 'transparent'), out.width= "100%", fig.height=3}
scholar::get_citation_history(scholar_id) %>%
  mutate(cumulative=cumsum(cites)) %>%
  rename(yearly = cites) %>% 
  gather(metric, val, -1) %>%
  ggplot(aes(x=as.factor(year), y=val, 
             group=metric, colour=metric)) +
  geom_line(lineend="round") +
  geom_point(show.legend = F) +
  labs(y="Googe citations", x="Year",
       colour = "",
       title = "Citations over time",
       caption = paste("retrieved from google scholar on",
                       format(Sys.time(), "%Y-%m-%d at %H:%M"))
       ) +
  theme_minimal() +
  theme(panel.grid.major = element_line(color="#4E67691F"),
        axis.line = element_line(),
        text = element_text(color="#4E6769"),
        line = element_line(color="#4E6769")) +
  scale_color_manual(values=c("#008080", "#004d4d"))
```

```{r "pubList-get"}
pubs <- scholar::get_publications(scholar_id) %>%
  arrange(desc(year)) %>%
  filter(!is.na(year), !is.na(journal), journal != "") %>%
  as_tibble() %>%
  mutate_all(as.character) %>%
  mutate(
    title = str_replace_all(title, "ε", "$\\\\varepsilon$ "),
    cite = ifelse(grepl("rxiv", journal, ignore.case = TRUE),
                  glue("Preprint \\newline cites: <cites>", .open = "<", .close = ">"),
                  glue("cites: <cites>", .open = "<", .close = ">")),
    author = str_replace(author, "Mowinckel", "\\\\textbf{Mowinckel}"),
    author = str_replace(author, "\\.\\.\\.", "et al."),
    journal = str_replace(journal, "&", "and"),
    number = ifelse(number == "", " ", number),
    number = str_replace_all(number, "[[:punct:]]", ""),
    cid = ifelse(!is.na(cid),
                 glue("https://scholar.google.no/scholar?oi=bibs&hl=en&cluster=<cid>", .open = "<", .close = ">"),
                 NA),
    journal = ifelse(!is.na(cid),
                     glue("\\href{<cid>}{<journal> <number>}", .open = "<", .close = ">"),
                     glue("<journal> <number>", .open = "<", .close = ">")
    ),
    across(where(is.character), str_trim)
  )  %>% 
  filter(!grepl("\\varepsilon", title))

```

## Most recent 10

```{r publist-1}
pubs |> 
  arrange(year) |> 
  brief_entries(
    what = glue("<author> \\newline \\textit{<title>} \\newline <journal> \\vspace{1mm} ", .open = "<", .close = ">"),
    when = year,
    with = cite,
    .protect = FALSE
  ) 
```

## Most cited 10

```{r publist-2, results='asis'}
pubs |> 
  arrange(desc(as.numeric(cites))) |> 
  brief_entries(
    what = glue("<author> \\newline \\textit{<title>} \\newline <journal> \\vspace{1mm} ", .open = "<", .close = ">"),
    when = year,
    with = cite,
    .protect = FALSE
  ) 
```
