# row bind data frames in a list with different number of columns and column names:
bind_rows_diff <- function(input_list){
  name_col <- unique(unlist(lapply(input_list, function(x){colnames(x)})))
  output_df <- lapply(input_list, function(x){
    name_col_na <- setdiff(name_col, colnames(x))
    col_na <- data.frame(matrix(nrow = 1, ncol = length(name_col_na)))
    colnames(col_na) <- name_col_na
    cbind.data.frame(x, col_na)
  })
  output_df <- do.call(rbind.data.frame, output_df)
}
