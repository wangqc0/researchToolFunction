# compute Gini coefficient from a distribution
gini_coefficient <- function (x) {
  # x: vector of distribution
  # check errors
  if (!(typeof(x) == 'double')) {
    stop('The type of the individual income vector should be \'double\'')
  }
  # remove NA
  x_nona <- x[!is.na(x)]
  if (any(x_nona < 0)) {
    stop('The individual income vector should not include negative values')
  }
  # reorder
  x_ordered <- x_nona[order(x_nona)]
  # calculate the Gini coefficient
  n_x <- length(x_ordered)
  sum_x <- sum(x_ordered)
  area_ideal <- n_x * sum_x / 2
  cumsum_x <- cumsum(x_ordered)
  cumsum_x_lower <- c(0, cumsum_x[-length(cumsum_x)])
  cumsum_x_upper <- cumsum_x
  area_actual <- sum((cumsum_x_lower + cumsum_x_upper) / 2)
  gini <- (area_ideal - area_actual) / area_ideal
  return(gini)
}
