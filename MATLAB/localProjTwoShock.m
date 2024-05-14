function [beta, aic, beta_draw] = localProjTwoShock(y, x, yy, h, m_1_min, m_1_max, m_2_min, m_2_max, q_min, q_max, n_mc)
    % yy: additional variables to add beyond y
    y_h = lagmatrix(y, -h);
    x_m = [lagmatrix(x(:, 1), m_1_min), lagmatrix(x(:, 2), m_2_min), lagmatrix(x(:, 1), (m_1_min + 1):m_1_max), lagmatrix(x(:, 2), (m_2_min + 1):m_2_max)];
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
    if n_mc > 0
        nvar_X = size(X, 2);
        EXX = X' * X;
        %EXX = mean(pagemtimes(pagetranspose(reshape(X', nvar_X, 1, T)), reshape(X', nvar_X, 1, T)), 3);
        % LRV: Newey-West kernel
        Xu = X .* u;
        LRV = xcov(Xu);
        M_kernel = .75 * (T ^ (1 / 3));
        j_kernel = (-(T - 1):(T - 1))';
        kappa = max(1 - abs(j_kernel / M_kernel), 0); 
        LRV = reshape(sum(LRV .* kappa, 1), nvar_X, nvar_X) * T;%
        Sigma_beta = ((eye(size(EXX)) / (EXX)) * LRV * (eye(size(EXX)) / (EXX))) / T;
        Sigma_beta = tril(Sigma_beta) + transpose(tril(Sigma_beta)) - diag(diag(Sigma_beta));
        beta_draw = mvnrnd(beta, Sigma_beta, n_mc);
    else
        beta_draw = [];
    end
end