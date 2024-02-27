# function: given longitude and latitude of a point, find the polygon the point is in
# longitude <- station[station$station == '58424099999',]$longitude
# latitude <- station[station$station == '58424099999',]$latitude
point_polygon_index <-
  function (longitude, latitude, polygons) {
    # longitude: longitude of the point
    # latitude: latitude of the point
    # polygons: a list of polygons to locate
    point <- sf::st_sfc(sf::st_point(c(longitude, latitude)), crs = 4326)
    indicator_point_intersect <-
      lapply(
        polygons,
        function (polygon_i) {
          sf_polygon_i <- sf::st_as_sf(sf::st_sfc(polygon_i), crs = 4326)
          tryCatch({
            suppressMessages(point_intersect_i <- sf::st_contains(sf_polygon_i, point))
            #if (nrow(point_intersect_i) == 0) {
            if (length(point_intersect_i[[1]]) == 0) {
              return(0)
            } else {
              return(1)
            }
          }, error = function (e) {return(NA)})
        }
      )
    index <- which(unlist(indicator_point_intersect) == 1)
    if (length(index) == 0) {
      index <- NA
    } else if (length(index) > 1) {
      index <- index[1]
    }
    return(index)
  }
# point_polygon_index(longitude, latitude, china_city_geometry)