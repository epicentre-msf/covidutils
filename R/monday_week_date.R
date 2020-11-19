
#' Return a date variable set to the Monday of the week
#'
#' Function that return for any day of the week a date set to the Monday of that week.
#'
#' @param date a date
#'
#' @return
#' @export
#'
monday_week_date <- function(date) {
  lubridate::wday(date, week_start = 1) <- 1
  return(date)
}
