#' Create bar charts for discrete features
#'
#' This function creates frequency bar charts for each discrete feature.
#' @param data input data to be plotted, in either \link{data.frame} or \link{data.table} format.
#' @param na.rm logical, indicating if missing values should be removed for each feature. The default is \code{TRUE}.
#' @param maxcat maximum categories allowed for each feature. The default is 50. More information in 'Details' section.
#' @param order_bar logical, indicating if bars should be ordered.
#' @keywords bardiscrete
#' @details If a discrete feature contains more categories than \code{maxcat} specifies, it will not be passed to the plotting function.
#' @import data.table
#' @import ggplot2
#' @importFrom scales comma
#' @importFrom stats na.omit reorder
#' @import gridExtra
#' @export
#' @examples
#' # load packages
#' library(ggplot2)
#' library(data.table)
#'
#' # load diamonds dataset from ggplot2
#' data("diamonds")
#'
#' # plot bar charts for diamonds dataset
#' BarDiscrete(diamonds)
#' BarDiscrete(diamonds, maxcat = 5)

BarDiscrete <- function(data, na.rm = TRUE, maxcat = 50, order_bar = TRUE) {
  ## Declare variable first to pass R CMD check
  frequency <- NULL
  ## Check if input is data.table
  if (!is.data.table(data)) {data <- data.table(data)}
  ## Stop if no discrete features
  if (SplitColType(data)$num_discrete == 0) stop("No Discrete Features")
  ## Get discrete features
  discrete <- SplitColType(data)$discrete
  ## Get number of categories for each feature
  n_cat <- sapply(discrete, function(x) {length(unique(x))})
  ign_ind <- which(n_cat > maxcat)
  if (length(ign_ind) > 0) {
    set(discrete, j = ign_ind, value = NULL)
    message(length(ign_ind), " columns ignored with more than ", maxcat, " categories.\n", paste0(names(ign_ind), ": ", n_cat[ign_ind], " categories\n"))
  }
  ## Get dimension
  n <- nrow(discrete)
  p <- ncol(discrete)
  ## Calculate number of pages if showing 9 features on each page
  pages <- ceiling(p / 9)
  for (pg in 1:pages) {
    ## Subset data by column
    subset_data <- discrete[, (9 * pg - 8):min(p, 9 * pg), with = FALSE]
    ## Create ggplot object
    plot <- lapply(seq_along(subset_data),
                   function(j) {
                     x <- subset_data[, j, with = FALSE]
                     agg_x <- x[, list(frequency = .N), by = names(x)]
                     if (na.rm) {agg_x <- na.omit(agg_x)}
                     if (order_bar) {
                       base_plot <- ggplot(agg_x, aes(x = reorder(get(names(agg_x)[1]), frequency), y = frequency))
                     } else {
                       base_plot <- ggplot(agg_x, aes_string(x = names(agg_x)[1], y = "frequency"))
                     }
                     base_plot +
                       geom_bar(stat = "identity", alpha = 0.4, colour = "black") +
                       scale_y_continuous(labels = comma) +
                       coord_flip() + xlab(names(agg_x)[1]) + ylab("Frequency")
                   })
    ## Print plot object
    if (pages > 1) {
      suppressWarnings(do.call(grid.arrange, c(plot, ncol = 3, nrow = 3)))
    } else {
      suppressWarnings(do.call(grid.arrange, plot))
    }
  }
}
