
#' Get summary df of country cases, deaths and trends etc
#'
#' @param df_jhu dataframe output from [`get_owid_jhcsse()`]
#' @param inc_factor incidence factor. defaults to 100 000
#'
#' @return tibble
#' @export
get_country_summaries <- function(df_jhu, inc_factor = 100000) {
  df_summary <- get_owid_summary()

  df_trends_14d <- get_trends(df_jhu, time_unit_extent = 14)
  df_trends_30d <- get_trends(df_jhu, time_unit_extent = 30)
  df_trends <- dplyr::left_join(df_trends_14d, df_trends_30d, by = "iso_a3", suffix = c("_14d", "_30d"))

  df_export <-
    dplyr::inner_join(df_summary, df_trends, by = "iso_a3") %>%
    dplyr::mutate( # add incidence per 100 000
      cases_inc = cases/population  * inc_factor,
      deaths_inc = deaths/population * inc_factor,
      .after = deaths
    ) %>%
    dplyr::mutate(
      cases_inc_14d = cases_14d/(population - cases + cases_14d)  * inc_factor,
      deaths_inc_14d = deaths_14d/(population - cases + deaths_14d) * inc_factor,
      .after = deaths_14d
    ) %>%
    dplyr::mutate(
      cases_inc_30d = cases_30d/(population - cases + cases_30d)  * inc_factor,
      deaths_inc_30d = deaths_30d/(population - cases + deaths_30d) * inc_factor,
      .after = deaths_30d
    )

  df_export
}

#' Import JHU CSSE data from Our World in Data's github
#'
#' Download URL: https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/full_data.csv
#'
#' @param url raw OWID github URL for JHU CSV
#' @return a tibble dataframe
#' @importFrom magrittr %>%
#' @export
get_owid_jhcsse <- function(url = "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/jhu/full_data.csv") {
  rm_non_countries <- c("International", "World", "Africa", "Asia", "Europe", "European Union", "North America", "Oceania", "South America")
  df_raw <- readr::read_csv(url, guess_max = 60000)
  df_raw %>%
    dplyr::filter(!location %in% rm_non_countries, !is.na(date)) %>%
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

#' Import OWID covid summaries per country
#'
#' Download URL: https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/latest/owid-covid-latest.csv
#'
#' @param url OWID covid latest github URL
#' @return a tibble dataframe
#' @export
get_owid_summary <- function(url = "https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/latest/owid-covid-latest.csv") {
  df_owid_latest <- readr::read_csv(url)
  df_owid_latest %>%
    dplyr::filter(stringr::str_detect(iso_code, "OWID_", negate = TRUE)) %>%
    dplyr::transmute(
      location,
      iso_a3 = iso_code,
      population,
      cases = total_cases,
      deaths = total_deaths
    ) %>%
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
    dplyr::select(continent, region, country = location, iso_a3, dplyr::everything())
}

