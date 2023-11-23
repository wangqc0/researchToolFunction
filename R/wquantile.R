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
    # quantile (p_input) to value:
    value <- wquantile(x_input, weights = w_input, probs = p_input)
    # value to quantile (p_output):
    ewcdf_output <- ewcdf(x_output, weights = w_output)
    p_output <- ewcdf_output(value)
    return(p_output)
  }
