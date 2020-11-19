
#' Import ECDC data
#'
#' get data from https://opendata.ecdc.europa.eu/covid19/casedistribution/csv or from https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide.xlsx
#'
#'
#' @return a tibble dataframe
#' @importFrom magrittr %>%
#' @export
#'
get_ecdc_data <- function() {

  base_url <- "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv"
  xlsx_url <- "https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide.xlsx"

  error <- suppressMessages(
    suppressWarnings(try(readr::read_csv(file = base_url), silent = TRUE))
  )

  if ("try-error" %in% class(error)) {
    message("csv unavailable, trying xlsx")
    httr::GET(xlsx_url, httr::write_disk(tf <- tempfile(fileext = ".xlsx")))
    readxl::read_excel(tf)
  } else {
    readr::read_csv(base_url)
  }

}
