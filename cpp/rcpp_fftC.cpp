#include <Rcpp.h>
#include <fftw3.h>
#include <vector>

using namespace Rcpp;

// [[Rcpp::export]]
NumericVector fftC(NumericVector input) {
  int N = input.size();
  
  // FFTW arrays
  fftw_complex *arrayOut;
  fftw_plan plan;
  
  // Allocate input and output arrays
  double *arrayIn = (double*) fftw_malloc(sizeof(double) * N);
  arrayOut = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
  
  // Copy data from R to FFTW input
  for (int i = 0; i < N; i++) {
    arrayIn[i] = input[i];
  }
  
  // Create plan and execute
  plan = fftw_plan_dft_r2c_1d(N, arrayIn, arrayOut, FFTW_ESTIMATE);
  fftw_execute(plan);
  
  // Prepare return vector
  NumericVector result(N);
  for(int i = 0; i < N; i++) {
    // Store magnitude of complex numbers
    result[i] = sqrt(arrayOut[i][0] * arrayOut[i][0] + arrayOut[i][1] * arrayOut[i][1]);
  }
  
  // Cleanup
  fftw_destroy_plan(plan);
  fftw_free(arrayIn); 
  fftw_free(arrayOut);
  
  return result;
}


// /*** R
// fftC(runif(100))
// */
