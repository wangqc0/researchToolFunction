function [beta_0_response, beta_0_response_lower, beta_0_response_upper, m_aic, q_aic, lp_aic] = ...
    lp_irf_jorda_bs(Y, x, ind_diff, h_max, irf_band_confidence, min_delay, m_max, q_max, n_bs)
    arguments
        Y (:, :) double % responses
        x (:, 1) double % shock
        ind_diff (:, 1) {mustBeInteger} = []
        h_max (1, 1) {mustBeInteger} = 5
        irf_band_confidence (1, 1) {mustBeInRange(irf_band_confidence, 60, 100, 'exclude-upper')} = 90
        min_delay (1, 1) {mustBeInteger} = 0
        m_max (1, 1) {mustBeInteger} = 4
        q_max (1, 1) {mustBeInteger} = 4
        n_bs (1, 1) {mustBeInteger} = 1000
    end
    if size(Y, 1) ~= size(x, 1)
        error("The row size of response and shock must be equal")
    end
    m_min = 0;
    if min_delay == 0
        q_min = 1;
    elseif min_delay == 1
        q_min = 0;
    else
        error("minimum delay assumption indicator must be 0 (no) or 1 (yes)")
    end
    n_response = size(Y, 2);
    beta_0_response = nan(h_max + 1, n_response);
    beta_0_response_lower = nan(h_max + 1, n_response);
    beta_0_response_upper = nan(h_max + 1, n_response);
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
                [~, lp_aic_p_q] = localProjDiff(y, x, yy, 0, m_min, m, q_min, q, 0);
                lp_aic(m - m_min + 1, q - q_min + 1) = lp_aic_p_q;
            end
        end
        [index_aic_m, index_aic_q] = find(lp_aic == min(min(lp_aic)));
        m_aic = index_aic_m + m_min - 1;
        q_aic = index_aic_q + q_min - 1;
        for h = min_delay:(h_max + min_delay)
            if any(i_response == ind_diff)
                [beta, ~, beta_draw] = localProjDiff_bs(y, x, yy, h, m_min, m_aic, q_min, q_aic, n_bs);
            else
                [beta, ~, beta_draw] = localProj_bs(y, x, yy, h, m_min, m_aic, q_min, q_aic, n_bs);
            end
            beta_0 = beta(2);
            beta_0_draw = beta_draw(:, 2);
            beta_0_lower = prctile(beta_0_draw, (100 - irf_band_confidence) / 2);
            beta_0_upper = prctile(beta_0_draw, 100 - (100 - irf_band_confidence) / 2);
            % adjust the band by the point estimate
            beta_0_bandwidth = (beta_0_upper - beta_0_lower) / 2;
            beta_0_lower = beta_0 - beta_0_bandwidth;
            beta_0_upper = beta_0 + beta_0_bandwidth;
            beta_0_i(h + 1 - min_delay, 1) = beta_0;
            beta_0_lower_i(h + 1 - min_delay, 1) = beta_0_lower;
            beta_0_upper_i(h + 1 - min_delay, 1) = beta_0_upper;
        end
        beta_0_response(:, i_response) = beta_0_i;
        beta_0_response_lower(:, i_response) = beta_0_lower_i;
        beta_0_response_upper(:, i_response) = beta_0_upper_i;
    end
end