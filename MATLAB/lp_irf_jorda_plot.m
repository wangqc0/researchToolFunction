function [] = lp_irf_jorda_plot(beta_0_response, beta_0_response_lower, beta_0_response_upper, M, Q, min_delay, irf_response, irf_shock)
    arguments
        beta_0_response (:, :) double
        beta_0_response_lower (:, :) double
        beta_0_response_upper (:, :) double
        M (1, 1) {mustBeInteger}
        Q (1, 1) {mustBeInteger}
        min_delay (1, 1) {mustBeInteger} = 0
        irf_response (1, :) cell = {}
        irf_shock (1, :) {mustBeText} = ''
    end
    h_max = size(beta_0_response, 1) - 1;
    n_plot_irf = size(beta_0_response, 2);
    if (numel(irf_response) ~= n_plot_irf) && ~isempty(irf_response)
        irf_response = strcat({'Variable '}, num2str((1:n_plot_irf)'))';
    end
    n_plot_col = floor(sqrt(n_plot_irf));
    n_plot_row = ceil(n_plot_irf / n_plot_col);
    for i_plot_irf = 1:n_plot_irf
        subplot(n_plot_row, n_plot_col, i_plot_irf)
        plot(min_delay:h_max, beta_0_response(1:(end - min_delay), i_plot_irf), 'k-')
        hold on
        plot(min_delay:h_max, [beta_0_response_lower(1:(end - min_delay), i_plot_irf) beta_0_response_upper(1:(end - min_delay), i_plot_irf)], 'k--')
        title(irf_response{i_plot_irf})
    end
    if min_delay == 0
        sgtitle({['IRF of Local Projection on ', irf_shock], ['M = ', num2str(M), ', Q = ', num2str(Q)]})
    else
        sgtitle({['IRF of Local Projection (with minimum delay assumption) on ', irf_shock], ['M = ', num2str(M), ', Q = ', num2str(Q)]})
    end
    
end