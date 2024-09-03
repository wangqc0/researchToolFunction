function [beta, aic, beta_draw] = local_projection(y, x, yy, W, fe_dummy, ind_diff_logical, subsample, h, m_min, m_max, q_min, q_max, r_min, r_max, n_draw, method_draw)
    % yy: additional variables to add beyond y
    n_x = size(x, 2);
    if n_x == 1
        x_m = [lagmatrix(x(:, 1), m_min), lagmatrix(x(:, 1), (m_min + 1):m_max)];
    else
        m_1_min = m_min(1, 1);
        m_2_min = m_min(2, 1);
        m_1_max = m_max(1, 1);
        m_2_max = m_max(2, 1);
        x_m = [lagmatrix(x(:, 1), m_1_min), lagmatrix(x(:, 2), m_2_min), lagmatrix(x(:, 1), (m_1_min + 1):m_1_max), lagmatrix(x(:, 2), (m_2_min + 1):m_2_max)];
    end
    if ind_diff_logical
        y_h = lagmatrix(y, -h) - lagmatrix(y, 1); %dy_h_m1
        dy = [nan; diff(y)]; %dy
        dyy = [nan(1, size(yy, 2)); diff(yy)]; %dyy
        yy_m = lagmatrix([dy dyy], q_min:q_max); %dyy_m
    else
        y_h = lagmatrix(y, -h);
        yy_m = lagmatrix([y yy], q_min:q_max);
    end
    % ensure y_h, x_m, yy_m, (W_m) all have no nan values
    isnan_y_h = any(isnan(y_h), 2);
    isnan_x_m = any(isnan(x_m), 2);
    isnan_yy_m = any(isnan(yy_m), 2);
    if isempty(W)
        isnan_any = any([isnan_y_h, isnan_x_m, isnan_yy_m], 2);
        W_m = [];
    else
        W_m = lagmatrix(W, r_min:r_max);
        isnan_W_m = any(isnan(W_m), 2);
        isnan_any = any([isnan_y_h, isnan_x_m, isnan_yy_m, isnan_W_m], 2);
        W_m = W_m(~isnan_any, :);
    end
    y_h = y_h(~isnan_any, :);
    x_m = x_m(~isnan_any, :);
    yy_m = yy_m(~isnan_any, :);
    T = size(y_h, 1);
    Y = y_h;
    if isempty(fe_dummy)
        X = [x_m, yy_m, W_m, ones(size(x_m, 1), 1)];
    else
        fe_dummy = fe_dummy(~isnan_any, :);
        X = [x_m, yy_m, W_m, ones(size(x_m, 1), 1), fe_dummy];
    end
    if ~isempty(subsample)
        subsample = subsample(~isnan_any, :);
        Y = Y(subsample, :);
        X = X(subsample, :);
        T = size(Y, 1);
    end
    beta = (X' * X) \ X' * Y;
    u = Y - X * beta;
    % calculate AIC
    aic = log(2 * pi) + log(mean(u .^ 2)) + 2 * size(beta, 1) / T;
    if n_draw > 0
        nvar_X = size(X, 2);
        if (method_draw == "mc" || method_draw == "nw")
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
            if method_draw == "mc"
                beta_draw = mvnrnd(beta, Sigma_beta, n_draw);
            elseif method_draw == "nw"
                beta_draw.se = sqrt(diag(Sigma_beta))';
                beta_draw.df = T - nvar_X;
            else
                beta_draw = [];
            end
        elseif method_draw == "bs"
            bs_index = ceil(rand(T, n_draw) * T);
            bs_index(bs_index == 0) = 1;
            Y_bs = Y(bs_index);
            X_reshaped = permute(X, [1, 3, 2]);
            X_bs = reshape(X_reshaped(bs_index, :), T, n_draw, nvar_X);
            Y_bs = permute(Y_bs, [1, 3, 2]);
            X_bs = permute(X_bs, [1, 3, 2]);
            beta_draw = pagemtimes(pagemldivide(pagemtimes(X_bs, "transpose", X_bs, "none"), pagetranspose(X_bs)), Y_bs);
            beta_draw = permute(beta_draw, [3, 1, 2]);
        else
            beta_draw = repmat(beta', n_draw, 1);
        end
    else
        beta_draw = [];
    end
end