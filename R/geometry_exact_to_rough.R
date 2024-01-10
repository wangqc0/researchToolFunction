# The script includes functions to decline the resolution of geometric shape files to reduce their size and quickens map plotting

# define a function that takes rows in a two-column matrix (coordinate) by specified separations
exactToRough <-
  function (coordinate, max_small_geometry, max_medium_geometry, sample_by_medium, sample_by_large) {
    # coordinate: the (n * 2) polygon matrix to be compressed
    # max_small_geometry: threshold of small geometries (do not rough)
    # max_medium_geometry: threshold of medium geometries (less rough)
    # sample_by_medium: the extent of roughness of medium geometries
    # sample_by_large: the extent of roughness of large geometries
    n <- nrow(coordinate)
    if (n < max_small_geometry) {
      return(coordinate)
    } else if (n < max_medium_geometry) {
      return(coordinate[sample_by_medium * (c(1:(n %/% sample_by_medium), 1)),])
    } else {
      return(coordinate[sample_by_large * (c(1:(n %/% sample_by_large), 1)),])
    }
  }
# standard definition: exactToRough(x, 30, 90, 10, 30)
# high definition: exactToRough(x, 30, 30, 5, 5)
# ultra-high definition:exactToRough(x, 30, 30, 2, 2)

# define a function that extracts a rough polygon from an exact polygon to save time and space in plot
# wrap the function above into the new function taking a list of geometries as input
geometryExactToRough <-
  function(shape, max_small_geometry, max_medium_geometry, sample_by_medium, sample_by_large) {
    # shape: the list of geometries to transform (S3: sfc_MULTIPOLYGON)
    for (i in 1:length(shape)) {
      for (j in 1:length(shape[[i]])) {
        shape[[i]][[j]][[1]] <-
          exactToRough(shape[[i]][[j]][[1]], max_small_geometry, max_medium_geometry, sample_by_medium, sample_by_large)
      }
    }
    return(shape)
  }
# example of attaching to a table with the geometric information:
# china_geometry <- china$geometry
# china_geometry_rough <- geometryExactToRough(china_geometry, 30, 90, 10, 30)
# china$geometry <- china_geometry_rough
