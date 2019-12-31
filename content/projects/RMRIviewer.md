---
title: "MRI viewer"
date: 2018-03-13T12:21:16-05:00
image: "img/VisMRI_wide.png"
external_link: ""
weight: 1
draft: false
---

There is currently a lack of tools for visualising results from MRI analyses in R, most packages call an external command to open a viewer in another program. There is, however, advantages to visualise directly from R, among other increased understanding of the underlying data.

In this project, tentatively called visMRI, the idea is to create a shiny instance that will function as a viewer for MRI results. Ultimately, I hope to launch something that might be used on a `.feat` folder from [FSL](www.fmrib.ox.ac.uk)

By the marvellous idea and contribution of a colleague, I also hope to incorporate his code for [Freesurfer's](https://surfer.nmr.mgh.harvard.edu) `aparc` segmentations. 

<a href="https://athanasiamo.shinyapps.io/VisMRI" title="View buggy demonstration"><i class="fa fa-eye"></i></a>
<a href="https://github.com/Athanasiamo/VisMRI" title=Github repository"><i class="fa fa-github"></i></a>
