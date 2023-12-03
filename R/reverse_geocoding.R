# The file contains functions related to geocoding addresses in Japan, usually used for spatial analysis
# Packages `Gmedian`, `crul`, `jsonlite`, `curl`, `htmltools` are required.

# aggregate the purchase data by panel id and calculate the geometric median of
# the location
aggregateGmedian <- function(purchase){
  home <- data.frame()
  id <- unique(purchase$panel_id)
  home[1:length(id),1] <- id
  for (j in 1:length(id)){
    purchase_j <- purchase[purchase$panel_id == home[j,1],c('shop_latitude','shop_longitude')]
    home[j,2:3] <- Gmedian(purchase_j)
  }
  colnames(home) <- c('panel_id', 'latitude', 'longitude')
  return(home)
}
aggregateGmedianf <- function(purchase){
  home <- data.frame()
  purchase_id <- data.frame()
  id <- purchase[1,1]
  for (j in 1:nrow(purchase)){
    if ((id == purchase[j,1]) & (j < nrow(purchase))){
      # append the row to purchase_id
      purchase_id <- rbind(purchase_id,purchase[j,2:3])
    }
    else{
      if (j < nrow(purchase)){
        # calculate the result from running Gmedian on purchase_id and start a new purchase_id
        home <- rbind(home,cbind(id,Gmedian(purchase_id)))
        purchase_id <- data.frame()
        purchase_id <- rbind(purchase_id,purchase[j,2:3])
        id <- purchase[j,1]
      }
      else{
        # calculate the result from running Gmedian on purchase_id
        purchase_id <- rbind(purchase_id,purchase[j,2:3])
        home <- rbind(home,cbind(id,Gmedian(purchase_id)))
      }
    }
  }
  colnames(home) <- c('panel_id', 'latitude', 'longitude')
  return(home)
}

# reverse geocoding to get municipality information
# based on the function `reverse_geocode.r` (https://gist.githubusercontent.com/uribo/f17af1d45f55ba977f708822458159d7/raw/c74cabfde90a2a60152e641c8419e811d1139b07/reverse_geocode.r)
reverse_geocode_muni <- function(latitude = NULL, longitude = NULL) {
  i <<- i + 1
  print(i)
  x <- crul::HttpClient$new(url = 'https://aginfo.cgk.affrc.go.jp/ws/rgeocode.php')
  res <- x$get(query = list(lon = longitude, lat = latitude, json = TRUE))
  res.json <- jsonlite::fromJSON(res$parse(), simplifyVector = FALSE)
  muni <- ifelse(
    res.json$status <= 202,
    paste(res.json$result$prefecture$pname,res.json$result$municipality$mname),
    NA
  )
  return(muni)
}

# reverse-geocoding for the monitor data
reverse_geocode_monitor <- function(monitor, bin = 100){
  # the number of simultaneous connection:
  J <- ceiling(nrow(monitor)/bin)
  monitor_muni <- list()
  complete <- function(res){
    out <<- c(out, list(res))
  }
  for (j in 1:J){
    monitor_j <- monitor[(bin*(j-1)+1):(min(bin*j,nrow(monitor))),c('latitude','longitude','panel_id')]
    site <- paste0('https://aginfo.cgk.affrc.go.jp/ws/rgeocode.php?lon=',
                   monitor_j$longitude, '&lat=', monitor_j$latitude, '&opt=', monitor_j$panel_id)
    out <<- list()
    for(i in 1:length(site)){
      curl_fetch_multi(
        site[i]
        , done = complete
        , fail = print
        , handle = new_handle(customrequest = 'GET')
      )
    }
    multi_run()
    allout <- lapply(out, function(x){
      webpage <- read_html(x$content)
      status <- webpage %>% html_nodes('status') %>% html_text()
      if (status %in% c('200', '201')){
        pref <- webpage %>% html_nodes('pname') %>% html_text() %>% unlist()
        muni <- webpage %>% html_nodes('mname') %>% html_text() %>% unlist()
        code <- webpage %>% html_nodes('mcode') %>% html_text() %>% unlist()
        pid <- sub('.*opt=', '', x$'url')
        c(paste(pref, muni, code, sep = '-'), pid)
      } else {
        pid <- sub('.*opt=', '', x$'url')
        c(NA, pid)
      }
    })
    muni <- do.call(rbind.data.frame, allout) %>% `colnames<-` (c('muni','panel_id'))
    monitor_muni[[j]] <- muni
    print(paste(Sys.time(), min(bin*j,nrow(monitor)), '/', nrow(monitor)))
  }
  do.call(rbind.data.frame, monitor_muni)
}
