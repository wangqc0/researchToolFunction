# output the regression table of modelsummary to irf
# only used when the names of the list of the regressions follow the "t+(\\d)" format
reg_modelsummary_df_to_irf <-
  function (df, confidence_level = 90) {
    h <-
      df %>%
      select(starts_with("t+")) %>%
      colnames(.) %>%
      str_replace(., "t\\+", "") %>%
      as.integer()
    point_estimate <-
      df %>%
      select(starts_with("t+")) %>%
      slice(1) %>%
      str_remove_all(., "(\\*|\\+)") %>%
      as.double()
    se <-
      df %>%
      select(starts_with("t+")) %>%
      slice(2) %>%
      str_remove_all(., "(\\(|\\))") %>%
      as.double()
    nobs <-
      df %>%
      select(starts_with("t+")) %>%
      slice(3) %>%
      as.integer(.)
    bandwidth <-
      se * qt(1 - (1 - confidence_level / 100) / 2, nobs)
    irf <-
      data.frame(
        h = h,
        point_estimate = point_estimate,
        lower_bound = point_estimate - bandwidth,
        upper_bound = point_estimate + bandwidth
      )
    return (irf)
  }