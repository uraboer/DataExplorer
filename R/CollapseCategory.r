#' Collapse categories for discrete features
#'
#' Sometimes discrete features have sparse categories. This function will collapse the sparse categories for a discrete feature based on a given threshold.
#' @param data input data, in either \link{data.frame} or \link{data.table} format.
#' @param feature name of the discrete feature to be collapsed.
#' @param threshold the bottom x\% categories to be collapsed, e.g., if set to 20\%, categories with cumulative frequency of the bottom 20\% will be collapsed.
#' @param update logical, indicating if the data should be modified. Setting to \code{TRUE} will modify the input data directly, and \bold{will only work with \link{data.table}}. The default is \code{FALSE}.
#' @param measure name of variable to be treated as additional measure to frequency.
#' @param category_name name of the bucket to group selected categories if update is set to \code{TRUE}. The default is "OTHER".
#' @keywords collapsecategory
#' @return If update is set to \code{FALSE}, returns categories with cumulative frequency less than the input threshold. The output class will match the class of input data.
#' @details If a continuous feature is passed to the argument \code{feature}, it will be force set to \link{character-class}.
#' @import data.table
#' @export
#' @examples
#' # load packages
#' library(data.table)
#'
#' # generate data
#' data <- data.table("a" = as.factor(round(rnorm(500, 10, 5))), "b" = rexp(500, 1:500))
#'
#' # view cumulative frequency without collpasing categories
#' CollapseCategory(data, "a", 0.2)
#'
#' # view cumulative frequency based on another measure
#' CollapseCategory(data, "a", 0.2, measure = "b")
#'
#' # collapse bottom 20% categories based on cumulative frequency
#' CollapseCategory(data, "a", 0.2, update = TRUE)
#' BarDiscrete(data)

CollapseCategory <- function(data, feature, threshold, measure, update = FALSE, category_name = "OTHER") {
  ## Declare variable first to pass R CMD check
  cnt <- pct <- cum_pct <- NULL
  ## Check if input is data.table
  is_data_table <- is.data.table(data)
  ## Detect input data class
  data_class <- class(data)
  ## Set data to data.table
  if (!is_data_table) {data <- data.table(data)}
  ## Set feature to discrete
  set(data, j = feature, value = as.character(data[[feature]]))
  if (missing(measure)) {
    ## Count frequency of each category and order in descending order
    var <- data[, list(cnt = .N), by = feature][order(-cnt)]
  } else {
    var <- data[, list(cnt = sum(get(measure))), by = feature][order(-cnt)]
  }
  ## Calcualte cumulative frequency for each category
  var[, pct := cnt / sum(cnt)][, cum_pct := cumsum(pct)]
  ## Identify categories not to be collapased based on input threshold
  top_cat <- var[cum_pct <= (1 - threshold), get(feature)]
  ## Collapse categories if update is true, else return distribution for analysis
  if (update) {
    if (!is_data_table) stop("Please change your input data class to data.table to update!")
    data[!(get(feature) %in% top_cat), c(feature) := category_name]
  } else {
    output <- var[cum_pct <= (1 - threshold)]
    class(output) <- data_class
    return(output)
  }
}
