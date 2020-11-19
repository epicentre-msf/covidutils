
#' Combine care
#'
#' Specific function that combine 'twin' variables of patient's care at admission (`var1`) and at discharge (`var2`) in to a single variable. Input variable is coded with values 'Yes' or 'No'. Output variable is code with values 'Yes', 'No at admission then not reported', 'No at any time' or 'Not reported'.
#'
#' @param var1 variable at admission
#' @param var2 variable at discharge
#'
#' @return a character vector
#' @export
#'
combine_care <- function(var1, var2){
  case_when(
    var1 == 'Yes' | var2 == 'Yes' ~ 'Yes',
    var1 == 'No' & (var2 == 'Unknown' | is.na(var2)) ~ 'No at admission then not reported',
    (var1 == 'No' | is.na(var1)) & var2 == 'No' ~ 'No at any time',
    TRUE ~ 'Not reported') %>%
    factor(levels = c('Yes', 'No at admission then not reported', 'No at any time', 'Not reported'))
}
