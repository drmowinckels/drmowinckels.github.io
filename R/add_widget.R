#' Add widget to markdown
#'
#' @param x widget
#' @param name filename
#' @param height ifram height
add_widget <- function(x, name, height = "500px") { 
  name <- paste0(name, "_widget.html") 
  withr::with_dir(".", 
                  htmlwidgets::saveWidget(x, 
                                          name, 
                                          selfcontained = TRUE))
  
  htmltools::tags$iframe(src = name,
                         width = "100%",
                         height = height)
}