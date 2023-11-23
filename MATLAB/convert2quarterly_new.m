function tt_output = convert2quarterly_new(tt, aggmethods)
%CONVERT2QUARTERLY_NEW run convert2quarterly and shift date to the start of
% a month
%   tt: input timetable
%   aggmethods: aggregation methods
%   tt_output: output timetable
    tt_output = convert2quarterly(tt, 'Aggregation', aggmethods);
    tt_output.Time = dateshift(tt_output.Time, 'start', 'month');
end