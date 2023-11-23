function [dy_dv_mc, dy_de_mc, P_mc] = var_irf_chol_mc(y, Pi, e, h_max, n_mc, options)
    % The function involves two random draws from multivariable normal
    % distributions. Set seed for replicability.
    arguments
        y (:, :) {mustBeNumeric}
        Pi (:, :) {mustBeNumeric}
        e (:, :) {mustBeNumeric}
        h_max (1, 1) {mustBeInteger}
        n_mc (1, 1) {mustBeInteger}
        options.drift logical = false
    end
    % derived parameters:
    var_e = cov(e');
    n = size(var_e, 1);
    if options.drift
        p = (size(Pi, 2) - 2) / n;
    else
        p = (size(Pi, 2) - 1) / n;
    end
    T = size(y, 2);
    % draw Pi
    vec_Pi = reshape(Pi, [], 1);
    %Y = y(:, (p + 1):T);
    if options.drift
        X = zeros(2 + n * p, T - p);
        X(1, :) = 1;
        X(2, :) = 0:(T - p - 1);
        for p_i = 1:p
            X((2 + ((n * (p_i - 1) + 1):(n * p_i))), :) = y(:, (p + 1 - p_i):(T - p_i));
        end
    else
        X = zeros(1 + n * p, T - p);
        X(1, :) = 1;
        for p_i = 1:p
            X((1 + ((n * (p_i - 1) + 1):(n * p_i))), :) = y(:, (p + 1 - p_i):(T - p_i));
        end
    end
    Q = nan(size(X, 1), size(X, 1), size(X, 2));
    for t = 1:size(X, 2)
        Q(:, :, t) = X(:, t) * X(:, t)';
    end
    Q = mean(Q, 3);
    var_Pi = (kron(eye(size(Q)) / Q, var_e)) / (T - p); 
    Pi_mc = mvnrnd(vec_Pi, var_Pi, n_mc);
    Pi_mc = reshape(Pi_mc', n, [], n_mc);
    % obtain Psi
    % FASTER
    F_mc = zeros(n * p, n * p, n_mc);
    if options.drift
        F_mc(1:n, :, :) = Pi_mc(:, 3:end, :);
    else
        F_mc(1:n, :, :) = Pi_mc(:, 2:end, :);
    end
    F_mc((n + 1):end, 1:(end - n), :) = repmat(eye(n * (p - 1), n * (p - 1)), 1, 1, n_mc);
    F_mc_h = nan(n * p, n * p, h_max, n_mc);
    for i_mc = 1:n_mc
        F_i = F_mc(:, :, i_mc);
        F_h_i = nan(n * p, n * p, h_max);
        F_h_i_h = eye(n * p);
        for h = 1:h_max
            F_h_i_h = F_h_i_h * F_i;
            F_h_i(:, :, h) = F_h_i_h;
        end
        F_mc_h(:, :, :, i_mc) = F_h_i;
    end
    Psi_mc = F_mc_h(1:n, 1:n, :, :);
    Psi_mc = cat(3, repmat(eye(n), 1, 1, 1, n_mc), Psi_mc);
%     F_mc = zeros(n * p, n * p, n_mc);
%     F_mc_h = nan(n * p, n * p, h_max, n_mc);
%     F_mc(1:n, :, :) = Pi_mc(:, 2:end, :);
%     for i_mc = 1:n_mc
%         F_mc((n + 1):end, 1:(end - n), i_mc) = eye(n * (p - 1), n * (p - 1));
%         F_mc_h(:, :, :, i_mc) = repmat(F_mc(:, :, i_mc), 1, 1, h_max);
%     end
%     Psi_mc = nan(n, n, h_max + 1, n_mc);
%     for i_mc = 1:n_mc
%         F_h_i = F_mc_h(:, :, :, i_mc);
%         Psi_i = nan(n, n, h_max);
%         for h = 1:h_max
%             F_h_i(:, :, h) = F_h_i(:, :, h) ^ h;
%             Psi_i(:, :, h) = F_h_i(1:n, 1:n, h);
%         end
%         % add t = 0
%         Psi_i = cat(3, eye(n), Psi_i);
%         F_mc_h(:, :, :, i_mc) = F_h_i;
%         Psi_mc(:, :, :, i_mc) = Psi_i;
%     end
    dy_de_mc = Psi_mc;
    % draw Omega
    vech_Omega = vech(var_e);
    D_n = dupmat(n);
    D_n_plus = (D_n' * D_n) \ D_n';
    var_Omega = (2 * D_n_plus * kron(var_e, var_e) * D_n_plus') / (T - p);
    Omega_mc = mvnrnd(vech_Omega, var_Omega, n_mc);
    Omega_mc = Omega_mc * D_n';
    Omega_mc = reshape(Omega_mc', n, n, n_mc);
    % check positive semidefinite and obtain P
    Omega_mc_psd = nan(n_mc, 1);
    P_mc = nan(n, n, n_mc);
    for i_mc_psd = 1:n_mc
        try
            [P_mc_i, chol_p_i] = chol(Omega_mc(:, :, i_mc_psd));
            P_mc(:, :, i_mc_psd) = P_mc_i';
        catch
            chol_p_i = 1;
        end
        Omega_mc_psd(i_mc_psd) = chol_p_i;
    end
    while sum(Omega_mc_psd) > 0
        n_mc_invalid = find(Omega_mc_psd > 0);
        Omega_mc(:, :, n_mc_invalid) = [];
        Omega_mc_psd(n_mc_invalid) = [];
        P_mc(:, :, n_mc_invalid) = [];
        Omega_mc_new = mvnrnd(vech_Omega, var_Omega, numel(n_mc_invalid));
        Omega_mc_new = Omega_mc_new * D_n';
        Omega_mc_new = reshape(Omega_mc_new', n, n, numel(n_mc_invalid));
        Omega_mc = cat(3, Omega_mc, Omega_mc_new);
        Omega_mc_psd_new = nan(numel(n_mc_invalid), 1);
        P_mc_new = nan(n, n, numel(n_mc_invalid));
        for i_mc_psd = 1:numel(n_mc_invalid)
            try
                [P_mc_i, chol_p_i] = chol(Omega_mc_new(:, :, i_mc_psd));
                P_mc_new(:, :, i_mc_psd) = P_mc_i';
            catch
                chol_p_i = 1;
            end
            Omega_mc_psd_new(i_mc_psd) = chol_p_i;
        end
        Omega_mc_psd = [Omega_mc_psd; Omega_mc_psd_new];
        P_mc = cat(3, P_mc, P_mc_new);
    end
    % muitiply Psi and P
    % FASTER
    Psi_s_mc = pagemtimes(Psi_mc, permute(reshape(repmat(P_mc, 1, 1, h_max + 1), n, n, n_mc, h_max + 1), [1 2 4 3]));
%     Psi_s_mc = nan(size(Psi_mc));
%     for i_mc = 1:n_mc
%         Psi_i = Psi_mc(:, :, :, i_mc);
%         P_i = P_mc(:, :, i_mc);
%         Psi_s_i = pagemtimes(Psi_i, P_i);
%         Psi_s_mc(:, :, :, i_mc) = Psi_s_i;
%     end
    dy_dv_mc = Psi_s_mc;
end