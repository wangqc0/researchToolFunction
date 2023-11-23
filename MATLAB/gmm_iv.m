function [para_est_2, avar] = gmm_iv(y, X, Z)
%GMM_IV Using the two-step Generalized Method of Moments (GMM) to estimate
%IV conditions in a linear regression model
%   y: dependent variable
%   X: independent variables
%   Z: instrumental variables, including all elements in X except
%   endogenous variables
%   para: parameter estimates
%   avar: asymptotic variance-covariance matrix
    N = length(y);
    K = size(X, 2);
    L = size(Z, 2);
    para_0 = zeros(K, 1);
    g_cost_c = @(para, iv) iv .* (y - X * para);
    g_cost_v = @(para) g_cost_c(para, Z(:, 1));
    for i = 1:(L - 1)
        g_cost_v = @(para) [g_cost_v(para), g_cost_c(para, Z(:, i + 1))];
    end
    d_g_cost_c = @(para, iv) iv .* (-X);
    d_g_cost_v = @(para) d_g_cost_c(para, Z(:, 1));
    for i = 1:(L - 1)
        d_g_cost_v = @(para) [d_g_cost_v(para), d_g_cost_c(para, Z(:, i + 1))];
    end
    fminunc_options = optimoptions('fminunc', 'OptimalityTolerance', 1.0000e-08, ...
        'MaxIterations', 1500, 'FunctionTolerance', 1.0000e-08, 'Display', 'off');
    % first step
    g_L_cost_c = @(para) mean(g_cost_v(para), 1) * mean(g_cost_v(para), 1)';
    para_est_1 = fminunc(g_L_cost_c, para_0, fminunc_options);
    v_cost_1 = g_cost_v(para_est_1);
    S_est_1 = (v_cost_1' * v_cost_1) / N;
    W_est_1 = inv(S_est_1);
    % second step
    g_L2_cost_c = @(para) mean(g_cost_v(para), 1) * W_est_1 * mean(g_cost_v(para), 1)';
    para_est_2 = fminunc(g_L2_cost_c, para_est_1, fminunc_options);
    v_cost_2 = g_cost_v(para_est_2);
    S_est_2 = (v_cost_2' * v_cost_2) / N;
    W_est_2 = inv(S_est_2);
    % large sample properties
    d_g_cost_v_mean = mean(d_g_cost_v(para_est_2), 1);
    G = zeros(L, K);
    for k = 1:K
        G(:, k) = d_g_cost_v_mean(k:K:(K * L));
    end
%     S_zx = (Z' * X) / N;
%     S_zy = (Z' * y) / N;
%     avar = inv(S_zx' * W_est_2 * S_zx) * S_zx' * W_est_2 * S_est_2 * W_est_2 * S_zx * inv(S_zx' * W_est_2 * S_zx);
    avar = inv(G' * W_est_2 * G) * G' * W_est_2 * S_est_2 * W_est_2 * G * inv(G' * W_est_2 * G);
end