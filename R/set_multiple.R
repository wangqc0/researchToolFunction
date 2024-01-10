# obtain the intersect or union of multiple sets

intersect_multiple <-
  function (...) {
    set_multiple <- list(...)
    num_set <- length(set_multiple)
    if (num_set == 0) {
      return(c())
    }
    if (num_set == 1) {
      set_intersect <- set_multiple[[1]]
      return(set_intersect)
    } else {
      set_intersect <- set_multiple[[1]]
      for (set_index in 2:num_set) {
        set_intersect <- intersect(set_intersect, set_multiple[[set_index]])
      }
      return(set_intersect)
    }
  }

union_multiple <-
  function (...) {
    set_multiple <- list(...)
    num_set <- length(set_multiple)
    if (num_set == 0) {
      return(c())
    }
    if (num_set == 1) {
      set_union <- set_multiple[[1]]
      return(set_union)
    } else {
      set_union <- set_multiple[[1]]
      for (set_index in 2:num_set) {
        set_union <- union(set_union, set_multiple[[set_index]])
      }
      return(set_union)
    }
  }

# example
# a <- c(1, 2, 3, 4, 5)
# b <- c(2, 4, 5, 7, 8)
# d <- c(5, 2, 3, 4, 9)
# intersect_multiple(a, b, d) is equivalent to intersect(a, intersect(b, d))
# union_multiple(a, b, d) is equivalent to union(a, union(b, d))
