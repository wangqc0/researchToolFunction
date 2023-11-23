function result = fitlmiv(tt, form, iv)
%FITLMIV Run estimate and summary for a linear regression model with
%instrumental variables
%   tt: timetable
%   form: formula in Wilkinson notation
%   iv: instrumental variables in a cell array
%   result: output model
    yX = split(form, '~');
    y_name = strtrim(yX{1});
    X_name = strtrim(split(yX{2}, '+'));
    y = tt(:, y_name).Variables;
    X = [ones(size(tt, 1), 1), tt(:, X_name).Variables];
    Z = [ones(size(tt, 1), 1), tt(:, iv).Variables];
    % keep complete rows
    index_valid = ~ismissing(y) & ~any(ismissing(X), 2) & ~any(ismissing(Z), 2);
    y = y(index_valid);
    X = X(index_valid, :);
    Z = Z(index_valid, :);
    % tsls
    N = length(y);
    K = size(X, 2);
    df = N - K;
    PZX = (Z / (Z' * Z)) * Z' * X;
    beta_2sls = ((PZX' * PZX) \ PZX') * y;
    u_iv = y - X * beta_2sls;
    s_est = u_iv' * u_iv / df;
    var_est = s_est * inv(PZX' * PZX);
    stderr  = sqrt(diag(var_est));
    t_stat  = beta_2sls ./ stderr;
    pval = betainc(df ./ (df + (1 .* t_stat .^ 2)), (df ./ 2), (1 ./ 2));
    % result
    result.Description = 'IV Model (Gaussian Distribution)';
    result.SampleSize = N;
    result.NumEstimatedParameters = K;
    var = sum(u_iv .^2) / df;
    result.LogLikelihood = -(N / 2) * (log(2 * pi) + log(var)) - sum(u_iv .^2) / (2 * var);
    result.AIC = 2 * result.NumEstimatedParameters - 2 * result.LogLikelihood;
    result.BIC = log(result.SampleSize) * result.NumEstimatedParameters - 2 * result.LogLikelihood;
    result.Table = table(beta_2sls, stderr, t_stat, pval, 'RowNames', ['(Intercept)'; X_name], 'VariableNames', {'Estimate', 'SE', 'tStat', 'pValue'});
    result.Intercept = beta_2sls(1);
    result.Beta = beta_2sls(2:end)';
    result.Variance = var;
    % Rsquared
    rsq = 1 - sum(u_iv .^ 2) / sum((y - mean(y)) .^ 2);
    rsqa = 1 - (1 - rsq) * (result.SampleSize - 1) / (result.SampleSize - numel(beta_2sls) - 1);
    result.Rsquared.Ordinary = rsq;
    result.Rsquared.Adjusted = rsqa;
end