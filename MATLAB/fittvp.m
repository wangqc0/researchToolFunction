function [SEstate_LR_M, SVstate_LR_M_se, sumrho, sumrho_se, ...
    trendpi, trendpi_se0, trendpi_br, trendpi_br_se0] = ...
    fittvp(tab_tvp, options)
%FITTVP Time-Varying Parameter estimate used in Boivin (2006), "Has U.S.
%Monetary Policy Changed? Evidence from Drifting Coefficients and Real-Time
%Data", Journal of Money, Credit and Banking, Aug., 2006, Vol. 38, No. 5
%(Aug., 2006), pp. 1149-73.
%   tab_tvp: Timetable of the data, including the dependent variable as the
%   first column, independent variables in the middle, and lagged values of
%   the dependent variable as ending columns
%   (Y: Dependent variable)
%   (X: Independent variables, including lagged values of the dependent
%   variable and the intercept at the end)
%   (Z: Instrumental variables, including the intercept at the end)
%   bp: breakpoints of the trend estimate
%   n_lag: Number of lags of the dependent variable
%   intercept: Indicator of whether the independent variables contain
%   intercept
%   num_sim_cov: Number of simulations when estimating the covariance
%   matrix
%   its: Number of iterations
%   lambda_hp: Parameter of the HP filter
%   SEstate_LR_M: Parameter estimates of the independent variables
%   SVstate_LR_M_se: Standard error of the parameter estimates of the
%   independent variables
%   sumrho: Parameter estimates of the lagged values
%   sumrho_se: Standard error of the parameter estimates of the independent
%   variables
%   trendpi: Parameter estimates of the trend inflation
%   trendpi_se0: Standard error of the parameter estimates of the trend
%   inflation
%   trendpi_br: Parameter estimates of the trend inflation with breakpoints
%   trendpi_br_se0: Standard error of the parameter estimates of the trend
%   inflation with breakpoints
    arguments
        tab_tvp (:, :) timetable
        options.bp (1, :) {mustBeText} = {}
        options.n_lag (1, 1) double = 1
        options.intercept (1, 1) logical = true
        options.num_sim_cov (1, 1) double = 1000
        options.its (1, 1) double = 1000
        options.lambda_hp (1, 1) double = 1600
        options.iv (:, :) timetable = timetable()
    end
    % initialisation
    tvp_bp = options.bp;
    n_lag = options.n_lag;
    n_indepvar = size(tab_tvp, 2) - 1 - n_lag;
    intercept = options.intercept;
    num_sim_cov = options.num_sim_cov;
    its = options.its;
    lambda_hp = options.lambda_hp;
    iv = options.iv;
    Y = tab_tvp(:, 1).Variables;
    X = ifelse(intercept, [tab_tvp(:, 2:end).Variables, ones(size(tab_tvp, 1), 1)], tab_tvp(:, 2:end).Variables);
    Z = ifelse(size(iv, 2) > 0, [iv.Variables, ones(size(iv, 1), 1)], []);
    T = length(Y);
    tvp_period = [datestr(min(tab_tvp.Time), 'yyyy-mm-dd'), tvp_bp, datestr(max(tab_tvp.Time), 'yyyy-mm-dd')];
    % estimate shocks to coefficients
    lambda = max(1, lambda_SW1998(QLR(Y, X), 'QLR'));
    R = cell(numel(tvp_period) - 1, 1);
    SigmaVV = cell(numel(tvp_period) - 1, 1);
    SigmaBB = cell(numel(tvp_period) - 1, 1);
    for p = 1:(numel(tvp_period) - 1)
        period_min = find(tab_tvp.Time == tvp_period(p));
        period_max = find(tab_tvp.Time == tvp_period(p + 1));
        X1 = X(period_min:period_max, :);
        Y1 = Y(period_min:period_max, 1);
        % OLS/IV of the policy reaction function
        if isempty(Z)
            beta = (X1' * X1) \ (X1' * Y1);
        else
            Z1 = Z(period_min:period_max, :);
            PZX1 = (Z1 / (Z1' * Z1)) * Z1' * X1;
            beta = (PZX1' * PZX1) \ (PZX1' * Y1);
        end
        resid = Y1 - X1 * beta;
        % variance of the error term
        R_p = var(resid);
        SigmaXX = (X1' * X1) / length(X1);
        % White-HC consistent estimate
        EXeeX = 0;
        for i = 1:length(X1)
            EXeeX = EXeeX + resid(i) ^ 2 * X1(i, :)' * X1(i, :);
            %EXeeX = EXeeX + R_p * X1(i, :)' * X1(i, :);
        end
        EXeeX = EXeeX / length(X1);
        SigmaVV_p = (SigmaXX \ EXeeX) / SigmaXX;
        % estimate of innovation to coefficients
        SigmaBB_p = (lambda / T) ^ 2 * SigmaVV_p;
        R{p} = R_p;
        SigmaVV{p} = SigmaVV_p;
        SigmaBB{p} = SigmaBB_p;
    end
    % HP filter on series
    rate_hp = Y(:, 1) - X(:, 1) - hpfilter(Y(:, 1) - X(:, 1), lambda_hp);
    indepvar_hp = X(:, 2:n_indepvar) - hpfilter(X(:, 2:n_indepvar), lambda_hp);
    for p = 1:(numel(tvp_period) - 1)
        period_min = find(tab_tvp.Time == tvp_period(p));
        period_max = find(tab_tvp.Time == tvp_period(p + 1));
        period_sample_min = max(1, period_min - 10);
        period_sample_max = min(numel(tab_tvp.Time), period_max + 10);
        rate_hp_br0(period_sample_min:period_sample_max, 1) = Y(period_sample_min:period_sample_max, 1) - X(period_sample_min:period_sample_max, 1) - hpfilter(Y(period_sample_min:period_sample_max, 1) - X(period_sample_min:period_sample_max, 1), lambda_hp);
        indepvar_hp_br0(period_sample_min:period_sample_max, :) = X(period_sample_min:period_sample_max, 2:n_indepvar) - hpfilter(X(period_sample_min:period_sample_max, 2:n_indepvar), lambda_hp);
        rate_hp_br(period_min:period_max, 1) = rate_hp_br0(period_min:period_max, 1);
        indepvar_hp_br(period_min:period_max, :) = indepvar_hp_br0(period_min:period_max, :);
    end
    % kalman filter and smoother
    tvp_period_idx = find(ismember(tab_tvp.Time, datetime(tvp_period)));
    [SEstate, SVstate, KFEstate, KFVstate, KFresid, MLE] = KalmanFSbreaks(Y, X, beta, SigmaBB, R, tvp_period_idx);
    % standard error
    for i = 1:T
        SVstate_se(i, :) = diag(sqrt(squeeze(SVstate(i, :, :))))';
    end
    for i = 1:T
        KFVstate_se(i, :) = diag(sqrt(squeeze(KFVstate(i, :, :))))';
    end
    % long-run response and associated standard error (delta method)
    index_indepvar = 1:n_indepvar;
    index_rho = (n_indepvar + 1):(n_indepvar + n_lag);
    if intercept
        index_intercept = n_indepvar + n_lag + 1;
    end
    for i = 1:T
        % point estimate for the smoother
        SEstate_LR(i, index_indepvar) =  SEstate(i, index_indepvar) / (1 - sum(SEstate(i, index_rho)));
        SEstate_LR(i, index_rho) = SEstate(i, index_rho);
        if intercept
            SEstate_LR(i, index_intercept) = SEstate(i, index_intercept) / (1 - sum(SEstate(i, index_rho)));
        end
        Deriv0 = eye(size(SEstate, 2)) / (1 - sum(SEstate(i, index_rho)));
        Deriv0(:, index_rho) = SEstate(i, :)' / (1 - sum(SEstate(i, index_rho))) ^ 2;
        Deriv0(index_rho, index_rho) = eye(n_lag);
        SVstate_LR(i, :, :) = Deriv0 * squeeze(SVstate(i, : ,:)) * Deriv0';
        SVstate_LR_se(i, :) = diag(sqrt(squeeze(SVstate_LR(i, :, :))))';
    end
    % simulate the covariance matrix of rho at quarterly frequency
    for i = 1:T
        if mod(i, 50) == 0
            disp(i);
        end
        % smoother
        param0 = SEstate_LR(i, :)';
        Vdraw = squeeze(SVstate_LR(i, :, :));
        store_draws = [];
        for convi = 1:num_sim_cov
            rd = randn(size(param0));
            betadraw = param0 + (Vdraw ^ .5) * rd;
            if i < 48
                if numel(index_rho) == 1
                    rho_con = averaging(betadraw(index_rho), 3, 2000);
                else
                    rho_con = averaging_multirho(betadraw(index_rho), 3, 2000);
                end
            else
                if numel(index_rho) == 1
                    rho_con = averaging(betadraw(index_rho), 2, 2000);
                else
                    rho_con = averaging_multirho(betadraw(index_rho), 2, 2000);
                end
            end
            betadraw_mod = betadraw;
            betadraw_mod(index_rho) = rho_con;
            if intercept
                betadraw_mod(index_intercept) = betadraw(index_intercept) * (1 - sum(rho_con));
            end
            store_draws = [store_draws; betadraw_mod'];
        end
        store_drawsM = nanmean(store_draws);
        SEstate_LR_M(i, :) = SEstate_LR(i, :);
        SEstate_LR_M(i, index_rho) = store_drawsM(index_rho);
        SEstate_LR_M(i, index_intercept) = param0(index_intercept) * (1 - sum(store_drawsM(index_rho)));
        SVstate_LR_M(i, :, :) = nancov(store_draws);
        SVstate_LR_M_se(i, :) = diag(sqrt(cov(store_draws)))';
    end
    % construct sum of AR coefficient
    sumrho = sum(SEstate_LR_M(:, index_rho), 2);
    sumrho_se = [];
    for i = 1:T
        Deriv0 = ones(1, n_lag);
        MM = Deriv0 * squeeze(SVstate_LR_M(i, index_rho, index_rho)) * Deriv0';
        sumrho_se(i, 1) = sqrt(squeeze(MM));
    end
    % implied trend inflation
    Denom = 1 - SEstate_LR_M(:, 1) .* (1 - sum(SEstate_LR_M(:, index_rho), 1)) - sum(SEstate_LR_M(:, index_rho), 1);
    if intercept
        interceptM0 = SEstate_LR_M(:, index_intercept);
        trendpi_br(:, 1) = (interceptM0 - rate_hp_br(:, 1) .* (1 - sum(SEstate_LR_M(:, index_rho), 1)) ...
            + sum(indepvar_hp_br .* SEstate_LR_M(:, 2:n_indepvar) .* (1 - sum(SEstate_LR_M(:, index_rho), 2)), 2)) ...
            ./ Denom;
        trendpi(:, 1) = (interceptM0 - rate_hp(:, 1) .* (1 - sum(SEstate_LR_M(:, index_rho), 1)) ...
            + sum(indepvar_hp .* SEstate_LR_M(:, 2:n_indepvar) .* (1 - sum(SEstate_LR_M(:, index_rho), 2)), 2)) ...
            ./ Denom;
    end
    % trend inflation standard error (delta method)
    trendpi_br_se0 = [];
    trendpi_se0 = [];
    for i = 1:T
        Denom000 = 1 - SEstate_LR_M(i, 1) .* (1 - sum(SEstate_LR_M(i, index_rho))) - sum(SEstate_LR_M(i, index_rho));
        if intercept
            Numerator_br = (interceptM0(i, 1) - rate_hp_br(i, 1) .* (1 - sum(SEstate_LR_M(i, index_rho))) ...
                + sum(indepvar_hp_br(i, :) .* SEstate_LR_M(i, 2:n_indepvar) .* (1 - sum(SEstate_LR_M(i, index_rho))), 2));
            Numerator = (interceptM0(i, 1) - rate_hp(i, 1) .* (1 - sum(SEstate_LR_M(i, index_rho))) ...
                + sum(indepvar_hp(i, :) .* SEstate_LR_M(i, 2:n_indepvar) .* (1 - sum(SEstate_LR_M(i, index_rho))), 2)); ...
            Deriv0 = [
                Numerator_br * (1 - sum(SEstate_LR_M(i, index_rho))) / Denom000 ^ 2;
                indepvar_hp_br(i, :)' * (1 - sum(SEstate_LR_M(i, index_rho))) / Denom000;
                interceptM0(i, 1) * (1 - SEstate_LR_M(i, 1)) / Denom000 ^ 2;
                1 / Denom000;
                ];
            MM = Deriv0' * squeeze(SVstate_LR_M(i, :, :)) * Deriv0;
            trendpi_br_se0(i, 1) = diag(sqrt(squeeze(MM)))';
            Deriv0 = [
                Numerator * (1 - sum(SEstate_LR_M(i, index_rho))) / Denom000 ^ 2;
                indepvar_hp(i, :)' * (1 - sum(SEstate_LR_M(i, index_rho))) / Denom000;
                interceptM0(i, 1) * (1 - SEstate_LR_M(i, 1)) / Denom000 ^ 2;
                1 / Denom000;
                ];
            MM = Deriv0' * squeeze(SVstate_LR_M(i, :, :)) * Deriv0;
            trendpi_se0(i, 1) = diag(sqrt(squeeze(MM)))';
        end
    end
end