function [dy_dv_bs, dy_de_bs, A_bs] = var_irf_bq_bs(y, Pi, e, h_max, T_burnin, n_bs)
    % The function involves a random draw from a uniform distribution and a
    % datasample. Set seed for replicability.
    %syms theta
    % derived parameters:
    var_e = cov(e');
    P = chol(var_e)';
    n = size(var_e, 1);
    p = (size(Pi, 2) - 1) / n;
    T = size(y, 2);
    % reshuffle residual
    tau = round((p - .5) + rand(n_bs, 1) * ((T + .5) - (p - .5)));
    % SLIGHTLY FASTER:
    y_initial = cell2mat(arrayfun(@(tau_b) y(:, (tau_b - p + 1):tau_b), tau, 'UniformOutput', false));
    y_initial = pagetranspose(reshape(y_initial', p, n, n_bs));
    e_reshuffle = reshape(e(:, datasample(1:(T - p), (T + T_burnin) * n_bs)), n, T + T_burnin, n_bs);
%     y_initial = nan(n, p, n_bs);
%     e_reshuffle = nan(size(e, 1), size(e, 2) + T_burnin + p, n_bs);
%     for i_bs = 1:n_bs
%         y_initial(:, :, i_bs) = y(:, (tau(i_bs) - p + 1):tau(i_bs));
%         e_reshuffle(:, :, i_bs) = e(:, datasample(1:(T - p), T + T_burnin));
%     end
    % generate derived y series
    % FASTER:
    y_new = nan(n, T + T_burnin, n_bs);
    y_new(:, 1:p, :) = y_initial;
    for t = (p + 1):(T + T_burnin)
        x = nan(1 + n * p, 1, n_bs);
        x(1, 1, :) = 1;
        for p_i = 1:p
            x((1 + ((n * (p_i - 1) + 1):(n * p_i))), 1, :) = y_new(:, (t - p_i), :);
        end
        y_new(:, t, :) = pagemtimes(Pi, x) + e_reshuffle(:, t, :);
    end
%     y_new = nan(size(y, 1), size(y, 2) + T_burnin, n_bs);
%     for i_bs = 1:n_bs
%         y_new_i = y_new(:, :, i_bs);
%         y_new_i(:, 1:p) = y_initial(:, :, i_bs);
%         for t = (p + 1):(T + T_burnin)
%             x = zeros(1 + n * p, 1);
%             x(1) = 1;
%             for p_i = 1:p
%                 x((1 + ((n * (p_i - 1) + 1):(n * p_i)))) = y_new_i(:, (t - p_i));
%             end
%             y_new_i(:, t) = Pi * x + e_reshuffle(:, t, i_bs);
%         end
%         y_new(:, :, i_bs) = y_new_i;
%     end
    y_new = y_new(:, (T_burnin + 1):end, :);
    % obtain Pi and Omega
    Pi_bs = nan(size(Pi, 1), size(Pi, 2), n_bs);
    Omega_bs = nan(size(var_e, 1), size(var_e, 2), n_bs);    
    for i_bs = 1:n_bs
        [Pi_bs_i, e_i] = var_ols(y_new(:, :, i_bs), p);
        var_e_i = cov(e_i');
        Pi_bs(:, :, i_bs) = Pi_bs_i;
        Omega_bs(:, :, i_bs) = var_e_i;
    end
    % obtain Psi
    % SLIGHTLY FASTER
    F_bs = zeros(n * p, n * p, n_bs);
    F_bs(1:n, :, :) = Pi_bs(:, 2:end, :);
    F_bs((n + 1):end, 1:(end - n), :) = repmat(eye(n * (p - 1), n * (p - 1)), 1, 1, n_bs);
    %F_bs_h = reshape(repmat(F_bs, 1, 1, h_max), n * p, n * p, n_bs, h_max);
    %F_bs_h = permute(F_bs_h, [1 2 4 3]);
%     F_bs = zeros(n * p, n * p, n_bs);
%     F_bs_h = nan(n * p, n * p, h_max, n_bs);
%     F_bs(1:n, :, :) = Pi_bs(:, 2:end, :);
%     for i_bs = 1:n_bs
%         F_bs((n + 1):end, 1:(end - n), i_bs) = eye(n * (p - 1), n * (p - 1));
%         F_bs_h(:, :, :, i_bs) = repmat(F_bs(:, :, i_bs), 1, 1, h_max);
%     end
    % FASTER
    F_bs_h = nan(n * p, n * p, h_max, n_bs);
    for i_bs = 1:n_bs
        F_i = F_bs(:, :, i_bs);
        F_h_i = nan(n * p, n * p, h_max);
        F_h_i_h = eye(n * p);
        for h = 1:h_max
            F_h_i_h = F_h_i_h * F_i;
            F_h_i(:, :, h) = F_h_i_h;
        end
        F_bs_h(:, :, :, i_bs) = F_h_i;
    end
    Psi_bs = F_bs_h(1:n, 1:n, :, :);
    Psi_bs = cat(3, repmat(eye(n), 1, 1, 1, n_bs), Psi_bs);
%     Psi_bs = nan(n, n, h_max + 1, n_bs);
%     for i_bs = 1:n_bs
%         F_h_i = F_bs_h(:, :, :, i_bs);
%         Psi_i = nan(n, n, h_max);
%         for h = 1:h_max
%             F_h_i(:, :, h) = F_h_i(:, :, h) ^ h;
%             Psi_i(:, :, h) = F_h_i(1:n, 1:n, h);
%         end
%         % add t = 0
%         Psi_i = cat(3, eye(n), Psi_i);
%         F_bs_h(:, :, :, i_bs) = F_h_i;
%         Psi_bs(:, :, :, i_bs) = Psi_i;
%     end
    dy_de_bs = Psi_bs;
    % obtain A
    A_bs = nan(size(P, 1), size(P, 2), n_bs);
    for i_bs = 1:n_bs
        var_e_i = Omega_bs(:, :, i_bs);
        C_i = chol(var_e_i)';
        D_1_x_i = sum(Psi_bs(:, :, :, n_bs), 3) * C_i;
        theta_solve_i = atan(-D_1_x_i(1, 1) / D_1_x_i(1, 2));
%         D_1_i = sum(Psi_bs(:, :, :, n_bs), 3) * C_i * [cos(theta), -sin(theta); sin(theta), cos(theta)];
%         theta_solve_i = vpasolve(D_1_i(1, 1) == 0, theta);
        D_0_hat_i = C_i * [cos(theta_solve_i), -sin(theta_solve_i); sin(theta_solve_i), cos(theta_solve_i)];
        A_bs_i = double(D_0_hat_i);
        A_bs(:, :, i_bs) = A_bs_i;
    end
    % muitiply Psi and A
    % FASTER
    Psi_s_bs = pagemtimes(Psi_bs, permute(reshape(repmat(A_bs, 1, 1, h_max + 1), n, n, n_bs, h_max + 1), [1 2 4 3]));
%     Psi_s_bs = nan(size(Psi_bs));
%     for i_bs = 1:n_bs
%         Psi_i = Psi_bs(:, :, :, i_bs);
%         P_i = P_bs(:, :, i_bs);
%         Psi_s_i = pagemtimes(Psi_i, P_i);
%         Psi_s_bs(:, :, :, i_bs) = Psi_s_i;
%     end
    dy_dv_bs = Psi_s_bs;
end