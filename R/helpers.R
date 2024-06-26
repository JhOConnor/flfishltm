#' @import tidyr dplyr tibble
#' @import ggplot2 viridis stringr
NULL



#' Helper function to add blank rows to account for missing years in a yearly summary table
#'
#' @description
#' currently used within [ltm.data.summary()]
#' 
#' @param sumTable `data.frame` or `tibble` 
#'
#' @return table
#' @export
#'
#' @examples
#' 
#' test_data <- structure(list(
#' Year = c("2006 - 2007", "2007 - 2008", "2008 - 2009","2009 - 2010", 
#'           "2010 - 2011", "2012 - 2013", "2013 - 2014", "2014 - 2015", 
#'           "2015 - 2016", "2019 - 2020", "2020 - 2021"),
#' yr = c(2006, 2007, 2008, 2009, 2010, 2012,2013, 2014, 2015, 2019, 2020),
#' BOW = c(0.226666666666667, 0.24, 0.188, 0.252, 0.132, 0.02, 0.116, 0.112, 
#'         0.064, 0.26, 0.128), LMB = c(0.00666666666666667, 0.0733333333333333, 
#'         0.064, 0.084, 0.04, 0.02, 0.048, 0.148, 0.212, 0.136, 0.12)), 
#'         row.names = c(NA, -11L), class = c("tbl_df", "tbl", "data.frame"))
#'         
#' helper_addgapyears(test_data) 
#'  
#' 
helper_addgapyears <- function(sumTable) {
 
 check_expected_columns(sumTable, c("Year", "yr"))
  
  if(!is.numeric(sumTable$yr)) {
    cli::cli_abort(c("{.arg yr} must be a {.cls numeric} vector",
                   "x" = "You've supplied a {.cls {class(sumTable$yr)}} vector."))
  }
  
  start = min(sumTable$yr, na.rm=TRUE)
  end = max(sumTable$yr, na.rm=TRUE)
  
  tibble::tibble(yr = c(start:end)) %>% 
    left_join(sumTable, by = "yr") %>% 
    relocate(Year) %>% 
    mutate(Year = paste(yr, "-", yr + 1))
  
}
# tt <- test_table()
# ts <- helper_addgapyears(tt)



#' HELPER: check for expected column names
#'
#' @description helper function triggers error if expected column names are missing
#' 
#' @param input_table 
#' @param expected_names 
#'
#' @return NULL
#' @export
#' @examples
#' test_data <- data.frame(col1 = 1, col2 = 2, col3 = "A")
#' check_expected_columns(test_data, c("col1", "col2"))
check_expected_columns <- function(input_table, expected_names) {
  
  expected_missing <- !expected_names %in% names(input_table)
  
  if(any(expected_missing)) {
    cli::cli_abort(c("{sum(expected_missing)} expected column{?s} missing: 
                     {.val {paste(expected_names[expected_missing], 
                     collapse = \", \")}}"))
  }
  
  NULL
  
}


#' INTERNAL: Create a deprecation warning
#'
#' @return warning message
#'
#' @examples
#' deprecated_function <- function() {
#'   deprecate("new_function")
#' }
#' deprecated_function()
deprecate <- function(new_function) {
  calling_function <- deparse(sys.calls()[[sys.nframe()-1]])
  if(is.null(calling_function)) calling_function = "NO PARENT"
  cli::cli_alert_warning(c("{calling_function} is deprecated, please use ",
                          "{.fun {new_function}}"," to silence this warning")) 
  
}


################################################################################################################
################################################################################################################
#' Check if Outlier
#' 
#' Checks whether value is an outlier
#' @param x vector of numerical values
#'
#' @return boolean
#' @examples
#' numbers = c(1:10,1:10,1:10,1000)
#' numbers_outlier <- is.outlier(numbers)
#' numbers[numbers_outlier]#'
#' @export
is.outlier <- function(x) {
  return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
}
