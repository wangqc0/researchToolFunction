# calculate the gini coefficient given incomes and weights:
gini <-
  function(income, weight = NA) {
    if (nargs() < 2) {
      weight = rep(1, length(income))
    }
    income_weight <- data.frame(income, weight)
    income_weight <- income_weight[complete.cases(income_weight),]
    income_weight <- income_weight[order(income_weight$income),]
    income_weight$cum_income_lead <- cumsum(income_weight$income)
    income_weight$cum_income_times_weight_lead <- income_weight$cum_income_lead * income_weight$weight
    income_weight$cum_income_lag <- c(0, income_weight$cum_income_lead[-nrow(income_weight)])
    income_weight$cum_income_times_weight_lag <- income_weight$cum_income_lag * income_weight$weight
    income_weight$cum_income_times_weight <- (income_weight$cum_income_times_weight_lead + income_weight$cum_income_times_weight_lag) / 2
    accumulated <- sum(income_weight$cum_income_times_weight)
    bin <- sum(income_weight$weight)
    accumulated_max <- bin * max(income_weight$cum_income_lead) / 2
    gini <- 1 - accumulated / accumulated_max
    return(gini)
  }
