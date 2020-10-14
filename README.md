
<!-- README.md is generated from README.Rmd. Please edit that file -->

# covidutils

<!-- badges: start -->

<!-- badges: end -->

Centralised utility functions for covid related projects at Epicentre.

## Installation

Install covidutils from github with:

``` r
remotes::install_github("epicentre-msf/covidutils")
```

## Development

To include a function in the package, add it to a script in the `R/`
directory.

### Best practices

  - Large functions should have their own `.R` script inside the `R/`
    directory with an information name, `get_ecdc.R` for example
  - Smaller utility functions can be grouped into a single script such
    as `utils.R`
  - If you are using functions used from external packages inside your
    own function, they must be fully qualified i.e. `dplyr::filter()`
  - All external packages used must be added to the imports section of
    the `DESCRIPTION` file. This can be done via
    `usethis::use_package("name_of_package")`
  - All variables used within a function should be passed as arguments
  - Document your functions using [roxygen
    syntax](https://roxygen2.r-lib.org/)
  - When your changes are ready and documented:
      - run `devtools::document()` to build the appropriate
        documentation files
      - run `devtools::check()` to check the package for any errors or
        warnings
      - run `devtools::install()` to install or re-install the package
        on your system
      - consider adding a usage of example of any new functions in this
        `README.Rmd` below then knit the document to produce the `.md`
        format required for github
      - push the changes to github

If using RStudio, you can document, check and install the package with
option in the ‘Build’ pane.

When developing new functions you can run `devtools::load_all()` at
anytime load the current state of all function in the `R/` directory.

## Function examples

``` r
library(covidutils)
```

### Import ECDC data

``` r
df_ecdc <- get_ecdc_data()

df_ecdc
#> # A tibble: 48,943 x 11
#>    date       country_ecdc geoid country continent region iso_a3 cases deaths
#>    <date>     <chr>        <chr> <chr>   <chr>     <chr>  <chr>  <dbl>  <dbl>
#>  1 2019-12-30 Afghanistan  AF    Afghan… Asia      South… AFG        0      0
#>  2 2019-12-30 Algeria      DZ    Algeria Africa    North… DZA        0      0
#>  3 2019-12-30 Armenia      AM    Armenia Asia      Weste… ARM        0      0
#>  4 2019-12-30 Australia    AU    Austra… Oceania   Austr… AUS        0      0
#>  5 2019-12-30 Austria      AT    Austria Europe    Weste… AUT        0      0
#>  6 2019-12-30 Azerbaijan   AZ    Azerba… Asia      Weste… AZE        0      0
#>  7 2019-12-30 Bahrain      BH    Bahrain Asia      Weste… BHR        0      0
#>  8 2019-12-30 Belarus      BY    Belarus Europe    Easte… BLR        0      0
#>  9 2019-12-30 Belgium      BE    Belgium Europe    Weste… BEL        0      0
#> 10 2019-12-30 Brazil       BR    Brazil  Americas  South… BRA        0      0
#> # … with 48,933 more rows, and 2 more variables: population_2019 <dbl>,
#> #   source <chr>
```
