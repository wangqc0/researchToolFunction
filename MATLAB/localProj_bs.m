function [beta, aic, beta_draw] = localProj_bs(y, x, yy, h, m_min, m_max, q_min, q_max, n_bs)
    % yy: additional variables to add beyond y
    y_h = lagmatrix(y, -h);
    x_m = [lagmatrix(x(:, 1), m_min), lagmatrix(x(:, 1), (m_min + 1):m_max)];
    yy_m = lagmatrix([y yy], q_min:q_max);
    isnan_y_h = any(isnan(y_h), 2);
    isnan_x_m = any(isnan(x_m), 2);
    isnan_yy_m = any(isnan(yy_m), 2);
    isnan_any = any([isnan_y_h, isnan_x_m, isnan_yy_m], 2);
    y_h = y_h(~isnan_any, :);
    x_m = x_m(~isnan_any, :);
    yy_m = yy_m(~isnan_any, :);
    T = size(y_h, 1);
    Y = y_h;
    X = [ones(size(x_m, 1), 1), x_m, yy_m];
    beta = (X' * X) \ X' * Y;
    u = Y - X * beta;
    % calculate AIC
    aic = T * (log(2 * pi) + log(mean(u .^ 2))) + 2 * size(beta, 1);
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