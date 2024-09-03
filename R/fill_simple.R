# This function fills in a numeric vector with NA values according to the following steps:
# 1. Starting from the first element. If it is NA, skip it and go to the next element, until the first non-NA element appears. Record the index of the first non-NA element.
# 2. Record the element as the temporary value.
# 3. Fill all previous NA elements with the value.
# 4. Go to the next element. If it is NA, fill it with the temporary value. Otherwise, replace the temporary value by the value of the current element. Do this until reaching the end of the vector.

fill_simple <-
  function (vec) {
    non_na_founded <- FALSE
    len_vec <- length(vec)
    for (i in c(1:len_vec)) {
      if (non_na_founded) {
        if (is.na(vec[i])) {
          vec[i] <- value_temp
        } else {
          value_temp <- vec[i]
        }
      } else {
        if (is.na(vec[i])) {
          next
        } else {
          value_temp <- vec[i]
          i_first_non_na <- i
          vec[1:(i_first_non_na - 1)] <- value_temp
          non_na_founded <- TRUE
        }
      }
    }
    return (vec)
  }
