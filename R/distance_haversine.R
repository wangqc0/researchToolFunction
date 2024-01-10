# Haversine distance of two points given their longitudes and latitudes
distance_haversine <-
  function (longitude_1, latitude_1, longitude_2, latitude_2) {
    radius_earth <- 6371
    d_longitude <- (longitude_2 - longitude_1) * pi / 180
    d_latitude <- (latitude_2 - latitude_1) * pi / 180
    a <- sin(d_latitude / 2) * sin(d_latitude / 2) +
           cos(latitude_1 * pi / 180) * cos(latitude_2 * pi / 180) * sin(d_longitude / 2) * sin(d_longitude / 2)
    cc <- 2 * arctan2(sqrt(a), sqrt(1 - a))
    d <- radius_earth * cc
    return(d)
  }
# calculate the arc tangent function of a slope and locate the quadrant
arctan2 <-
  function (y, x) {
    y_to_x <- y / x
    if (y >= 0) {
      if (x >= 0) {
        arctan_y_to_x <- atan(y_to_x)
      } else {
        arctan_y_to_x <- atan(y_to_x) + pi
      }
    } else {
      if (x >= 0) {
        arctan_y_to_x <- atan(y_to_x)
      } else {
        arctan_y_to_x <- atan(y_to_x) - pi
      }
    }
    return(arctan_y_to_x)
  }
