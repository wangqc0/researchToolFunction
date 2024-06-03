function [beta_0_response, beta_0_response_lower, beta_0_response_upper, m_aic_all, q_aic_all, lp_aic_all] = ...
    lp_irf_jorda(Y, x, W, fe, subsample, ind_diff, h_max, irf_band_confidence, min_delay, m_max, q_max, r_max, n_draw, method_draw)
    arguments
        Y (:, :) double % responses
        x (:, :) double % shocks
        W (:, :) double = [] % controls
        fe (:, :) double = [] % fixed effects
        subsample (:, 1) logical = [] % subsampling indicator
        ind_diff (:, 1) {mustBeInteger} = []
        h_max (1, 1) {mustBeInteger} = 5
        irf_band_confidence (1, 1) {mustBeInRange(irf_band_confidence, 60, 100, "exclude-upper")} = 90
        min_delay (1, 1) {mustBeInteger} = 0
        m_max (:, 1) {mustBeInteger} = 4 * ones(size(x, 2), 1)
        q_max (1, 1) {mustBeInteger} = 4
        r_max (1, 1) {mustBeInteger} = 1
        n_draw (1, 1) {mustBeInteger} = 1000
        method_draw (1, 1) {mustBeMember(method_draw, {'mc', 'bs'})} = "mc"
    end
    if size(Y, 1) ~= size(x, 1)
        error("The row size of response and shock must be equal")
    end
    if size(x, 2) < 1 || size(x, 2) > 2
        error("The number of shocks must be one or two")
    end
    if ~isempty(W) && size(Y, 1) ~= size(W, 1)
        error("The row size of controls must be equal to response and shock")
    end
    if ~isempty(fe) && size(Y, 1) ~= size(fe, 1)
        error("The row size of fixed effects must be equal to response and shock")
    end
    if ~isempty(subsample) && size(Y, 1) ~= size(subsample, 1)
        error("The row size of subsampling indicator must be equal to response and shock")
    end
    if size(m_max, 1) ~= size(x, 2)
        error("The number of specified M lags must equals to the number of shocks")
    end
    n_shock = size(x, 2);
    m_min = zeros(n_shock, 1);
    if min_delay == 0
        q_min = 1;
    elseif min_delay == 1
        q_min = 0;
    else
        error("minimum delay assumption indicator must be 0 (no) or 1 (yes)")
    end
    r_min = 1;
    n_fe_indicator = size(fe, 2);
    fe_dummy = [];
    if n_fe_indicator > 0
        for i_fe_indicator = 1:n_fe_indicator
            fe_dummy_i_fe_indicator = dummyvar(categorical(fe(:, i_fe_indicator)));
            fe_dummy = horzcat(fe_dummy, fe_dummy_i_fe_indicator(:, 2:end));
        end
    end
    n_response = size(Y, 2);
    % one-shock case
    if n_shock == 1
        beta_0_response = nan(h_max + 1, n_response);
        beta_0_response_lower = nan(h_max + 1, n_response);
        beta_0_response_upper = nan(h_max + 1, n_response);
        m_aic_all = nan(n_response, 1);
        q_aic_all = nan(n_response, 1);
        lp_aic_all = nan(m_max - m_min + 1, q_max - q_min + 1, n_response);
        for i_response = 1:n_response
            y = Y(:, i_response);
            yy = Y;
            yy(:, i_response) = [];
            beta_0_i = nan(h_max + 1, 1);
            beta_0_upper_i = nan(h_max + 1, 1);
            beta_0_lower_i = nan(h_max + 1, 1);
            % choose m_aic (for x) and q_aic (for Y) based on AIC at h = 0
            lp_aic = nan(m_max - m_min + 1, q_max - q_min + 1);
            for m = m_min:m_max
                for q = q_min:q_max
                    [~, lp_aic_p_q] = local_projection(y, x, yy, W, fe_dummy, true, subsample, 0, m_min, m, q_min, q, r_min, r_max, 0, method_draw);
                    lp_aic(m - m_min + 1, q - q_min + 1) = lp_aic_p_q;
                end
            end
            [index_aic_m, index_aic_q] = find(lp_aic == min(min(lp_aic)));
            m_aic = index_aic_m + m_min - 1;
            q_aic = index_aic_q + q_min - 1;
            m_aic_all(i_response) = m_aic;
            q_aic_all(i_response) = q_aic;
            lp_aic_all(:, :, i_response) = lp_aic;
            for h = min_delay:(h_max + min_delay)
                [beta, ~, beta_draw] = local_projection(y, x, yy, W, fe_dummy, any(i_response == ind_diff), subsample, h, m_min, m_aic, q_min, q_aic, r_min, r_max, n_draw, method_draw);
                beta_0 = beta(1);
                beta_0_draw = beta_draw(:, 1);
                beta_0_lower = prctile(beta_0_draw, (100 - irf_band_confidence) / 2);
                beta_0_upper = prctile(beta_0_draw, 100 - (100 - irf_band_confidence) / 2);
                % adjust the band by the point estimate
                if method_draw == "bs"
                    beta_0_bandwidth = (beta_0_upper - beta_0_lower) / 2;
                    beta_0_lower = beta_0 - beta_0_bandwidth;
                    beta_0_upper = beta_0 + beta_0_bandwidth;
                end
                beta_0_i(h + 1 - min_delay, 1) = beta_0;
                beta_0_lower_i(h + 1 - min_delay, 1) = beta_0_lower;
                beta_0_upper_i(h + 1 - min_delay, 1) = beta_0_upper;
            end
            beta_0_response(:, i_response) = beta_0_i;
            beta_0_response_lower(:, i_response) = beta_0_lower_i;
            beta_0_response_upper(:, i_response) = beta_0_upper_i;
        end
    % two-shock case
    else
        beta_0_response = nan(h_max + 1, 2, n_response);
        beta_0_response_lower = nan(h_max + 1, 2, n_response);
        beta_0_response_upper = nan(h_max + 1, 2, n_response);
        m_1_min = m_min(1, 1);
        m_2_min = m_min(2, 1);
        m_1_max = m_max(1, 1);
        m_2_max = m_max(2, 1);
        m_aic_all = nan(2, n_response);
        q_aic_all = nan(n_response, 1);
        lp_aic_all = nan(m_1_max - m_1_min + 1, m_2_max - m_2_min + 1, q_max - q_min + 1, n_response);
        for i_response = 1:n_response
            y = Y(:, i_response);
            yy = Y;
            yy(:, i_response) = [];
            beta_0_i = nan(h_max + 1, 2);
            beta_0_upper_i = nan(h_max + 1, 2);
            beta_0_lower_i = nan(h_max + 1, 2);
            % choose m_1_aic (for x_1), m_2_aic (for x_2) and q_aic (for Y) based on AIC at h = 0
            lp_aic = nan(m_1_max - m_1_min + 1, m_2_max - m_2_min + 1, q_max - q_min + 1);
            for m_1 = m_1_min:m_1_max
                for m_2 = m_2_min:m_2_max
                    for q = q_min:q_max
                        [~, lp_aic_p_q] = local_projection(y, x, yy, W, fe_dummy, true, subsample, 0, [m_1_min; m_2_min], [m_1; m_2], q_min, q, r_min, r_max, 0, method_draw);
                        lp_aic(m_1 - m_1_min + 1, m_2 - m_2_min + 1, q - q_min + 1) = lp_aic_p_q;
                    end
                end
            end
            [index_aic_m_1, index_aic_m_2_and_q] = find(lp_aic == min(min(min(lp_aic))));
            index_aic_q = ceil(index_aic_m_2_and_q / (m_2_max - m_2_min + 1));
            index_aic_m_2 = index_aic_m_2_and_q - (index_aic_q - 1) * (m_2_max - m_2_min + 1);
            m_1_aic = index_aic_m_1 + m_1_min - 1;
            m_2_aic = index_aic_m_2 + m_2_min - 1;
            m_aic = [m_1_aic; m_2_aic];
            q_aic = index_aic_q + q_min - 1;
            m_aic_all(:, i_response) = m_aic;
            q_aic_all(i_response) = q_aic;
            lp_aic_all(:, :, :, i_response) = lp_aic;
            for h = min_delay:(h_max + min_delay)
                [beta, ~, beta_draw] = local_projection(y, x, yy, W, fe_dummy, any(i_response == ind_diff), subsample, h, [m_1_min; m_2_min], [m_1_aic; m_2_aic], q_min, q_aic, r_min, r_max, n_draw, method_draw);
                beta_0_1 = beta(1);
                beta_0_1_draw = beta_draw(:, 1);
                beta_0_1_lower = prctile(beta_0_1_draw, (100 - irf_band_confidence) / 2);
                beta_0_1_upper = prctile(beta_0_1_draw, 100 - (100 - irf_band_confidence) / 2);
                beta_0_2 = beta(2);
                beta_0_2_draw = beta_draw(:, 2);
                beta_0_2_lower = prctile(beta_0_2_draw, (100 - irf_band_confidence) / 2);
                beta_0_2_upper = prctile(beta_0_2_draw, 100 - (100 - irf_band_confidence) / 2);
                % adjust the band by the point estimate
                if method_draw == "bs"
                    beta_0_1_bandwidth = (beta_0_1_upper - beta_0_1_lower) / 2;
                    beta_0_1_lower = beta_0_1 - beta_0_1_bandwidth;
                    beta_0_1_upper = beta_0_1 + beta_0_1_bandwidth;
                    beta_0_2_bandwidth = (beta_0_2_upper - beta_0_2_lower) / 2;
                    beta_0_2_lower = beta_0_2 - beta_0_2_bandwidth;
                    beta_0_2_upper = beta_0_2 + beta_0_2_bandwidth;
                end
                beta_0_i(h + 1 - min_delay, 1) = beta_0_1;
                beta_0_lower_i(h + 1 - min_delay, 1) = beta_0_1_lower;
                beta_0_upper_i(h + 1 - min_delay, 1) = beta_0_1_upper;
                beta_0_i(h + 1 - min_delay, 2) = beta_0_2;
                beta_0_lower_i(h + 1 - min_delay, 2) = beta_0_2_lower;
                beta_0_upper_i(h + 1 - min_delay, 2) = beta_0_2_upper;
            end
            beta_0_response(:, :, i_response) = beta_0_i;
            beta_0_response_lower(:, :, i_response) = beta_0_lower_i;
            beta_0_response_upper(:, :, i_response) = beta_0_upper_i;
        end
    end
end