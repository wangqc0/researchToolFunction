function [beta_0_response, beta_0_response_lower, beta_0_response_upper, m_1_aic, m_2_aic, q_aic, lp_aic] = ...
    lp_irf_jorda_mc_2_shock(Y, x, ind_diff, h_max, irf_band_confidence, min_delay, m_1_max, m_2_max, q_max, n_mc)
    arguments
        Y (:, :) double % responses
        x (:, 2) double % shock
        ind_diff (:, 1) {mustBeInteger} = []
        h_max (1, 1) {mustBeInteger} = 5
        irf_band_confidence (1, 1) {mustBeInRange(irf_band_confidence, 60, 100, 'exclude-upper')} = 90
        min_delay (1, 1) {mustBeInteger} = 0
        m_1_max (1, 1) {mustBeInteger} = 4
        m_2_max (1, 1) {mustBeInteger} = 4
        q_max (1, 1) {mustBeInteger} = 4
        n_mc (1, 1) {mustBeInteger} = 1000
    end
    if size(Y, 1) ~= size(x, 1)
        error('The row size of response and shock must be equal')
    end
    m_1_min = 0;
    m_2_min = 0;
    if min_delay == 0
        q_min = 1;
    elseif min_delay == 1
        q_min = 0;
    else
        error('minimum delay assumption indicator must be 0 (no) or 1 (yes)')
    end
    n_response = size(Y, 2);
    beta_0_response = nan(h_max + 1, 2, n_response);
    beta_0_response_lower = nan(h_max + 1, 2, n_response);
    beta_0_response_upper = nan(h_max + 1, 2, n_response);
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
                    [~, lp_aic_p_q] = localProjDiffTwoShock(y, x, yy, 0, m_1_min, m_1, m_2_min, m_2, q_min, q, 0);
                    lp_aic(m_1 - m_1_min + 1, m_2 - m_2_min + 1, q - q_min + 1) = lp_aic_p_q;
                end
            end
        end
        [index_aic_m_1, index_aic_m_2_and_q] = find(lp_aic == min(min(min(lp_aic))));
        index_aic_q = ceil(index_aic_m_2_and_q / (m_2_max - m_2_min + 1));
        index_aic_m_2 = index_aic_m_2_and_q - (index_aic_q - 1) * (m_2_max - m_2_min + 1);
        m_1_aic = index_aic_m_1 + m_1_min - 1;
        m_2_aic = index_aic_m_2 + m_2_min - 1;
        q_aic = index_aic_q + q_min - 1;
        for h = min_delay:(h_max + min_delay)
            if any(i_response == ind_diff)
                [beta, ~, beta_draw] = localProjDiffTwoShock(y, x, yy, h, m_1_min, m_1_aic, m_2_min, m_2_aic, q_min, q_aic, n_mc);
            else
                [beta, ~, beta_draw] = localProjTwoShock(y, x, yy, h, m_1_min, m_1_aic, m_2_min, m_2_aic, q_min, q_aic, n_mc);
            end
            beta_0_1 = beta(2);
            beta_0_1_draw = beta_draw(:, 2);
            beta_0_1_lower = prctile(beta_0_1_draw, (100 - irf_band_confidence) / 2);
            beta_0_1_upper = prctile(beta_0_1_draw, 100 - (100 - irf_band_confidence) / 2);
            beta_0_2 = beta(3);
            beta_0_2_draw = beta_draw(:, 3);
            beta_0_2_lower = prctile(beta_0_2_draw, (100 - irf_band_confidence) / 2);
            beta_0_2_upper = prctile(beta_0_2_draw, 100 - (100 - irf_band_confidence) / 2);
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