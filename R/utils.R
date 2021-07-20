
#' Formatting Confidence Intervals
#' @export
combine_ci <- function(lwr, upr, digits = 1) {
  x <- sprintf(glue::glue("[%.{digits}f - %.{digits}f]"),
               round(lwr, digits = digits),
               round(upr, digits = digits))
  x <- case_when(str_detect(x, "NA") ~ NA_character_, TRUE ~ x)
  return(x)
}

integer_breaks <- function(n = 5, ...) {
  fxn <- function(x) {
    breaks <- floor(pretty(x, n, ...))
    names(breaks) <- attr(breaks, "labels")
    breaks
  }
  return(fxn)
}
