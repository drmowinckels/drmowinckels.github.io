---
title: "MRI viewer"
date: 2018-03-13T12:21:16-05:00
image: "img/VisMRI.png"
external_link: ""
weight: 1
---

There is currently a lack of tools for vislualising results from MRI analyses in R, most packages call an external command to open a viewer in another program. There is, however, advantages to visualise directly from R, among other increased understanding of the underlying data.

In this project, tentatively called visMRI, the idea is to create a shiny instance that will function as a viewer for MRI results. Ultimately, I hope to launch something that might be used on a `.feat` folder from [FSL](www.fmrib.ox.ac.uk)

By the marvellous idea of a colleague, I also hope to incporporate his code for [Freesurfer's](https://surfer.nmr.mgh.harvard.edu) aparc segmentations. 

A very buggy example can be seen [here](https://athanasiamo.shinyapps.io/VisMRI).