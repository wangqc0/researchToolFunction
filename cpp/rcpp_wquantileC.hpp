#include <Rcpp.h>
using namespace Rcpp;

#ifndef rcpp_wquantileC
#define rcpp_wquantileC

double wquantileC(NumericVector x, double q, Nullable<NumericVector> w_nullable);
double wquantileMedianC(NumericVector x, Nullable<NumericVector> w_nullable);
double ewcdfC(double p, NumericVector x, Nullable<NumericVector> weight);
double convert_weighted_quantile_C(double p_input, NumericVector x_input, NumericVector w_input, NumericVector x_output, NumericVector w_output);

#endif