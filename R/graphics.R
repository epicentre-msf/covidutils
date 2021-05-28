

# Plot cases and deaths and trends into a single graphic plot
#'
#' @param dta daily case and death data for country
#' @param df_trends trend preds etc for country
#' @param add_title add a title to plot?
#'
#' @return ggplot
#' @export
country_plot <- function(
  dta,
  df_trends,
  cases_lab = "cases",
  deaths_lab = "deaths",
  ylab_curve = "Frequency",
  title_curve = "Since the first cases reported",
  title_mdl1 = "Last 30 days",
  title_mdl2 = "Last 14 days",
  ylab_mdl = "Frequency and fitted values",
  caption = "Fitted using a linear regression model",
  add_title = FALSE,
  title = "Covid-19 cases and deaths and trend estimations in"
) {
  # Parameters
  country_id  <- df_trends$country
  main_colour <- c(cases = '#1A62A3', deaths = '#e10000')

  # browser()

  # Table observations
  dta_obs <- dta %>%
    select(date, cases, deaths) %>%
    pivot_longer(-date, names_to = 'obs', values_to = 'n') %>%
    filter(n > 0)

  df_14d <- dta_obs %>% filter(date >= df_trends$date_start_14d, date <= df_trends$date_end_14d)
  df_30d <- dta_obs %>% filter(date >= df_trends$date_start_30d, date <= df_trends$date_end_30d)

  mdl14d_cases_dta  <- pluck(df_trends$trend_cases_preds_14d, 1)
  mdl14d_deaths_dta <- pluck(df_trends$trend_deaths_preds_14d, 1)
  mdl30d_cases_dta  <- pluck(df_trends$trend_cases_preds_30d, 1)
  mdl30d_deaths_dta <- pluck(df_trends$trend_deaths_preds_30d, 1)

  # 14 day model --------------------------------------------------------
  df_14d_cases <- df_14d %>% filter(obs == "cases")
  df_14d_deaths <- df_14d %>% filter(obs == "deaths")

  # Models tables
  if (!is.null(mdl14d_cases_dta)) {
    df_14d_cases  <- df_14d_cases %>%
      left_join(mdl14d_cases_dta %>% mutate(obs = "cases"), by = c("date", "obs"))
  } else {
    df_14d_cases  <- df_14d_cases %>% mutate(fitted = NA_real_, lower_95 = NA_real_, upper_95 = NA_real_)
  }
  if (!is.null(mdl14d_deaths_dta)) {
    df_14d_deaths  <- df_14d_deaths %>%
      left_join(mdl14d_deaths_dta %>% mutate(obs = "deaths"), by = c("date", "obs"))
  } else {
    df_14d_deaths  <- df_14d_deaths %>% mutate(fitted = NA_real_, lower_95 = NA_real_, upper_95 = NA_real_)
  }
  df_14d_plot <- bind_rows(df_14d_cases, df_14d_deaths)

  # 30 day model --------------------------------------------------------
  df_30d_cases <- df_30d %>% filter(obs == "cases")
  df_30d_deaths <- df_30d %>% filter(obs == "deaths")

  # Models tables
  if (!is.null(mdl30d_cases_dta)) {
    df_30d_cases  <- df_30d_cases %>%
      left_join(mdl30d_cases_dta %>% mutate(obs = "cases"), by = c("date", "obs"))
  } else {
    df_30d_cases  <- df_30d_cases %>% mutate(fitted = NA_real_, lower_95 = NA_real_, upper_95 = NA_real_)
  }
  if (!is.null(mdl30d_deaths_dta)) {
    df_30d_deaths  <- df_30d_deaths %>%
      left_join(mdl30d_deaths_dta %>% mutate(obs = "deaths"), by = c("date", "obs"))
  } else {
    df_30d_deaths  <- df_30d_deaths %>% mutate(fitted = NA_real_, lower_95 = NA_real_, upper_95 = NA_real_)
  }
  df_30d_plot <- bind_rows(df_30d_cases, df_30d_deaths)

  # Plots ---------------------------------------------------------------------
  labels_facets <- c(cases = cases_lab, deaths = deaths_lab)
  plot_obs <- ggplot(dta_obs, aes(x = date, y = n)) +
    facet_wrap(~obs, scales = "free_y", ncol = 1, labeller = labeller(obs = labels_facets)) +
    geom_col(aes(colour = obs, fill = obs)) +
    scale_colour_manual(values = main_colour) +
    scale_fill_manual(values = main_colour) +
    scale_x_date(labels = scales::label_date_short()) +
    scale_y_continuous(expand = expansion(mult = c(0, .1))) +
    xlab(NULL) +
    ylab(ylab_curve) +
    labs(subtitle = title_curve) +
    theme_light() +
    theme(
      legend.position = "none",
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.minor.y = element_blank(),
      strip.text = element_text(face = "bold", size = 11)
    )

  plot_mdl1 <- ggplot(df_30d_plot, aes(x = date, y = n)) +
    facet_wrap(~ obs, scales = "free_y", ncol = 1, labeller = labeller(obs = labels_facets)) +
    geom_point(aes(colour = obs), size = 2) +
    scale_colour_manual(values = main_colour) +
    geom_ribbon(aes(ymin = lower_95, ymax = upper_95, fill = obs), alpha = 0.4) +
    geom_line(aes(y = fitted, colour = obs), size = 1) +
    scale_fill_manual(values = main_colour) +
    scale_x_date(date_breaks = "5 days", labels = scales::label_date_short()) +
    xlab(NULL) +
    ylab(ylab_mdl) +
    labs(subtitle = title_mdl1) +
    theme_light() +
    theme(legend.position = "none", strip.text = element_text(face = "bold", size = 11))


  plot_mdl2 <- ggplot(df_14d_plot, aes(x = date, y = n)) +
    facet_wrap(~ obs, scales = "free_y", ncol = 1, labeller = labeller(obs = labels_facets)) +
    geom_point(aes(colour = obs), size = 2) +
    scale_colour_manual(values = main_colour) +
    geom_ribbon(aes(ymin = lower_95, ymax = upper_95, fill = obs), alpha = 0.4) +
    geom_line(aes(y = fitted, colour = obs), size = 1) +
    scale_fill_manual(values = main_colour) +
    scale_x_date(date_breaks = "2 days", labels = scales::label_date_short()) +
    xlab(NULL) +
    ylab(NULL) +
    labs(subtitle = title_mdl2) +
    theme_light() +
    theme(legend.position = "none", strip.text = element_text(face = "bold", size = 11))


  library(patchwork)
  # Arrange plots
  multiplot <- plot_obs +
    plot_mdl1 +
    plot_mdl2 +
    plot_layout(ncol = 3, widths = c(2, 1.4, 1.1)) +
    plot_annotation(caption = caption)

  if (add_title) {
    multiplot <- multiplot + plot_annotation(title = paste(title, country_id))
  }

  return(multiplot)
}

#' gt country summary table
#'
#' @param df_trends filtered to one country
#' @import gt
#' @return gt table
#' @export
country_table <- function(df_trends) {
  require(gt)
  require(dplyr)
  require(stringr)

  tbl_summary_country <- df_trends %>%
    select(starts_with("cases"), starts_with("deaths"), starts_with("dt_")) %>%
    tidyr::pivot_longer(everything()) %>%
    mutate(period = case_when(
      str_detect(name, "_14d") ~ "Last 14 days",
      str_detect(name, "_30d") ~ "Last 30 days",
      TRUE ~ "Total"
    ), .before = 1) %>%
    mutate(name = str_remove(name, "_14d|_30d")) %>%
    tidyr::pivot_wider(names_from = "name", values_from = "value") %>%
    mutate(cfr = (deaths/cases) * 100) %>%
    mutate(dt_cases_ci = combine_ci(dt_cases_lwr, dt_cases_upr), .after = dt_cases_est) %>%
    mutate(dt_deaths_ci = combine_ci(dt_deaths_lwr, dt_deaths_upr), .after = dt_deaths_est) %>%
    select(-matches("_lwr|_upr")) %>%
    select(period, cases, deaths, cfr, cases_inc, deaths_inc, everything())

  gt(tbl_summary_country) %>%
    cols_label(
      period = 'Period',
      cases  = 'Cases',
      deaths = 'Deaths',
      cfr = 'naive CFR',
      cases_inc = 'Cases',
      deaths_inc = 'Deaths',
      dt_cases_est = 'Rate',
      dt_cases_ci  = '[95% CI]',
      dt_deaths_est = 'Rate',
      dt_deaths_ci = '[95% CI]') %>%
    tab_spanner(
      label = 'Count',
      columns = vars(cases, deaths)) %>%
    tab_spanner(
      label = html(paste('Cumulative incidence<br> per', format(100000, scientific = FALSE, big.mark = ','), 'pop')),
      columns = vars(cases_inc, deaths_inc)) %>%
    tab_spanner(
      label = html('Doubling time<br>in cases'),
      columns = vars(dt_cases_est, dt_cases_ci)) %>%
    tab_spanner(
      label = html('Doubling time<br>in deaths'),
      columns = vars(dt_deaths_est, dt_deaths_ci)) %>%
    fmt_number(
      columns = vars(cases, cases_inc, deaths, deaths_inc),
      decimals = 0) %>%
    fmt_number(
      columns = vars(cfr, dt_cases_est, dt_deaths_est),
      decimals = 1) %>%
    fmt_missing(
      columns = vars(dt_cases_est, dt_cases_ci, dt_deaths_est, dt_deaths_ci),
      rows = 1,
      missing_text = '') %>%
    fmt_missing(
      columns = vars(dt_cases_est, dt_cases_ci, dt_deaths_est, dt_deaths_ci),
      rows = c(2:3),
      missing_text = '---') %>%
    tab_options(
      column_labels.font.weight = "bold",
      data_row.padding = px(1))
}
