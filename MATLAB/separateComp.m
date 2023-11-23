function series_decomp = separateComp(series, numlag, numlag_ma)
%SEPARATECOMP The algorighm used to separate short-run cyclical and
% long-run potential components of time series data using VAR approach. An
% example is Blanchard and Quah (1989)'s application on output and
% unemployment (see us_gdp_unemp.m). The first component of the innovation
% is transitory. Detrend the series before use.
%   series: detrended time series used to separate into components
%   numlag: number of lags in the VAR
%   numlag_ma: number of lags in the inverted moving average series
    if (size(series, 1) < numlag + 2)
        error('Insufficient number of observation given number of lag')
    end
    numvar = size(series, 2);
    % apply the VAR
    mdl = varm(numvar, numlag);
    [estMdl, ~, ~, eps] = estimate(mdl, series);
    % invert the representation to moving average series
    var0 = cellfun(@(x){-x}, estMdl.AR);
    var0 = {eye(numvar), var0{1:length(var0)}};
    VARLag = LagOp(var0, 'Lags', 0:numlag);
    VMALag = LagOp(eye(numvar), 'Lags', 0);
    VMA = arma2ma(VARLag, VMALag, numlag_ma);
    %vmaCoef = toCellArray(VMA);
    vmaCoef = reshape(cell2mat(toCellArray(VMA)), [numvar numvar numlag_ma + 1]);
    Omega = estMdl.Covariance;
    % recover disturbance series from moving average series
    vmaCoef_sum = sum(vmaCoef, 3);
%     vmaCoef_sum = zeros(numvar);
%     for i = 1:length(vmaCoef)
%         vmaCoef_sum = vmaCoef_sum + vmaCoef{i};
%     end
    syms A0 [numvar numvar]
    cond_1 = A0 * transpose(A0) == Omega;
    cond_1 = reshape(cond_1, [numel(cond_1) 1]);
    cond_2 = [1 0] * (vmaCoef_sum * A0) * [1; 0] == 0;
    A = vpasolve([cond_1; cond_2], A0);
    A_0 = zeros(numvar);
    for i = 1:numvar
        for j = 1:numvar
            eval(strcat('A_0(', num2str(i), ', ', num2str(j), ') = A.A0', num2str(i), '_', num2str(j), '(3);'))
        end
    end
    %vmaA = cellfun(@(x){x * A_0}, vmaCoef);
    vmaA = pagemtimes(vmaCoef, A_0);
    dist = eps / transpose(A_0);
    % recover the original series
    dist_lag = lagmatrix(dist, 0:numlag_ma);
    dist_lag(isnan(dist_lag)) = 0;
    dist_lag = reshape(dist_lag, [size(dist_lag, 1) numvar numlag_ma + 1]);
    dist_decomp = zeros([size(dist_lag) numvar]);
    for j = 1:numvar
        dist_decomp(:, j, :, j) = dist_lag(:, j, :);
    end
    series_decomp = sum(pagemtimes(dist_decomp, 'none', vmaA, 'transpose'), 3);
    series_decomp = squeeze(series_decomp);
%     for j = 1:numvar
%         series_decomp_j = zeros(size(dist));
%         for i = 0:numlag_ma
%             dist_j_i = zeros(size(dist));
%             dist_j_i((i + 1):end, j) = dist(1:(end - i), j);
%             series_decomp_j_i = dist_j_i * transpose(vmaA{i + 1});
%             series_decomp_j = series_decomp_j + series_decomp_j_i;
%         end
%         series_decomp(:, :, j) = series_decomp_j;
%     end
end