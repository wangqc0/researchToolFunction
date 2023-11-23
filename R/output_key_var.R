# output essential information about one key variable from a list of regression models (rq and lm):
output_key_var <-
  function(mdl, key_var, summary_se = NA) {
    lapply(
      mdl,
      function(x) {
        if (!is.na(summary_se)) {
          output_summary <- summary(x, se = summary_se)
        } else {
          output_summary <- summary(x)
        }
        coefficients_var <- colnames(output_summary[['coefficients']])
        if ('Std. Error' %in% coefficients_var) {
          cbind.data.frame(
            Coefficient = output_summary[['coefficients']][key_var, 1],
            `Standard error` = output_summary[['coefficients']][key_var, c('Std. Error')],
            `p value` = output_summary[['coefficients']][key_var, c('Pr(>|t|)')],
            Observations = length(output_summary[['residuals']])
          )
        } else {
          key_var_coef <- output_summary[['coefficients']][key_var, 1]
          key_var_n <- length(output_summary[['residuals']])
          key_var_se <-  ((output_summary[['coefficients']][key_var, c('upper bd')] - output_summary[['coefficients']][key_var, c('lower bd')]) / 2) / qt(.975, key_var_n - nrow(output_summary[['coefficients']]))
          cbind.data.frame(
            Coefficient = key_var_coef,
            `Standard error` = key_var_se,
            `p value` = pt(abs(key_var_coef) / key_var_se, key_var_n - nrow(output_summary[['coefficients']]), lower.tail = F),
            Observations = key_var_n
          )
        }
      }
    ) %>%
      do.call('rbind', .) %>%
      as.data.frame()
  }
