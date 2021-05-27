
#' Formatting Confidence Intervals
#' @export
combine_ci <- function(lwr, upr, digits = 1) {
  x <- sprintf(glue::glue("[%.{digits}f - %.{digits}f]"),
               round(lwr, digits = digits),
               round(upr, digits = digits))
  x <- case_when(str_detect(x, "NA") ~ NA_character_, TRUE ~ x)
  return(x)
}
