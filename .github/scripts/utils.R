#' Shorten a URL using the Short.io API
#'
#' This function takes a given URL and leverages the Short.io API to generate
#' a shortened version of the URL using the specified custom domain.
#'
#' @param uri A character string. The original URL to be shortened.
#'
#' @return A character string. The shortened URL returned by the Short.io API.
#'
#' @description
#' `short_url` sends a POST request to the Short.io API to create a new shortened
#' URL for the provided `uri`. The function uses environment variable `SHORTIO`
#' for the API key and sets specific options for the API call, such as not
#' allowing duplicate links and setting a fixed domain for the shortened URL.
#'
#' @examples
#' \dontrun{
#'   # Example usage to shorten a URL
#'   Sys.setenv(SHORTIO = "your_api_key_here") # Set API key in environment
#'   short_url("https://www.example.com/very-long-url")
#' }
#'
#' @importFrom httr2 request req_method req_headers req_body_json req_perform
#' @importFrom httr2 resp_body_json
#' @export
short_url <- function(uri) {
  message("Getting Short.io")
  resp <- httr2::request("https://api.short.io/links") |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      Authorization = Sys.getenv("SHORTIO"),
      accept = "application/json",
      `content-type` = "application/json",
    ) |>
    httr2::req_body_json(
      data = list(
        skipQS = FALSE,
        archived = FALSE,
        allowDuplicates = FALSE,
        originalURL = uri,
        domain = "drmo.site"
      ),
    ) |>
    httr2::req_perform() |>
    httr2::resp_body_json()
  resp$shortURL
}

#' Compute the Number of Characters in a String
#'
#' This function calculates the total number of characters in a given string.
#'
#' @param x A character string. The input string whose length is to be calculated.
#'
#' @return An integer. The total number of characters in the input string.
#'
#' @description
#' `strlength` splits the input string into individual characters and counts them
#' using `strsplit` and `length`. It is equivalent to determining the string length.
#'
#' @examples
#' # Example usage:
#' strlength("hello")        # Returns: 5
#' strlength("R is great!")  # Returns: 11
#'
#' @export
strlength <- function(x) {
  strsplit(x, "") |>
    unlist() |>
    length()
}

#' Converts a vector of tags into a single hash-tagged string
#'
#' @param tags A character vector of tags (e.g., c("R", "Health data")).
#' @return A single string with tags converted to a hash-tagged format (e.g., "#Rstats #HealthData").
#' Specific transformation applied:
#'  - Converts "r" (case insensitive) to "rstats".
#'  - Removes spaces within tags.
#'  - Collapses all elements into one space-separated string.
tags2hash <- function(tags) {
  tags <- paste0("#", tags)
  tags <- sub("^#r$", "#rstats", tags, ignore.case = TRUE)
  tags <- sub(" |-", "", tags, ignore.case = TRUE)
  paste(tags, collapse = " ")
}

#' Optimize Image Size
#'
#' Reads an image, checks its file size, and iteratively reduces its dimensions
#' and/or adjusts quality until it's below a specified maximum file size.
#' It's particularly effective for JPEG images where quality can be adjusted.
#'
#' @param path A character string. The path to the input image file.
#' @param max_size_mb A numeric value. The target maximum file size in megabytes (MB).
#'   Defaults to 1 MB.
#' @param quality A numeric value (0-100). The JPEG quality to use when saving the image.
#'   Lower values result in smaller file sizes but lower quality. Defaults to 80.
#' @param scale_factor A numeric value (0-1). The factor by which image dimensions
#'   are reduced in each iteration if the image is still too large. E.g., 0.9
#'   will reduce dimensions by 10% each time. Defaults to 0.9.
#' @param max_iterations An integer. The maximum number of scaling iterations to attempt.
#'   This prevents infinite loops for unachievable size targets. Defaults to 20.
#'
#' @return A logical value. `TRUE` if the image was successfully optimized and saved,
#'   `FALSE` otherwise. Prints messages during the process.
#' @export
#'
#' @examples
#' \dontrun{
#' # Create a dummy image for demonstration
#' magick::image_write(image_blank(6000, 4000, "red"), path = "large_image.jpg")
#'
#' # Optimize the image to be under 0.5 MB
#' optimize_image_size(
#'   path = "large_image.jpg",
#'   max_size_mb = 0.5,
#'   quality = 75,
#'   scale_factor = 0.95 # More gradual reduction
#' )
#'
#' # Clean up dummy files
#' file.remove("large_image.jpg")
#' file.remove("optimized_image.jpg")
#' }
optimize_image_size <- function(
  path,
  max_size_mb = 1,
  quality = 80,
  scale_factor = 0.9,
  max_iterations = 20
) {
  if (!file.exists(path)) {
    warning("Input image file not found: ", path)
    return(FALSE)
  }

  output_path <- sprintf(
    "%s_reduced.%s",
    tools::file_path_sans_ext(path),
    tools::file_ext(path)
  )

  max_size_bytes <- max_size_mb * 1024 * 1024
  img <- magick::image_read(path)

  # Get initial file size by saving to a temp file and checking its size
  # This is more reliable than image_info for initial check
  temp_initial_path <- tempfile(
    fileext = paste(".", tools::file_ext(path))
  )
  magick::image_write(
    img,
    path = temp_initial_path,
    quality = quality
  )
  current_file_size <- file.size(temp_initial_path)
  file.remove(temp_initial_path) # Clean up temp file

  cat(paste0("Optimizing '", basename(path), "'...\n"))
  cat(paste0(
    "Initial size: ",
    round(current_file_size / (1024 * 1024), 2),
    " MB\n"
  ))
  cat(paste0("Target size: < ", max_size_mb, " MB\n"))

  iteration <- 0

  # Loop to reduce size if necessary
  while (current_file_size > max_size_bytes && iteration < max_iterations) {
    iteration <- iteration + 1
    cat(paste0(
      "Iteration ",
      iteration,
      ": Current size ",
      round(current_file_size / (1024 * 1024), 2),
      " MB.\n"
    ))

    # Reduce dimensions
    img <- magick::image_scale(img, paste0(scale_factor * 100, "%"))

    # Save to a temporary file to check the new size reliably
    temp_output_path <- tempfile(fileext = tools::file_ext(output_path))
    magick::image_write(img, path = temp_output_path, quality = quality)

    # Get the actual file size from the temporary file
    current_file_size <- file.size(temp_output_path)

    # Remove the temporary file
    file.remove(temp_output_path)

    if (iteration == max_iterations && current_file_size > max_size_bytes) {
      warning(paste0(
        "Maximum iterations (",
        max_iterations,
        ") reached. ",
        "Could not reduce image to target size (",
        max_size_mb,
        " MB). Final size: ",
        round(current_file_size / (1024 * 1024), 2),
        " MB."
      ))
      break # Exit loop if max iterations reached
    }
  }

  # Save the final optimized image
  magick::image_write(
    img,
    path = output_path,
    quality = quality
  )

  final_file_size <- file.size(output_path)
  cat(paste0(
    "Optimization complete. Final image saved to '",
    basename(output_path),
    "'.\n"
  ))
  cat(paste0(
    "Final size: ",
    round(final_file_size / (1024 * 1024), 2),
    " MB\n"
  ))

  output_path
}
