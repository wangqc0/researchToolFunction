# revise `as.factor` to include numbers between the minimum and the maximum not encoded as factors:
as.factor_all <- function(x){
  ran <- c(min(x):max(x))
  y <- as.factor(c(x, ran))
  y[1:length(x)]
}
