function [beta_0_response, beta_0_response_lower, beta_0_response_upper] = ...
    lp_irf_jorda_mc(Y, x, ind_diff, h_max, irf_band_confidence, min_delay, m_max, q_max, n_mc)
    arguments
        Y (:, :) double % responses
        x (:, 1) double % shock
        ind_diff (:, 1) {mustBeInteger} = []
        h_max (1, 1) {mustBeInteger} = 20
        irf_band_confidence (1, 1) {mustBeInRange(irf_band_confidence, 60, 100, 'exclude-upper')} = 90
        min_delay (1, 1) {mustBeInteger} = 0
        m_max (1, 1) {mustBeInteger} = 4
        q_max (1, 1) {mustBeInteger} = 4
        n_mc (1, 1) {mustBeInteger} = 1000
    end
    if size(Y, 1) ~= size(x, 1)
        error('The row size of response and shock must be equal')
    end
    m_min = 0;
    if min_delay == 0
        q_min = 1;
    elseif min_delay == 1
        q_min = 0;
    else
        error('minimum delay assumption indicator must be 0 (no) or 1 (yes)')
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
        for h = min_delay:(h_max + min_delay)
            if any(i_response == ind_diff)
                [beta, beta_draw] = localProjDiff(y, x, yy, h, m_min, m_max, q_min, q_max, n_mc);
            else
                [beta, beta_draw] = localProj(y, x, yy, h, m_min, m_max, q_min, q_max, n_mc);
            end
            beta_0 = beta(2);
            beta_0_draw = beta_draw(:, 2);
            beta_0_lower = prctile(beta_0_draw, (100 - irf_band_confidence) / 2);
            beta_0_upper = prctile(beta_0_draw, 100 - (100 - irf_band_confidence) / 2);
            beta_0_i(h + 1 - min_delay) = beta_0;
            beta_0_lower_i(h + 1 - min_delay) = beta_0_lower;
            beta_0_upper_i(h + 1 - min_delay) = beta_0_upper;
        end
        beta_0_response(:, i_response) = beta_0_i;
        beta_0_response_lower(:, i_response) = beta_0_lower_i;
        beta_0_response_upper(:, i_response) = beta_0_upper_i;
    end
end