function [beta, beta_draw] = sem(y, x, yy, h, m_min, m_max, q_min, q_max, n_mc)
    % yy: additional variables to add beyond y
    y_h = lagmatrix(y, -h);
    x_m = lagmatrix(x, m_min:m_max);
    yy_m = lagmatrix([y yy], q_min:q_max);
    n_discard_begin = max(max(m_max, q_max + 1), 1);
    n_discard_end = h;
    y_h = y_h((1 + n_discard_begin):(end - n_discard_end));
    x_m = x_m((1 + n_discard_begin):(end - n_discard_end), :);
    yy_m = yy_m((1 + n_discard_begin):(end - n_discard_end), :);
    T = size(y_h, 1);
    Y = y_h;
    X = [ones(size(x_m, 1), 1), x_m, yy_m];
    beta = (X' * X) \ X' * Y;
    u = Y - X * beta;
    nvar_X = size(X, 2);
    EXX = mean(pagemtimes(pagetranspose(reshape(X', nvar_X, 1, T)), reshape(X', nvar_X, 1, T)), 3);
    % LRV: Newey-West kernel
    Xu = X .* u;
    LRV = xcov(Xu);
    M_kernel = .75 * (T ^ (1 / 3));
    j_kernel = (-(T - 1):(T - 1))';
    kappa = max(1 - abs(j_kernel / M_kernel), 0); 
    LRV = reshape(sum(LRV .* kappa, 1), nvar_X, nvar_X);
    beta_draw = mvnrnd(beta, ((eye(size(EXX)) / (EXX)) * LRV * (eye(size(EXX)) / (EXX))) / T, n_mc);
end