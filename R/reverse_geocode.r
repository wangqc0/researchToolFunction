# source: https://gist.githubusercontent.com/uribo/f17af1d45f55ba977f708822458159d7/raw/c74cabfde90a2a60152e641c8419e811d1139b07/reverse_geocode.r
# with edit

#' Reverse geocoding
#' 
#' @description Reverse geocoding using finds.jp web service.
#' @param latitude latitude
#' @param longitude longitude
#' @import crul
#' @importFrom dplyr data_frame
#' @importFrom dplyr if_else
#' @importFrom dplyr na_if
#' @importFrom dplyr num_range
#' @importFrom dplyr vars
#' @importFrom jsonlite fromJSON
reverse_geocode <- function(longitude = NULL, latitude = NULL) {
  
  x <- crul::HttpClient$new(
    url = 'https://aginfo.cgk.affrc.go.jp/ws/rgeocode.php'
  )
  res <- x$get(query = list(lon = latitude, lat = longitude, json = TRUE))
  res.json <- jsonlite::fromJSON(res$parse(), simplifyVector = FALSE)
  
  # ref) http://www.finds.jp/rgeocode/index.html.ja#RES
  if (res.json$status <= 202) {
    df.res <- dplyr::data_frame(
      geo_0 = res.json$result$prefecture$pname, #geo_0
      geo_1 = res.json$result$municipality$mname, # geo_1
      geo_2 = dplyr::if_else(is.null(res.json$result$local), "", res.json$result$local[[1]]$section), # geo_2
      geo_3 = dplyr::if_else(is.null(res.json$result$local), "", res.json$result$local[[1]]$homenumber) # geo_3
    ) %>% 
      dplyr::mutate(geo_2 = gsub("（大字なし）", "", geo_2)) %>% 
      dplyr::mutate_at(dplyr::vars(dplyr::num_range("geo_", 2:3)), dplyr::na_if, y = "")
  } else {
    df.res <- dplyr::data_frame(
      geo_0 = NA,
      geo_1 = NA,
      geo_2 = NA,
      geo_3 = NA
      )
  }
  return(df.res)
  
}