function [beta, aic, beta_draw] = localProjDiff_bs(y, x, yy, h, m_min, m_max, q_min, q_max, n_bs)
    dy_h_m1 = lagmatrix(y, -h) - lagmatrix(y, 1);
    x_m = [lagmatrix(x(:, 1), m_min), lagmatrix(x(:, 1), (m_min + 1):m_max)];
    dy = [nan; diff(y)];
    dyy = [nan(1, size(yy, 2)); diff(yy)];
    dyy_m = lagmatrix([dy dyy], q_min:q_max);
    % ensure dy_h_m1, x_m, dyy_m all have no nan values
    isnan_dy_h_m1 = any(isnan(dy_h_m1), 2);
    isnan_x_m = any(isnan(x_m), 2);
    isnan_dyy_m = any(isnan(dyy_m), 2);
    isnan_any = any([isnan_dy_h_m1, isnan_x_m, isnan_dyy_m], 2);
    dy_h_m1 = dy_h_m1(~isnan_any, :);
    x_m = x_m(~isnan_any, :);
    dyy_m = dyy_m(~isnan_any, :);
    T = size(dy_h_m1, 1);
    Y = dy_h_m1;
    X = [ones(size(x_m, 1), 1), x_m, dyy_m];
    beta = (X' * X) \ X' * Y;
    u = Y - X * beta;
    % calculate AIC
    aic = log(2 * pi) + log(mean(u .^ 2)) + 2 * size(beta, 1) / T;
    if n_bs > 0
        nvar_X = size(X, 2);
        bs_index = ceil(rand(T, n_bs) * T);
        bs_index(bs_index == 0) = 1;
        Y_bs = Y(bs_index);
        X_reshaped = permute(X, [1, 3, 2]);
        X_bs = reshape(X_reshaped(bs_index, :), T, n_bs, nvar_X);
        Y_bs = permute(Y_bs, [1, 3, 2]);
        X_bs = permute(X_bs, [1, 3, 2]);
        beta_draw = pagemtimes(pagemldivide(pagemtimes(X_bs, "transpose", X_bs, "none"), pagetranspose(X_bs)), Y_bs);
        beta_draw = permute(beta_draw, [3, 1, 2]);
    else
        beta_draw = [];
    end
end