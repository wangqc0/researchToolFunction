# decompose sources of variation using different functions
variation_decompose <-
  function (dat, indicator, source_indicator, other_indicator, weight_indicator = NA) {
    # dat: data frame
    # indicator: the variable to look at variation
    # source_indicator: a vector of categorical indicators
    # other_indicator: a vector of external categorical indicators
    # dat_weight: a vector of weights of each observation
    if (nargs() < 5) {
      dat_weight <- rep(1, nrow(dat))
    } else {
      dat_weight <- dat[, weight_indicator]
    }
    n_obs <- nrow(dat)
    n_indicator <- length(source_indicator)
    dat <- cbind(dat[, c(indicator, source_indicator, other_indicator)], dat_weight)
    colnames(dat)[1] <- 'dat_key'
    variation_ungrouped <-
      dat
    eval(parse(text = paste0('variation_ungrouped <- variation_ungrouped %>% group_by(', paste0(other_indicator, collapse = ','), ')')))
    variation_ungrouped <-
      variation_ungrouped %>%
      summarise(
        ss = (n() - 1) * var(dat_key),
        mld_times_n = n() * mld(dat_key, dat_weight),
        .groups = 'keep'
      ) %>%
      ungroup()
    variation_grouped_level <- list(variation_ungrouped)
    for (i_indicator in c(1:n_indicator)) {
      variation_grouped_level_i <- dat
      eval(parse(text = paste0('variation_grouped_level_i <- variation_grouped_level_i %>% group_by(', paste0(other_indicator, collapse = ','), ',', paste0(source_indicator[1:i_indicator], collapse = ','), ')')))
      variation_grouped_level_i <-
        variation_grouped_level_i %>%
        summarise(
          ss = (n() - 1) * var(dat_key),
          mld_times_n = n() * mld(dat_key, dat_weight),
          .groups = 'keep'
        ) %>%
        ungroup()
      variation_grouped_level <- c(variation_grouped_level, list(variation_grouped_level_i))
    }
    for (i_indicator in c(n_indicator:1)) {
      if (i_indicator == n_indicator) {
        variation_grouped_level_i_aggregate <-
          variation_grouped_level[[i_indicator + 1]]
        eval(parse(text = paste0('variation_grouped_level_i_aggregate <- variation_grouped_level_i_aggregate %>% group_by(', paste0(other_indicator, collapse = ','), ',', paste0(source_indicator[1:(i_indicator - 1)], collapse = ','), ')')))
        variation_aggregated_level_i <-
          variation_grouped_level[[i_indicator]] %>%
          left_join(
            .,
            variation_grouped_level_i_aggregate %>%
              summarise(
                ss = sum(ss, na.rm = T),
                mld_times_n = sum(mld_times_n),
                .groups = 'keep'
              ) %>%
              ungroup(),
            by = c(other_indicator, source_indicator[1:(i_indicator - 1)]),
            suffix = c(paste0('_level_', i_indicator - 1), paste0('_level_', i_indicator))
          )
      } else if (i_indicator > 1) {
        variation_grouped_level_i_aggregate <-
          variation_aggregated_level_i
        eval(parse(text = paste0('variation_grouped_level_i_aggregate <- variation_grouped_level_i_aggregate %>% group_by(', paste0(other_indicator, collapse = ','), ',', paste0(source_indicator[1:(i_indicator - 1)], collapse = ','), ')')))
        variation_aggregated_level_i <-
          variation_grouped_level[[i_indicator]] %>%
          left_join(
            .,
            variation_grouped_level_i_aggregate %>%
              summarise_at(
                vars(starts_with(c('ss', 'mld_times_n'))),
                ~sum(., na.rm = T)
              ) %>%
              ungroup(),
            by = c(other_indicator, source_indicator[1:(i_indicator - 1)]),
          ) %>%
          rename(
            !!quo_name(paste0('ss_level_', i_indicator - 1)) := ss,
            !!quo_name(paste0('mld_times_n_level_', i_indicator - 1)) := mld_times_n
          )
      } else {
        variation_grouped_level_i_aggregate <-
          variation_aggregated_level_i
        eval(parse(text = paste0('variation_grouped_level_i_aggregate <- variation_grouped_level_i_aggregate %>% group_by(', paste0(other_indicator, collapse = ','), ')')))
        variation_aggregated_level_i <-
          variation_grouped_level[[i_indicator]] %>%
          left_join(
            .,
            variation_grouped_level_i_aggregate %>%
              summarise_at(
                vars(starts_with(c('ss', 'mld_times_n'))),
                ~sum(., na.rm = T)
              ) %>%
              ungroup(),
            by = other_indicator
          )
      }
    }
    variation_result <-
      variation_aggregated_level_i
    for (i_indicator in c(1:n_indicator)) {
      if (i_indicator == 1) {
        variation_result <-
          variation_result %>%
          mutate(
            indicator_1_ss = 1 - (ss_level_1 / ss),
            indicator_1_mld = 1 - (mld_times_n_level_1 / mld_times_n)
          )
      } else {
        eval(parse(text = paste0('variation_result <- mutate(variation_result, indicator_', i_indicator, '_ss = (ss_level_', i_indicator - 1, ' - ss_level_', i_indicator, ') / ss)')))
        eval(parse(text = paste0('variation_result <- mutate(variation_result, indicator_', i_indicator, '_mld = (mld_times_n_level_', i_indicator - 1, ' - mld_times_n_level_', i_indicator, ') / mld_times_n)')))
      }
    }
    eval(parse(text = paste0('variation_result <- mutate(variation_result, residual_ss = (ss_level_', i_indicator, ') / ss)')))
    eval(parse(text = paste0('variation_result <- mutate(variation_result, residual_mld = (mld_times_n_level_', i_indicator, ') / mld_times_n)')))
    eval(parse(text = paste0('variation_result <- select(variation_result, ', paste0(other_indicator, collapse = ','), ', starts_with(\'indicator_\'), starts_with(\'residual_\'))')))
    for (i_indicator in c(1:n_indicator)) {
      variation_result <-
        variation_result %>%
        rename(
          !!quo_name(paste0(source_indicator[i_indicator], '_ss')) := paste0('indicator_', i_indicator, '_ss'),
          !!quo_name(paste0(source_indicator[i_indicator], '_mld')) := paste0('indicator_', i_indicator, '_mld')
        )
    }
    return(variation_result)
  }
