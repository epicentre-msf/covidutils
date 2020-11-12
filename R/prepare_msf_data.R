
#' Prepare MSF Covid linelist data
#'
#' This function clean incoherences, standardise/factorise main variables and create new variables that are used in different analyses
#'
#' @param dta The raw linelist downloaded
#' @param shorten_var_names Shorten the names of the variables by removing suffixes such as "MSF_", "patinfo_", "patcourse_"
#'
#' @return
#' @export
#'
#' @examples
prepare_msf_dta <- function(dta, shorten_var_names = FALSE){

  ## --- CLEAN ---

  dta <- dta %>%
    mutate(
      age_in_years = case_when(
        age_in_years > 110 ~ NA_real_,
        TRUE ~ age_in_years),
      Comcond_immuno = case_when(
        grepl('Positive', MSF_hiv_status) ~ 'Yes',
        TRUE ~ Comcond_immuno),
      Comcond_cardi = case_when(
        MSF_hypertension == 'Yes' ~ 'Yes',
        TRUE ~ Comcond_cardi))


  ## --- PREPARE ---

  ## Create variable levels
  levels_covid_status <- c('Confirmed', 'Probable', 'Suspected', 'Not a case', '(Unknown)')
  levels_outcome_status <- c('Cured', 'Died', 'Left against medical advice', 'Transferred', 'Sent back home', 'Other')
  levels_ynu <- c('Yes', 'No', '(Unknown)')


  ## Factorise variables
  dta <- dta %>%
    mutate(
      MSF_covid_status = factor(MSF_covid_status, levels = levels_covid_status) %>% forcats::fct_explicit_na(na_level = '(Unknown)'))


  ## Standardise dates (and weeks)
  dta <- dta %>%
    mutate(
      MSF_date_consultation = as.Date(MSF_date_consultation),
      outcome_patcourse_status = factor(outcome_patcourse_status, levels = levels_outcome_status) %>% forcats::fct_explicit_na(na_level = '(Pending/Unknown)'),
      epi_week_report = make_epiweek_date(report_date),
      epi_week_consultation = make_epiweek_date(MSF_date_consultation),
      epi_week_admission = make_epiweek_date(patcourse_presHCF),
      epi_week_onset = make_epiweek_date(patcourse_dateonset)
    )


  ## Create age groups
  age_breaks_5 <- c(0, 5, 15, 45, 65, Inf)
  age_labels_5 <- label_breaks(age_breaks_5, exclusive = TRUE)

  age_breaks_9 <- c(seq(0, 80, 10), Inf)
  age_labels_9 <- label_breaks(age_breaks_9, exclusive = TRUE)

  dta <- dta %>%
    mutate(
      age_in_years = floor(age_in_years),
      age_5gp = cut(age_in_years, breaks = age_breaks_5, labels = age_labels_5, include.lowest = TRUE, right = FALSE),
      age_9gp = cut(age_in_years, breaks = age_breaks_9, labels = age_labels_9, include.lowest = TRUE, right = FALSE)
    )


  ## Recoding Comorbidities as Yes/No
  dta <- dta %>%
    mutate(
      MSF_malaria = case_when(
        MSF_malaria == 'Positive' ~ 'Yes',
        MSF_malaria == 'Negative' ~ 'No',
        MSF_malaria %in% c('Inconclusive', 'Not done') ~ 'Unknown',
        TRUE ~ MSF_malaria),
      MSF_hiv_status = case_when(
        MSF_hiv_status %in% c('Positive (no ARV)', 'Positive (on ART)', 'Positive (unknown)') ~ 'Yes',
        MSF_hiv_status == 'Negative' ~ 'No',
        TRUE ~ MSF_hiv_status),
      MSF_tb_active = case_when(
        MSF_tb_active %in% c('Yes (currently no treatment)', 'Yes (currently on treatment)', 'Yes (unknown)') ~ 'Yes',
        TRUE ~ MSF_tb_active),
      MSF_smoking = case_when(
        MSF_smoking %in% c('Yes (current)', 'Yes (former)') ~ 'Yes',
        TRUE ~ MSF_smoking))


  ## Recode presence of comorbidities including the MSF ones
  Comcond_count <- rowSums(select(dta, starts_with('Comcond_'), MSF_hiv_status, MSF_hypertension, MSF_tb_active, MSF_malaria, MSF_malnutrition, MSF_smoking) == "Yes", na.rm = TRUE)

  Comcond_01 <- ifelse(Comcond_count > 0, 1, 0)

  dta <- cbind(dta, Comcond_count, Comcond_01)


  ## Patients' care variables
  dta <- dta %>%
    mutate(
      patcourse_admit = factor(patcourse_admit, levels = levels_ynu) %>% forcats::fct_explicit_na(na_level = levels_ynu[3]),
      outcome_patcourse_admit = factor(outcome_patcourse_admit, levels = levels_ynu) %>% forcats::fct_explicit_na(na_level = '(Unknown)'),
      merge_admit = case_when(
        patcourse_admit == 'Yes' ~ levels_ynu[1],
        outcome_patcourse_admit == 'Yes' ~ levels_ynu[1],
        is.na(outcome_patcourse_admit) ~ levels_ynu[3],
        TRUE ~ levels_ynu[2]) %>% factor(levels = levels_ynu),
      merge_oxygen = recode_care(MSF_received_oxygen, MSF_outcome_received_oxygen),
      merge_icu    = recode_care(patcourse_icu , outcome_patcourse_icu),
      merge_vent   = recode_care(patcourse_vent, outcome_patcourse_vent),
      merge_ecmo   = recode_care(patcourse_ecmo, outcome_patcourse_ecmo))


  ## --- SHORTEN variable names ---
  if (shorten_var_names) {

    var_names_stub <- c('^patinfo_', '^patcourse_', '^MSF_', '_patcourse')

    for (i in var_names_stub) {
      names(dta) <- gsub(i, '', names(dta))
    }

  }

  return(as_tibble(dta))
}

