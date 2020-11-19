
#' Prepare ECDC data
#'
#' Performs standardisation of country names and infers ISO3, continent and region data using the countrycode::countrycode function.
# Adjust for one-day lag, because ECDC reports at 10am CET the next day. Complete missing infos.
#'
#'
#' @param dta dataframe generated from [get_ecdc_data()]
#'
#' @return a tibble dataframe
#' @importFrom magrittr %>%
#' @export
#'
prepare_ecdc_data <- function(dta){

  dta %>%
    dplyr::mutate(date = lubridate::make_date(year, month, day) - 1) %>%
    dplyr::select(date, geoid = geoId, country_ecdc = countriesAndTerritories, iso_a3 = countryterritoryCode, population_2019 = popData2019, cases, deaths) %>%
    dplyr::arrange(date) %>%
    dplyr::mutate_at(dplyr::vars(cases, deaths), ~ifelse(. < 0, 0L, .)) %>%
    dplyr::mutate(
      country = countrycode::countrycode(iso_a3, origin = "iso3c", destination = "country.name"),
      country = dplyr::case_when(
        country == "Congo - Kinshasa" ~ "Democratic Republic of the Congo",
        country == "Congo - Brazzaville" ~ "Republic of Congo",
        country_ecdc == 'Cases_on_an_international_conveyance_Japan' ~ 'Cruise Ship',
        is.na(country) ~ gsub('_', ' ', country_ecdc),
        TRUE ~ country),
      iso_a3 = dplyr::case_when(
        country == 'Kosovo' ~ 'XKX',
        country == 'Anguilla' ~ 'AIA',
        country == 'Bonaire, Saint Eustatius and Saba' ~ 'BES',
        country == 'Falkland Islands (Malvinas)' ~ 'FLK',
        country == 'Montserrat' ~ 'MSR',
        country == 'Taiwan' ~ 'TWN',
        country == 'Western Sahara' ~ 'ESH',
        country == 'Cruise Ship' ~ NA_character_,
        TRUE ~ iso_a3),
      continent = countrycode::countrycode(iso_a3, origin = 'iso3c', destination = 'continent'),
      continent = dplyr::case_when(
        country == 'Kosovo' ~ 'Europe',
        country == 'Cruise Ship' ~ 'Undefined',
        is.na(country) ~ "Unknown",
        TRUE ~ continent),
      region = countrycode::countrycode(iso_a3, origin = "iso3c", destination = "region23"),
      region = dplyr::case_when(
        country == 'Kosovo' ~ 'Southern Europe',
        country == 'Cruise Ship' ~ 'Undefined',
        is.na(country) ~ "Unknown",
        TRUE ~ region),
      source = "ECDC"
    ) %>%
    dplyr::select(date, country_ecdc:geoid, country:region, iso_a3, cases, deaths, population_2019, source)

}
