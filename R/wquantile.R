# weighted generic quantile estimator:
# reference: https://aakinshin.net/posts/weighted-quantiles/
wquantile_generic <- function(x, probs, cdf_gen, weights = NA) {
  n <- length(x)
  if (any(is.na(weights))) {
    weights <- rep(1 / n, n)
  }
  nw <- sum(weights)^2 / sum(weights^2)
  indexes <- order(x)
  x <- x[indexes]
  weights <- weights[indexes]
  weights <- weights / sum(weights)
  cdf_probs <- cumsum(c(0, weights))
  sapply(probs, function(p) {
    cdf <- cdf_gen(nw, p)
    q <- cdf(cdf_probs)
    w <- tail(q, -1) - head(q, -1)
    sum(w * x)
  })
}

# weighted type 7 quantile estimator:
# reference: https://aakinshin.net/posts/weighted-quantiles/
wquantile <- function(x, probs, weights = NA) {
  # x: vector of observations
  # probs: input quantile
  # weights: the weight of each observation
  # check and remove NA
  which_x_na <- which(is.na(x))
  if (length(weights) > 1 && any(is.na(weights))) {
    which_weights_na <- which(is.na(weights))
    which_na <- union(which_x_na, which_weights_na)
    if (!is_empty(which_na)) {
      x <- x[-which_na]
      weights <- weights[-which_na]
    }
  } else {
    if (!is_empty(which_x_na) && length(weights) > 1) {
      x <- x[-which_x_na]
      weights <- weights[-which_x_na]
    } else if (!is_empty(which_x_na)) {
      x <- x[-which_x_na]
    }
  }
  cdf_gen <- function(n, p) return(function(cdf_probs) {
    h <- p * (n - 1) + 1
    u <- pmax((h - 1) / n, pmin(h / n, cdf_probs))
    u * n - h + 1
  })
  wquantile_generic(x, probs, cdf_gen, weights)
}

# convert weighted percentile in a group to weighted percentile in another group:
convert_weighted_quantile <-
  function(p_input, x_input, w_input, x_output, w_output) {
    # check and remove NA
    which_x_input_na <- which(is.na(x_input))
    which_w_input_na <- which(is.na(w_input))
    which_input_na <- union(which_x_input_na, which_w_input_na)
    if (!is_empty(which_input_na)) {
      x_input <- x_input[-which_input_na]
      w_input <- w_input[-which_input_na]
    }
    which_x_output_na <- which(is.na(x_output))
    which_w_output_na <- which(is.na(w_output))
    which_output_na <- union(which_x_output_na, which_w_output_na)
    if (!is_empty(which_output_na)) {
      x_output <- x_output[-which_output_na]
      w_output <- w_output[-which_output_na]
    }
    # quantile (p_input) to value:
    value <- wquantile(x_input, weights = w_input, probs = p_input)
    # value to quantile (p_output):
    ewcdf_output <- ewcdf(x_output, weights = w_output)
    p_output <- ewcdf_output(value)
    return(p_output)
  }
