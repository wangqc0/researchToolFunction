function [beta, beta_draw] = localProjDiff(y, x, yy, h, m_min, m_max, q_min, q_max, n_mc)
    dy_h_m1 = lagmatrix(y, -h) - lagmatrix(y, 1);
    x_m = lagmatrix(x, m_min:m_max);
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
    nvar_X = size(X, 2);
    EXX = X' * X;
    % LRV: Newey-West kernel
    Xu = X .* u;
    LRV = xcov(Xu);
    M_kernel = .75 * (T ^ (1 / 3));
    j_kernel = (-(T - 1):(T - 1))';
    kappa = max(1 - abs(j_kernel / M_kernel), 0); 
    LRV = reshape(sum(LRV .* kappa, 1), nvar_X, nvar_X);
    Sigma_beta = ((eye(size(EXX)) / (EXX)) * LRV * (eye(size(EXX)) / (EXX))) / T;
    Sigma_beta = tril(Sigma_beta) + transpose(tril(Sigma_beta)) - diag(diag(Sigma_beta));
    beta_draw = mvnrnd(beta, Sigma_beta, n_mc);
end