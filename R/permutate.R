# permutation of a vector
permutate <-
  function (x, n, i) {
   # x: a vector for permutation
   # n: length of the vector
   # i: current stage
    if (nargs() == 1) {
      n <- length(x)
      i <- 1
    } else if (nargs() == 2) {
      i <- 1
    }
    if (i == n) {
      x_final <- t(matrix(x, nrow = n))
      return(x_final)
    } else {
      x_new <- c()
      for (j in c(i:n)) {
        x[c(i, j)] <- x[c(j, i)]
        x_new <- c(x_new, permutate(x, n, i + 1))
        x[c(i, j)] <- x[c(j, i)]
      }
      return(x_new)
    }
  }

# return a matrix
permutate_matrix <-
  function (x) {
    # x: a vector for permutation
    x_output <- t(matrix(permutate(x, length(x)), nrow = length(x)))
    return(x_output)
  }
