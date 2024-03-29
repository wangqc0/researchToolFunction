#include <Rcpp.h>
using namespace Rcpp;

// This function fills in a numeric vector with NA values according to the following steps:
// 1. Starting from the first element. If it is NA, skip it and go to the next element, until the first non-NA element appears. Record the index of the first non-NA element.
// 2. Record the element as the temporary value.
// 3. Fill all previous NA elements with the value.
// 4. Go to the next element. If it is NA, fill it with the temporary value. Otherwise, replace the temporary value by the value of the current element. Do this until reaching the end of the vector.

// [[Rcpp::export]]
NumericVector fillSimpleC(NumericVector vec) {
  bool non_na_founded = false;
  int len_vec = vec.size();
  //int i_first_non_na = 0;
  float value_temp = 0;
  for (int i = 0; i < len_vec; ++i) {
    if (non_na_founded) {
      if (isnan(vec[i])) {
        vec[i] = value_temp;
      } else {
        value_temp = vec[i]; 
      }
    } else {
      if (isnan(vec[i])) {
        continue;
      } else {
        value_temp = vec[i]; 
        //i_first_non_na = i;
        for (int j = 0; j < i; ++j) {
          vec[j] = value_temp;
        }
        non_na_founded = true;
      }
    }
  }
  return vec;
}

// /*** R
// fillSimpleC(c(1, NA, 6, NA, 4, NA, 9))
// */
