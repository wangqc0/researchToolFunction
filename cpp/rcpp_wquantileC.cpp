#include <Rcpp.h>
#include "rcpp_wquantileC.hpp"
using namespace Rcpp;

// This function calculates the weighted quantile given a numeric vector of values and a numeric vector of weights.

inline IntegerVector index_order_vector(NumericVector const &x) {
  IntegerVector index = seq_along(x) - 1;
  std::sort(index.begin(), index.end(), [&](int i, int j){return x[i] < x[j];});
  return index + 1;
}

// [[Rcpp::export]]
double wquantileC(NumericVector x, double q, Nullable<NumericVector> w_nullable = R_NilValue) {
  int n = x.size();
  NumericVector w(n);
  
  if (w_nullable.isNotNull()) {
    w = NumericVector(w_nullable);
  } else {
    // assign equal weight to each element if weight is not provided
    w = rep(1.0 / n, n);
  }
  // exclude NA observations
  // LogicalVector not_x_na = !is_na(x);
  // LogicalVector not_w_na = !is_na(w);
  // LogicalVector not_na;
  // // if weight is provided and has NA in its values
  // if (w_nullable.isNotNull() && is_true(any(!not_w_na))) {
  //   // exclude the observation if either x or w of the observation is NA
  //   not_na = not_x_na & not_w_na;
  //   x = x[not_na];
  //   w = w[not_na];
  // } else {
  //   // if weight is provided and without NA in its values, check whether x has NA in its values
  //   // exclude the observation if x of the observation is NA
  //   // if weight is provided
  //   if (is_true(any(!not_x_na)) && w_nullable.isNotNull()) {
  //     x = x[not_x_na];
  //     w = w[not_x_na];
  //   } else if (is_true(any(!not_x_na))) {
  //     x = x[not_x_na];
  //   }
  // }
  //
  // // x = x[not_na];
  // // w = w[not_na];
  LogicalVector not_na = !is_na(x) & !is_na(w);
  if (!is_true(all(not_na))) {
    x = x[not_na];
    w = w[not_na];
  }
  n = x.size();
  // return NA if no valid observation
  if (n == 0) return NA_REAL;
  // after removing NA on w, if there is still NA in w, it must be that weight is not provided
  // assign equal weight to each element in this case
  // if (is_true(any(is_na(w)))) {
  //   w = rep(1.0 / n, n);
  // }
  // parameter nw for the CDF generation function
  double sum_of_w_sq = sum(w * w);
  double sum_w = sum(w);
  double nw = (sum_w * sum_w) / sum_of_w_sq;
  // ascending order the vectors x and w
  // NumericVector sorted_x = clone(x).sort();
  IntegerVector index_order_x = index_order_vector(x);
  NumericVector sorted_x = x[index_order_x - 1];
  NumericVector sorted_w = w[index_order_x - 1];
  // normalize weight
  sorted_w = sorted_w / sum(sorted_w);
  // obtain quantile points of the CDF of the distribution
  NumericVector q_cdf = cumsum(sorted_w);
  q_cdf.push_front(0);
  // calculate the CDF values of the given quantile points
  double h = q * (nw - 1) + 1;
  double u_min = (h - 1) / nw;
  double u_max = h / nw;
  NumericVector u = clone(q_cdf);
  for (int i = 0; i < n + 1; ++i) {
    if (u[i] < u_min) {
      u[i] = u_min;
    } else if (u[i] > u_max) {
      u[i] = u_max;
    }
  }
  NumericVector cdf_q = u * nw - h + 1;
  // weight of each element in x for the target quantile
  NumericVector w_q = cdf_q[Range(1, n)] - cdf_q[Range(0, n - 1)];
  // calculate the output
  return sum(w_q * sorted_x);
}

double wquantileMedianC(NumericVector x, Nullable<NumericVector> w_nullable = R_NilValue) {
  double q = .5;
  return wquantileC(x, q, w_nullable);
}

// EWCDF

// [[Rcpp::export]]
double ewcdfC(double p, NumericVector x, Nullable<NumericVector> weight = R_NilValue) {
  int n = x.size();

  // Check if weights are provided, otherwise use equal weights
  // if (weight.isNotNull()) {
  //   w = NumericVector(weight);
  // } else {
  //   w = rep(1.0, n);
  // }
  NumericVector w = weight.isNotNull() ? NumericVector(weight.get()) : no_init(n);
  if (weight.isNull()) {
    std::fill(w.begin(), w.end(), 1.0);
  }

  // Check if NA exist
  // LogicalVector not_na = !is_na(x) & !is_na(w);
  // if (is_true(any(!not_na))) {
  //   stop("Some values or weights are NA");
  // }
  for (int i = 0; i < n; ++i) {
    if (NumericVector::is_na(x[i]) || NumericVector::is_na(w[i])) {
      stop("Some values or weights are NA");
    }
  }

  // Total weight
  //double total_weight = sum(w);
  double total_weight = 0.0;

  // Compute weighted cumulative distribution function
  double cumulative_weight = 0.0;
  for (int i = 0; i < n; ++i) {
    total_weight += w[i];
    if (x[i] <= p) {
      cumulative_weight += w[i];
    }
  }

  return cumulative_weight / total_weight;
}

//convert weighted percentile in a group to weighted percentile in another group

// [[Rcpp::export]]
double convert_weighted_quantile_C(double p_input, NumericVector x_input, NumericVector w_input, NumericVector x_output, NumericVector w_output) {
  // check and remove NA
  LogicalVector not_na_input = !is_na(x_input) & !is_na(w_input);
  x_input = x_input[not_na_input];
  w_input = w_input[not_na_input];
  LogicalVector not_na_output = !is_na(x_output) & !is_na(w_output);
  x_output = x_output[not_na_output];
  w_output = w_output[not_na_output];
  double value = wquantileC(x_input, p_input, w_input);
  double p_output = ewcdfC(value, x_output, w_output);
  return p_output;
}

// /*** R
// wquantileC(c(1:10), .5, c(1:10))
// wquantileMedianC(c(1:10), c(1:10))
// ewcdfC(10, c(1:20), c(1:20))
// convert_weighted_quantile_C(.5, c(1:10), c(1:10), c(1:20), c(1:20))
// */
