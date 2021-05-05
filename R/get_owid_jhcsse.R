
#' Import JHU CSSE data from Our World in Data's github
#'
#' Download URL: https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/full_data.csv
#'
#' @param url raw OWID github URL for JHU CSV
#' @return a tibble dataframe
#' @importFrom magrittr %>%
#' @export
get_owid_jhcsse <- function(url = "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/full_data.csv") {
  df_raw <- readr::read_csv(url, guess_max = 60000)
  df_raw %>%
    dplyr::filter(!location %in% c("International", "World"), !is.na(date)) %>%
    dplyr::mutate(
      iso_a3 = countrycode::countrycode(location, "country.name", "iso3c"),
      iso_a3 = dplyr::case_when(location == "Timor" ~ "TLS", location == "Micronesia (country)" ~ "FSM", TRUE ~ iso_a3),
      continent = countrycode::countrycode(iso_a3, origin = "iso3c", destination = "continent"),
      region = countrycode::countrycode(iso_a3, origin = "iso3c", destination = "region23"),
      continent = dplyr::case_when(location == "Kosovo" ~ "Europe", TRUE ~ continent),
      region = dplyr::case_when(location == "Kosovo" ~ "Southern Europe", TRUE ~ region),
      iso_a3 = dplyr::case_when(location == "Kosovo" ~ "XKX", TRUE ~ iso_a3)
    ) %>%
    dplyr::filter(!is.na(iso_a3)) %>% # filters out continent aggregates
    dplyr::select(date, continent, region, country = location, iso_a3, cases = new_cases, deaths = new_deaths) %>%
    dplyr::mutate_at(dplyr::vars(cases, deaths), ~ ifelse(. < 0, 0L, .))
}
