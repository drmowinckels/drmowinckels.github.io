.vars <- dplyr::quos(...)
if (!missing(value)) {
  value_var <- dplyr::enquo(value)
  out <- .df %>%
    dplyr::select(!!!.vars, value = !!value_var) %>%
    dplyr::mutate(..r = dplyr::row_number()) %>%
    tidyr::gather(x, node, -..r, -value) %>%
    dplyr::arrange(.data$..r) %>%
    dplyr::group_by(.data$..r) %>%
    dplyr::mutate(
      next_x = dplyr::lead(.data$x),
      next_node = dplyr::lead(.data$node)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-..r) %>%
    dplyr::relocate(value, .after = dplyr::last_col())
}
else
{
  out <- .df %>%
    dplyr::select(!!!.vars) %>%
    dplyr::mutate(..r = dplyr::row_number()) %>%
    tidyr::gather(x, node, -..r) %>%
    dplyr::arrange(.data$..r) %>%
    dplyr::group_by(.data$..r) %>%
    dplyr::mutate(
      next_x = dplyr::lead(.data$x),
      next_node = dplyr::lead(.data$node)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(-..r)
}
levels <- unique(out$x)
out %>% dplyr::mutate(dplyr::across(c(x, next_x), ~ factor(., levels = levels)))
