# This file contains functions generating regression results from lm and clm models

# output essential results from a clm model:
output_clm <- function(clm){
  model_num <- length(clm)
  beta <- list()
  for (i in 1:model_num){
    beta_i <- t(data.frame(coef = clm[[i]]$beta))
    name_beta_i <- colnames(beta_i)
    if (ncol(beta_i) == 1){
      se_beta_i <- sqrt(clm[[i]]$vcov[name_beta_i, name_beta_i])
      names(se_beta_i) <- name_beta_i
      beta_i <- rbind.data.frame(beta_i, t(data.frame(se = se_beta_i)))
      beta_i['p',] <- pnorm(-abs(beta_i[1,] / beta_i[2,]))
    } else {
      se_beta_i <- sqrt(diag(clm[[i]]$vcov[name_beta_i, name_beta_i]))
      beta_i <- rbind.data.frame(beta_i, t(data.frame(se = se_beta_i)))
      beta_i['p',] <- apply(-abs(beta_i[1,] / beta_i[2,]), 2, pnorm)
    }
    beta_i <- cbind.data.frame(model = NA, n = NA, value = NA, beta_i)
    beta_i$model[1] <- i
    beta_i$n[1] <- clm[[i]]$n
    beta_i$value <- c('coef', 'se', 'p')
    beta[[i]] <- beta_i
  }
  beta <- bind_rows_diff(beta)
  rownames(beta) <- NULL
  beta
}

# output essential results from a lm model:
output_lm <- function(lm){
  model_num <- length(lm)
  beta <- list()
  for (i in 1:model_num){
    beta_i <- t(data.frame(coef = lm[[i]]$coefficients))
    name_beta_i <- colnames(beta_i)
    if (ncol(beta_i) == 1){
      se_beta_i <- sqrt(vcov(lm[[i]]))
      names(se_beta_i) <- name_beta_i
      beta_i <- rbind.data.frame(beta_i, t(data.frame(se = se_beta_i)))
      beta_i['p',] <- pnorm(-abs(beta_i[1,] / beta_i[2,]))
    } else {
      se_beta_i <- sqrt(diag(vcov(lm[[i]])))
      beta_i <- rbind.data.frame(beta_i, t(data.frame(se = se_beta_i)))
      beta_i['p',] <- apply(-abs(beta_i[1,] / beta_i[2,]), 2, pnorm)
    }
    beta_i <- cbind.data.frame(model = NA, n = NA, value = NA, beta_i)
    beta_i$model[1] <- i
    beta_i$n[1] <- nobs(lm[[i]])
    beta_i$value <- c('coef', 'se', 'p')
    beta[[i]] <- beta_i
  }
  beta <- bind_rows_diff(beta)
  rownames(beta) <- NULL
  beta
}

# transform essential results above to report format:
report_output <- function(output, var_location_start, var_location_end, digit = 3){
  options(scipen = 999)
  output_formatted <-
    round(output[,var_location_start:var_location_end], digits = digit)
  value <- unique(output$value)
  which_value_p <- which(value == 'p')
  which_value_coef <- which(value == 'coef')
  diff_row_coef_p <- which_value_p - which_value_coef
  for (i in 1:(nrow(output_formatted)/length(value))){
    for (j in 1:ncol(output_formatted)){
      p <- output_formatted[(i - 1) * length(value) + which_value_p, j]
      if (is.na(p)) {
        break
      } else if (p < .01) {
        output_formatted[(i - 1) * length(value) + which_value_coef, j] <-
          paste0(output_formatted[(i - 1) * length(value) + which_value_coef, j], '***')
      } else if (p < .05) {
        output_formatted[(i - 1) * length(value) + which_value_coef, j] <-
          paste0(output_formatted[(i - 1) * length(value) + which_value_coef, j], '**')
      } else if (p < .1) {
        output_formatted[(i - 1) * length(value) + which_value_coef, j] <-
          paste0(output_formatted[(i - 1) * length(value) + which_value_coef, j], '*')
      } else {
        output_formatted[(i - 1) * length(value) + which_value_coef, j] <-
          as.character(output_formatted[(i - 1) * length(value) + which_value_coef, j])
      }
    }
  }
  output[,var_location_start:var_location_end] <- output_formatted
  output
}
