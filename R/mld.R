# calculate the mean log deviation (MLD) given incomes and weights:
mld <-
  function (income, weight = NA) {
    if (nargs() < 2) {
      weight = rep(1, length(income))
    }
    income_weight <- data.frame(income, weight)
    income_weight <- income_weight[complete.cases(income_weight),]
    income_weight <- income_weight[order(income_weight$income),]
    mld <- mean(log(mean(income_weight$income, weight = income_weight$weight) / income_weight$income), weight = income_weight$income)
    return(mld)
  }
