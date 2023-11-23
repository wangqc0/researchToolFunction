function string_wrapped = latex_wrap_cell(string, delimiter, delimiter_max)
%LATEX_WRAP_CELL Wrap long strings so they do not occupy too much space in
%LaTex format
%   string: the string to convert
%   delimiter: a string of delimiter to identify the location of line break
%   delimiter_max: the maximum number of delimiter in the line to break
    strings = strsplit(string, delimiter);
    n_string = numel(strings);
    if n_string == 1 || delimiter_max == 0
        string_wrapped = string;
    else
        n_rejoin = max(0, n_string - delimiter_max - 1);
        if n_rejoin > 0
            strings = [strings(1:delimiter_max), strjoin(strings((delimiter_max + 1):end), delimiter)];
        end
        string_wrapped = ['\begin{tabular}{@{}c@{}}', strjoin(strings, '\\\'), '\end{tabular}'];
    end
end