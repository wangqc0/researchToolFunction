function output = summaryStat(input, stat_fun, stat_name)
%SUMMARYSTAT Summary statistics of a table or timetable
%   input: table or time table
%   stat_fun: function of statistics to show
%   stat_name: name of statistics to show
    arguments
        input table
        stat_fun (1, :) = {@(x)(numel(x(~ismissing(x)))), @(x)(mean(x, 'omitnan')), ...
            @(x)(median(x, 'omitnan')), @(x)(min(x, [], 'omitnan')), ...
            @(x)(max(x, [], 'omitnan')), @(x)(var(x, 0, 'omitnan'))}
        stat_name (1, :) string = {'N', 'Mean', 'Median', 'Min', 'Max', 'Variance'}
    end
    % check number of function and name match
    if numel(stat_fun) ~= numel(stat_name)
        error('Number of functions and number of function names should match.')
    end
    % delete non-numeric variables
    input_varname = input.Properties.VariableNames;
    for i = 1:numel(input_varname)
        var_is_numeric(i) = isnumeric(input.(input_varname{i}));
    end
    input = input(:, var_is_numeric);
    input_varname = input_varname(var_is_numeric);
    output = nan(numel(input_varname), numel(stat_fun));
    for i = 1:size(input, 2)
        for j = 1:numel(stat_fun)
            stat_fun_j = stat_fun{j};
            try
                output(i, j) = stat_fun_j(input{:, i});
            catch
            end
        end
    end
    output = array2table(output);
    output.Properties.RowNames = input_varname;
    output.Properties.VariableNames = stat_name;
end