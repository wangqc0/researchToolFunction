# The file contains functions related to mesh codes of Japan, ususally used for spatial analysis

# convert longitude and latitude to mesh code
loc2meshc <- function(long, lat){
  latm <- lat * 1.5
  longm <- long - 100
  mesh1 <- floor(latm) * 100 + floor(longm)
  mesh2 <- floor(latm * 8) %% 8 * 10 + floor(longm * 8) %% 8
  mesh3 <- floor(latm * 80) %% 10 * 10 + floor(longm * 80) %% 10
  meshc <- mesh1 * 10000 + mesh2 * 100 + mesh3
  return(meshc)
}

# function: given a second-level mesh code, find the mesh codes of eight neighbouring meshes:
meshc_2_nb <- function(x){
  v1 <- x %/% 10000
  h1 <- (x %/% 100) %% 100
  v2 <- (x %/% 10) %% 10
  h2 <- x %% 10
  # north:
  if (v2  == 7){
    v2n <- 0
    v1n <- v1 + 1
  } else{
    v2n <- v2 + 1
    v1n <- v1
  }
  # south:
  if (v2 == 0){
    v2s <- 7
    v1s <- v1 - 1
  } else{
    v2s <- v2 - 1
    v1s <- v1
  }
  # east:
  if (h2 == 7){
    h2e <- 0
    h1e <- h1 + 1
  } else{
    h2e <- h2 + 1
    h1e <- h1
  }
  # west:
  if (h2 == 0){
    h2w <- 7
    h1w <- h1 - 1
  } else{
    h2w <- h2 - 1
    h1w <- h1
  }
  # N, NE, E, SE, S, SW, W, NW
  xn <- v1n * 10000 + h1 * 100 + v2n * 10 + h2
  xne <- v1n * 10000 + h1e * 100 + v2n * 10 + h2e
  xe <- v1 * 10000 + h1e * 100 + v2 * 10 + h2e
  xse <- v1s * 10000 + h1e * 100 + v2s * 10 + h2e
  xs <- v1s * 10000 + h1 * 100 + v2s * 10 + h2
  xsw <- v1s * 10000 + h1w * 100 + v2s * 10 + h2w
  xw <- v1 * 10000 + h1w * 100 + v2 * 10 + h2w
  xnw <- v1n * 10000 + h1w * 100 + v2n * 10 + h2w
  c(xn,xne,xe,xse,xs,xsw,xw,xnw)
}
# function: given a second-level mesh code and a direction (1: N, 2: NE, 3: E, 4: SE, 5: S, 6: SW, 7: W, 8: NW),
# find the mesh code:
meshc_2_nbd <- function(x, d){
  v1 <- x %/% 10000
  h1 <- (x %/% 100) %% 100
  v2 <- (x %/% 10) %% 10
  h2 <- x %% 10
  if (d == 1){
    if (v2  == 7){
      v2n <- 0
      v1n <- v1 + 1
    } else{
      v2n <- v2 + 1
      v1n <- v1
    }
    return(v1n * 10000 + h1 * 100 + v2n * 10 + h2)
  } else if (d == 2){
    if (v2  == 7){
      v2n <- 0
      v1n <- v1 + 1
    } else{
      v2n <- v2 + 1
      v1n <- v1
    }
    if (h2 == 7){
      h2e <- 0
      h1e <- h1 + 1
    } else{
      h2e <- h2 + 1
      h1e <- h1
    }
    return(v1n * 10000 + h1e * 100 + v2n * 10 + h2e)
  } else if (d == 3){
    if (h2 == 7){
      h2e <- 0
      h1e <- h1 + 1
    } else{
      h2e <- h2 + 1
      h1e <- h1
    }
    return(v1 * 10000 + h1e * 100 + v2 * 10 + h2e)
  } else if (d == 4){
    if (v2 == 0){
      v2s <- 7
      v1s <- v1 - 1
    } else{
      v2s <- v2 - 1
      v1s <- v1
    }
    if (h2 == 7){
      h2e <- 0
      h1e <- h1 + 1
    } else{
      h2e <- h2 + 1
      h1e <- h1
    }
    return(v1s * 10000 + h1e * 100 + v2s * 10 + h2e)
  } else if (d == 5){
    if (v2 == 0){
      v2s <- 7
      v1s <- v1 - 1
    } else{
      v2s <- v2 - 1
      v1s <- v1
    }
    return(v1s * 10000 + h1 * 100 + v2s * 10 + h2)
  } else if (d == 6){
    if (v2 == 0){
      v2s <- 7
      v1s <- v1 - 1
    } else{
      v2s <- v2 - 1
      v1s <- v1
    }
    if (h2 == 0){
      h2w <- 7
      h1w <- h1 - 1
    } else{
      h2w <- h2 - 1
      h1w <- h1
    }
    return(v1s * 10000 + h1w * 100 + v2s * 10 + h2w)
  } else if (d == 7){
    if (h2 == 0){
      h2w <- 7
      h1w <- h1 - 1
    } else{
      h2w <- h2 - 1
      h1w <- h1
    }
    return(v1 * 10000 + h1w * 100 + v2 * 10 + h2w)
  } else if (d == 8){
    if (v2  == 7){
      v2n <- 0
      v1n <- v1 + 1
    } else{
      v2n <- v2 + 1
      v1n <- v1
    }
    if (h2 == 0){
      h2w <- 7
      h1w <- h1 - 1
    } else{
      h2w <- h2 - 1
      h1w <- h1
    }
    return(v1n * 10000 + h1w * 100 + v2n * 10 + h2w)
  }
}
# function: given a third-level mesh code and a direction (1: N, 2: NE, 3: E, 4: SE, 5: S, 6: SW, 7: W, 8: NW),
# find the mesh code:
meshc_3_nbd <- function(x, d){
  v1 <- x %/% 1000000
  h1 <- (x %/% 10000) %% 100
  v2 <- (x %/% 1000) %% 10
  h2 <- (x %/% 100) %% 10
  v3 <- (x %/% 10) %% 10
  h3 <- x %% 10
  meshc_2 <- x %/% 100
  if (d == 1){
    if (v3 == 9){
      v3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 1)
    } else{
      v3 <- v3 + 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 2){
    if (v3 == 9){
      v3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 1)
    } else{
      v3 <- v3 + 1
    }
    if (h3 == 9){
      h3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 3)
    } else{
      h3 <- h3 + 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 3){
    if (h3 == 9){
      h3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 3)
    } else{
      h3 <- h3 + 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 4){
    if (v3 == 0){
      v3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 5)
    } else{
      v3 <- v3 - 1
    }
    if (h3 == 9){
      h3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 3)
    } else{
      h3 <- h3 + 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 5){
    if (v3 == 0){
      v3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 5)
    } else{
      v3 <- v3 - 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 6){
    if (v3 == 0){
      v3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 5)
    } else{
      v3 <- v3 - 1
    }
    if (h3 == 0){
      h3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 7)
    } else{
      h3 <- h3 - 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 7){
    if (h3 == 0){
      h3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 7)
    } else{
      h3 <- h3 - 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  } else if (d == 8){
    if (v3 == 9){
      v3 <- 0
      meshc_2 <- meshc_2_nbd(meshc_2, 1)
    } else{
      v3 <- v3 + 1
    }
    if (h3 == 0){
      h3 <- 9
      meshc_2 <- meshc_2_nbd(meshc_2, 7)
    } else{
      h3 <- h3 - 1
    }
    return(meshc_2 * 100 + v3 * 10 + h3)
  }
}
# function: given a third-level mesh code, find the mesh codes of eight neighbouring meshes:
meshc_3_nb <- function(x){
  xn <- meshc_3_nbd(x, 1)
  xne <- meshc_3_nbd(x, 2)
  xe <- meshc_3_nbd(x, 3)
  xse <- meshc_3_nbd(x, 4)
  xs <- meshc_3_nbd(x, 5)
  xsw <- meshc_3_nbd(x, 6)
  xw <- meshc_3_nbd(x, 7)
  xnw <- meshc_3_nbd(x, 8)
  c(xn,xne,xe,xse,xs,xsw,xw,xnw)
}
# given a third-level mesh code, find the mesh codes of the neibouring meshes within the square
# identified by a distance:
meshc_3_nb_multi <- function(x, dist = 1){
  if (!(is.integer(dist) & dist > 0)){
    x
  }
  if (dist == 1){
    meshc_3_nb(x)
  } else{
    setdiff(
      unique(c(
        meshc_3_nb_multi(meshc_3_nbd(x, 1), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 2), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 3), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 4), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 5), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 6), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 7), dist - 1),
        meshc_3_nb_multi(meshc_3_nbd(x, 8), dist - 1)
      )),
      x
    )
  }
}

# convert mesh code to longitude and latitude (centroid):
meshc2loc <- function(meshc){
  lat <- ((meshc %/% 1000000) +
    (meshc %/% 1000 - 10 * meshc %/% 10000) / 8 +
    (meshc %/% 10 - 10 * meshc %/% 100) / (8 * 10) +
      1 / (8 * 10 * 2)) / 1.5
  long <- 100 + (meshc %/% 10000 - 100 * meshc %/% 1000000) +
    (meshc %/% 100 - 10 * meshc %/% 1000) / 8 +
    (meshc - 10 * meshc %/% 10) / (8 * 10) +
    1 / (8 * 10 * 2)
  return(c(long, lat))
}
