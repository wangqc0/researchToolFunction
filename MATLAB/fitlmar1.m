function result = fitlmar1(tt, form)
%FITLMAR1 Return estimate and summary for regARIMA(1, 0, 0) model
%   tt: timetable
%   form: formula in Wilkinson notation
%   result: output model
    yX = split(form, '~');
    y = strtrim(yX{1});
    X = strtrim(split(yX{2}, '+'));
    eval(strcat('est = estimate(regARIMA(1, 0, 0), tt.', y, ', ''X'', tt{:, X}, ''Display'', ''off'');'))
    result = summarize(est);
    fn = fieldnames(est);
    for i = 1:numel(fn)
        result.(fn{i}) = est.(fn{i});
    end
    result.Table.Properties.VariableNames = {'Estimate', 'SE', 'tStat', 'pValue'};
    result.Table.Properties.RowNames = ['(Intercept)'; 'e_M1'; string(X); 'Variance'];
    % delete the 'Variance' row
    result.Table = result.Table(1:(end - 1), :);
    % Rsquared
    row_has_not_nan = ~any(isnan(tt{:, [y; X]}), 2);
    est_y = tt{row_has_not_nan, y};
    est_X = tt{row_has_not_nan, X};
    est_beta = (est.Beta)';
    est_e = est_y - (est_X * est_beta + est.Intercept);
    est_e_M1 = tshift(est_e, -1);
    est_e_M1 = [est_e_M1(2) / est.AR{1}; est_e_M1(2:end)];
    est_yhat = est_X * est_beta + est.Intercept + est.AR{1} * est_e_M1;
    rsq = 1 - sum((est_y - est_yhat) .^ 2) / sum((est_y - mean(est_y)) .^ 2);
    rsqa = 1 - (1 - rsq) * (result.SampleSize - 1) / (result.SampleSize - numel(est_beta) - 1 - 1);
    result.Rsquared.Ordinary = rsq;
    result.Rsquared.Adjusted = rsqa;
end