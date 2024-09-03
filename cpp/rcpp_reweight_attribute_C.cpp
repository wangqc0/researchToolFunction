#include <Rcpp.h>
using namespace Rcpp;

// reweight observations by attribute (eg, education) with conversion factors

// [[Rcpp::export]]
NumericVector reweight_attribute_C(NumericVector const &pweight, IntegerVector const &attribute, NumericVector const &conversion_ratio) {
  int n = pweight.size();
  int n_conversion_ratio = conversion_ratio.size();
  NumericVector pweight_converted = clone(pweight);
  double conversion_ratio_i = 1.0;
  int attribute_i = 0;
  for (int i = 0; i < n; ++i) {
    attribute_i = attribute[i];
    if (0 < attribute_i && attribute_i < n_conversion_ratio + 1) {
      conversion_ratio_i = conversion_ratio[attribute_i - 1];
    } else {
      conversion_ratio_i = 1.0;
    }
    pweight_converted[i] = pweight[i] * conversion_ratio_i;
  }
  return pweight_converted;
}

// You can include R code blocks in C++ files processed with sourceCpp
// (useful for testing and development). The R code will be automatically 
// run after the compilation.
//

// /*** R
// reweight_attribute_C
// */
