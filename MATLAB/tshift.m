function ts_output = tshift(ts_input, dt)
%TSHIFT Shift to lagged or lead time series
%   ts_input: input time series
%   dt: shifting periods (positive for lead, negative for lag)
%   ts_output: output time series
    if rem(dt, 1) ~= 0
        error('Incorrect shifting period.')
    elseif dt == 0
        ts_output = ts_input;
    elseif dt > 0
        ts_output = [tshift(ts_input(2:end), dt - 1); nan];
    else
        ts_output = [nan; tshift(ts_input(1:(numel(ts_input) - 1)), dt + 1)];
    end
end