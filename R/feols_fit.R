# obtain fitted values of a variable in a data frame based on fixed effects
# the function requires package `fixest`
feols_fit <-
  function (df, variable_of_interest, variable_fixed_effect, fit_all, name_fitted_variable) {
    # df: data frame
    # variable_of_interest: a string of the variable to fit
    # variable_fixed_effect: a string vector of indicators of fixed effects
    # calculate_fit_all: a logical indicator indicating whether to return fit-all column
    # name_fitted_variable: a vector specifying the names of the fitted column attached to the data frame
    if (nargs() < 5) {
      name_fitted_variable <-
        c(
          paste0(variable_of_interest, '_residual'),
          paste0(variable_of_interest, '_fit'),
          paste0(variable_of_interest, '_fit_all')
        )
      if (nargs() < 4) {
        name_fitted_variable <- name_fitted_variable[1:2]
        fit_all <- FALSE
      }
    }
    if (length(intersect(colnames(df), name_fitted_variable)) > 0) {
      stop('Fitted variable names overlap with existing column names. Please rename according to: residual, fitted values, all fitted values (including NA rows).')
    }
    feols_df_formula <-
      as.formula(paste0(variable_of_interest, ' ~ 0 | ', paste0(variable_fixed_effect, collapse = ' + ')))
    feols_df <- 
      feols(
        fml = feols_df_formula,
        data = df[!is.na(df[[variable_of_interest]]),]
      )
    feols_df_fit <-
      list(
        'residual' = feols_df[['residuals']],
        'fit' = feols_df[['fitted.values']],
        'rsq_adj' = 1 - (feols_df[['ssr']] / feols_df[['ssr_null']]) * (feols_df[['nobs']] - 1) / (feols_df[['nobs']] - feols_df[['nparams']])
      )
    feols_df_fixef <- fixef(feols_df)
    df[!is.na(df[[variable_of_interest]]), name_fitted_variable[1]] <- feols_df_fit[['residual']]
    df[!is.na(df[[variable_of_interest]]), name_fitted_variable[2]] <- feols_df_fit[['fit']]
    # fit rows with NA by fixed-effect-interpolation
    if (fit_all) {
      df[, name_fitted_variable[3]] <- df[, name_fitted_variable[2]]
      df_na <- df[is.na(df[[variable_of_interest]]), variable_fixed_effect]
      variable_of_interest_na_fit <- c()
      for (j in 1:nrow(df_na)) {
        variable_of_interest_na_fit_j <- 0
        for (k in 1:length(variable_fixed_effect)) {
          name_fixed_effect_j_k <- as.character(df_na[j, variable_fixed_effect[k]])
          variable_fixed_effect_j_k <- feols_df_fixef[[variable_fixed_effect[k]]][name_fixed_effect_j_k]
          variable_of_interest_na_fit_j <- variable_of_interest_na_fit_j + variable_fixed_effect_j_k
        }
        variable_of_interest_na_fit <- c(variable_of_interest_na_fit, variable_of_interest_na_fit_j)
      }
      df[is.na(df[[variable_of_interest]]), name_fitted_variable[3]] <- variable_of_interest_na_fit
    }
    return(df)
  }