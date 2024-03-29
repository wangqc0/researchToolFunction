#include <Rcpp.h>
// #include <vector>
using namespace Rcpp;

// [[Rcpp::export]]
std::vector<std::vector<int>> permutateC(std::vector<int> x, int n = -1, int i = 0);

std::vector<std::vector<int>> permutateC(std::vector<int> x, int n, int i) {
  if (n == -1) {
    n = x.size();
    i = 0;
  }
  std::vector<std::vector<int>> result;
  
  if (i == n - 1) {
    result.push_back(x);
  } else {
    for (int j = i; j < n; ++j) {
      std::swap(x[i], x[j]);
      auto temp = permutateC(x, n, i + 1);
      result.insert(result.end(), temp.begin(), temp.end());
      std::swap(x[i], x[j]);
    }
  }
  return result;
}

std::vector<std::vector<int>> permutateCMatrix(const std::vector<int> &x) {
  return permutateC(x);
}

// /*** R
// permutateC(c(1:5))
// */
