#' Compute case and deaths trends
#'
#' @param df JHSU CSSE data
#' @param time_unit_extent defaults to 14 days
#'
#' @return tibble
#' @export
get_trends <- function(df,
                       time_unit_extent = 14,
                       omit_past_days = 2,
                       add_ci         = TRUE,
                       add_dt         = TRUE,
                       add_preds      = TRUE) {

  ## get trends
  trends_all <- df %>%
    dplyr::group_by(iso_a3) %>%
    tidyr::nest() %>%
    dplyr::mutate(model = map(data, model_trends, time_unit_extent, omit_past_days, add_ci, add_preds, add_dt)) %>%
    dplyr::select(-data) %>%
    tidyr::unnest(model)

  return(trends_all)
}

#' @noRd
#' @keywords internal
model_trends <- function(x,
                         time_unit_extent,
                         omit_past_days,
                         add_ci    = TRUE,
                         add_dt    = TRUE,
                         add_preds = TRUE,
                         ma_window = 3,
                         min_sum   = 30) {

  # don't include latest 2 days as likely data is incomplete
  last_date <- max(x$date, na.rm = TRUE) - omit_past_days
  dates_extent <- c(last_date - (time_unit_extent - 1), last_date)

  # filter data to date range of interest
  xsub <- x %>%
    dplyr::filter(dplyr::between(date, dates_extent[1], dates_extent[2])) %>%
    tidyr::complete(
      date = seq.Date(min(date, na.rm = TRUE), max(date, na.rm = TRUE), by = 1),
      fill = list(cases = NA_real_, deaths = NA_real_)
    )

  t_cases <- get_country_trend(xsub, "cases", min_sum, ma_window)
  t_deaths <- get_country_trend(xsub, "deaths", min_sum, ma_window)

  df_out <- tibble::tibble(
    date_start         = dates_extent[1],
    date_end           = dates_extent[2],
    cases              = sum(xsub$cases, na.rm = TRUE),
    trend_cases        = t_cases$trend,
    trend_cases_coeff  = t_cases$coeff,
    deaths             = sum(xsub$deaths, na.rm = TRUE),
    trend_deaths       = t_deaths$trend,
    trend_deaths_coeff = t_deaths$coeff
  )

  if (add_ci) {
    df_out <- df_out %>%
      dplyr::mutate(
        trend_cases_coeff_lwr95 = t_cases$lwr95,
        trend_cases_coeff_upr95 = t_cases$upr95,
        trend_deaths_coeff_lwr95 = t_deaths$lwr95,
        trend_deaths_coeff_upr95 = t_deaths$upr95
      )
  }

  if (add_preds) {
    df_out <- df_out %>%
      dplyr::mutate(
        trend_cases_preds = t_cases$preds,
        trend_deaths_preds = t_deaths$preds
      )
  }

  if (add_dt) {
    df_out <- df_out %>%
      dplyr::mutate(
        dt_cases_est = t_cases$dt_est,
        dt_cases_lwr = t_cases$dt_lwr,
        dt_cases_upr = t_cases$dt_upr,
        dt_deaths_est = t_deaths$dt_est,
        dt_deaths_lwr = t_deaths$dt_lwr,
        dt_deaths_upr = t_deaths$dt_upr
      )
  }

  df_out %>% dplyr::select(dplyr::starts_with("date_"), dplyr::contains("cases"), dplyr::contains("deaths"))

}

#' @noRd
#' @keywords internal
get_country_trend <- function(xsub, var, min_sum, ma_window) {
  if (nrow(xsub) > ma_window & sum(xsub[[var]], na.rm = TRUE) > min_sum) {
    # moving average
    xsub$ma <- as.numeric(forecast::ma(xsub[[var]], order = ma_window))
    xsub$ma <- dplyr::na_if(xsub$ma, 0) # PB: I don't think this is good idea, but kept from prev code

    # linear model and confidence intervals
    mdl <- lm(log(ma) ~ date, data = xsub)
    ci80 <- confint(mdl, level = 0.80)
    ci95 <- confint(mdl, level = 0.95)
    preds <- dplyr::transmute(
      broom::augment(mdl, interval = "confidence", conf.int = TRUE, conf.level = 0.95),
      date, fitted = exp(.fitted), lower_95 = exp(.lower), upper_95 = exp(.upper)
    ) %>%
      dplyr::left_join(
        broom::augment(mdl, interval = "confidence", conf.int = TRUE, conf.level = 0.80) %>%
          dplyr::transmute(date, lower_80 = exp(.lower), upper_80 = exp(.upper)),
        by = "date"
      )

    # prep output
    df_out <- tibble::tibble(
      coeff = coefficients(mdl)[[2]],
      lwr80  = ci80[2,1],
      upr80  = ci80[2,2],
      lwr95  = ci95[2,1],
      upr95  = ci95[2,2],
      preds = list(preds)
    ) %>%
      dplyr::transmute(
        coeff,
        lwr95,
        upr95,
        preds,
        trend = case_when(
          lwr95 > 0 ~ "Increasing",
          lwr95 <= 0 & lwr80 > 0 ~ "Likely increasing",
          upr95 < 0 ~ "Decreasing",
          upr95 >= 0 & upr80 < 0  ~ "Likely decreasing",
          lwr80 < 0 & upr80 > 0 ~ "Stable",
          TRUE ~ NA_character_
        ),
        dt_est = ifelse(trend %in% c("Increasing", "Likely increasing"), log(2)/coeff, NA_real_),
        dt_lwr = ifelse(trend %in% c("Increasing", "Likely increasing"), log(2)/upr95, NA_real_),
        dt_upr = ifelse(trend %in% c("Increasing", "Likely increasing"), log(2)/lwr95, NA_real_)
      )
  } else {
    tibble::tibble(coeff = NA_real_,
                   trend = NA_character_,
                   lwr95 = NA_real_,
                   upr95 = NA_real_,
                   preds = NA,
                   dt_est = NA_real_,
                   dt_lwr = NA_real_,
                   dt_upr = NA_real_)
  }
}


