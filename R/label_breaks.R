#' Label breaks
#'
#' Create two-sided labels from a sequence of values
#'
#' @param breaks a vector with break values (`Inf` may be included)
#' @param exclusive logical, indicating whether the right side of the label should display a mutually exclusive value with the left side of the following label. If FALSE (default), the labels display not mutually exclusive values (i.e. "1-10", 10-100", etc.). If TRUE the labels display mutually exclusive values (i.e. "1-9", 10-99", etc.).
#' @param add_Inf logical, if TRUE (default), and if not already present, the value `Inf` is added as last value. If TRUE the length of the output vector is of the same input vector. If FALSE the length of the output vector is the length of the input vector -1.
#' @param replace_Inf logical, if TRUE (default) the value `Inf` is replaced by a +.
#'
#' @return a vector of the same length of the input vector of length of the input vector - 1 if `add_Inf` is set as FALSE.
#' @export
#'
#' @examples
#' x <- c(1, 10, 100, Inf)
#' label_breaks(x)
#' label_breaks(x, exclusive = TRUE)
#' label_breaks(x, exclusive = FALSE, replace_Inf = TRUE)
#'
#' y <- c(1, 10, 100)
#' label_breaks(y)
#' label_breaks(y, exclusive = TRUE) # same length of input vector
#' label_breaks(y, exclusive = FALSE, add_Inf = FALSE) # length of input vector - 1
label_breaks <- function(breaks, exclusive = FALSE, add_Inf = TRUE, replace_Inf = TRUE) {

  if (is.unsorted(breaks, strictly = TRUE))
    stop('The values need to be in strict increasing order.')

  if (add_Inf && !any(is.infinite(breaks))) {
    breaks[length(breaks) + 1] <- Inf
  }

  if (exclusive){
    lbls <- sprintf("%s-%s", prettyNum(breaks[-length(breaks)], big.mark = ' '), prettyNum(breaks[-1] - 1, big.mark = ' '))
  } else {
    lbls <- sprintf("%s-%s", scales::label_number_si()(breaks[1:length(breaks) - 1]), scales::label_number_si()(breaks[2:length(breaks)]))
  }

  if(replace_Inf){
    lbls <- gsub("-Inf", "+", lbls)
  }

  return(lbls)
}
