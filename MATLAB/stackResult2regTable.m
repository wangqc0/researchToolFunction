function [output, output_row, output_column] = stackResult2regTable(result, options)
%STACKRESULT2REGTABLE Convert stacked regression results generated by
%'stack_result' to a regression table exportable to latex
%   result: stacked table
%   options: options for the table
%   output: regression table
%   output_row: row names of the table
%   output_column: column names of the table
    arguments
        result table
        options.lagAtBottom (1, 1) logical = false % locate variables ended with 'M[0-9]' to the bottom
        options.orderIndependentVariable cell = {} % an array of independent variable names
        options.underscore (1, 1) logical = true % replace string '_' by '\_'
    end
    % estimator
    est = result(result.Type == 'Estimate' | result.Type == 'SE' | result.Type == 'pValue', :);
    est_unstack = unstack(est, 'Value', 'Type');
    getStar = @(x, y) ifelse(y < 0.1, ...
        ifelse(y < 0.05, ifelse(y < 0.01, strcat(num2str(x), '$^{***}$'), strcat(num2str(x), '$^{**}$')), strcat(num2str(x), '$^{*}$')), ...
        num2str(x));
    est_unstack.Estimate = cellfun(@(x) sprintf('%0.4f', x), num2cell(est_unstack.Estimate), 'UniformOutput', false);
    est_unstack.SE = cellfun(@(x) strcat('(', sprintf('%0.4f', x), ')'), num2cell(est_unstack.SE), 'UniformOutput', false);
    for i = 1:size(est_unstack, 1)
        est_unstack.Estimate(i) = cellstr(getStar(est_unstack.Estimate{i}, est_unstack.pValue(i)));
    end
    est_unstack = removevars(est_unstack, {'pValue'});
    est = stack(est_unstack, {'Estimate', 'SE'}, 'NewDataVariableName', 'Value', 'IndexVariableName', 'Type');
    est_model = unique(est_unstack.Model);
    est_unstack = unstack(est, 'Value', 'Model');
    est_unstack = unstack(est_unstack, est_model, 'Spec', 'VariableNamingRule', 'modify');
    est_unstack.Type = cellstr(est_unstack.Type);
    for i = 1:size(est_unstack, 1)
        if strcmp(est_unstack.Type(i), 'SE')
            est_unstack.Variable(i) = '';
        end
    end
    est_unstack = removevars(est_unstack, {'Type'});
    % statistic
    stat = result(result.Type == 'Value', :);
    stat.Value = cellfun(@(x) sprintf('%0.4f', x), num2cell(stat.Value), 'UniformOutput', false);
    stat.Value(stat.Variable == 'Observation') = cellfun(@(x) sprintf('%0.0i', str2double(x)), stat.Value(stat.Variable == 'Observation'), 'UniformOutput', false);
    stat_model = unique(stat.Model);
    stat_unstack = unstack(stat, 'Value', 'Model');
    stat_unstack = unstack(stat_unstack, stat_model, 'Spec', 'VariableNamingRule', 'modify');
    stat_unstack = removevars(stat_unstack, {'Type'});
    % output
    output = [est_unstack; stat_unstack];
    output = output(:, ~all(ismissing(output)));
    if options.underscore
        output.Variable = strrep(output.Variable, '_', '\_');
    end
    output.Variable = string(renamecats(categorical(output.Variable), {'(Intercept)', 'Rsquared', 'RsquaredAdj'}, {'Intercept', '$R^2$', '$R^2_{adj}$'}));
    output.Variable(ismissing(output.Variable)) = '';
    output_row = cellstr(output.Variable);
    output = removevars(output, {'Variable'});
    output_column = cellstr(strcat('(', num2str((1:size(output, 2))'), ')'));
    output = output.Variables;
    % change the order of independent variables
    if numel(options.orderIndependentVariable) > 0
        output_row_empty = cellfun(@isempty, output_row);
        output_row_stat = ((find(output_row_empty, 1, 'last') + 1):numel(output_row))';
        output_row_x = (1:find(output_row_empty, 1, 'last'))';
        output_row_x_intercept = find(strcmp(output_row(output_row_x), 'Intercept'));
        output_row_x_intercept = [output_row_x_intercept; output_row_x_intercept + 1];
        output_row_x_nointercept = setdiff(output_row_x, output_row_x_intercept);
        output_row_x_order_origin = output_row(output_row_x_nointercept);
        output_row_x_order_origin = output_row_x_order_origin(~ismissing(output_row_x_order_origin));
        output_row_x_order_new = options.orderIndependentVariable;
        if options.underscore
            output_row_x_order_new = strrep(output_row_x_order_new, '_', '\_');
        end
        [~, ~, index_new_to_origin] = intersect(output_row_x_order_new, output_row_x_order_origin, 'stable');
        output_row_x_nointercept_new = reshape([2 * index_new_to_origin - 1 2 * index_new_to_origin]', 2 * size(index_new_to_origin, 1), 1);
        output_row_index = [output_row_x_intercept; output_row_x_nointercept_new + numel(output_row_x_intercept); output_row_stat];
        output_row = output_row(output_row_index);
        output = output(output_row_index, :);
    end
    % change the independet variables' positions to locate lagged variables
    % at the bottom
    if options.lagAtBottom
        output_row_empty = cellfun(@isempty, output_row);
        output_row_stat = ((find(output_row_empty, 1, 'last') + 1):numel(output_row))';
        output_row_x = (1:find(output_row_empty, 1, 'last'))';
        output_row_M = find(cellfun(@(x) ~isempty(x), regexp(output_row, '\_M[0-9]', 'match')));
        output_row_M = reshape([output_row_M output_row_M + 1]', 2 * size(output_row_M, 1), 1);
        output_row_x_noM = setdiff(output_row_x, output_row_M);
        output_row_index = [output_row_x_noM; output_row_M; output_row_stat];
        output_row = output_row(output_row_index);
        output = output(output_row_index, :);
    end
end