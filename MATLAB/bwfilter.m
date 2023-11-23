function s = bwfilter(y, bw)
%BWFILTER Biweight filter to obtain the local mean of a series as in Stock
%and Watson (2012), 'Disentangling the Channels of the 2007–09 Recession',
%Brookings Papers on Economic Activity
%   y: input series
%   bw: time window (on each side)
%   s: filtered series
    I = numel(y);
    for i = 1:I
        y(i) = mean(y(max(1, i - bw):min(I, i + bw)), 'omitnan');
    end
    s = y;
end