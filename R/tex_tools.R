# highlight values in a line in a latex regression table
tex_line_highlight <- function (tex, var_label, n_col, col_highlight, color_highlight) {
  # tex: tex object (string)
  # var_label: the label of the variable to highlight (string)
  # n_col: number of columns (integer)
  # col_highlight: indices of columns to highlight (vector)
  # color_highlight: the color used to highlight (string)
  str_to_replace <- paste0(var_label, paste0(rep(' & (.*)', n_col), collapse = ''), '\\\\\\\\')
  str_replace_by <- var_label
  for (k in 1:n_col) {
    if (k %in% col_highlight) {
      str_replace_by <- paste0(str_replace_by, ' & \\\\textcolor{', color_highlight, '}{\\', k, '}')
    } else {
      str_replace_by <- paste0(str_replace_by, ' & \\', k, '')
    }
  }
  str_replace_by <- paste0(str_replace_by, '\\\\\\\\')
  tex_highlighted <- str_replace(tex, str_to_replace, str_replace_by)
  return(tex_highlighted)
}

tex_line_highlight_textbf <- function (tex, var_label, n_col, col_highlight) {
  # tex: tex object (string)
  # var_label: the label of the variable to highlight (string)
  # n_col: number of columns (integer)
  # col_highlight: indices of columns to highlight (vector)
  str_to_replace <- paste0(var_label, paste0(rep(' & (.*)', n_col), collapse = ''), '\\\\\\\\')
  str_replace_by <- var_label
  for (k in 1:n_col) {
    if (k %in% col_highlight) {
      str_replace_by <- paste0(str_replace_by, ' & \\\\textbf{\\', k, '}')
    } else {
      str_replace_by <- paste0(str_replace_by, ' & \\', k, '')
    }
  }
  str_replace_by <- paste0(str_replace_by, '\\\\\\\\')
  tex_highlighted <- str_replace(tex, str_to_replace, str_replace_by)
  return(tex_highlighted)
}