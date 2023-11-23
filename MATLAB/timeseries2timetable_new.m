function tt = timeseries2timetable_new(ts, varname)
%TIMESERIES2TIMETABLE_NEW Convert a timeseries with datetime information to a timetable
%   ts: input timeseries
%   varname: name of the variable in the output timetable
%   tt: output timetable
    Time = datetime(datenum(ts.TimeInfo.StartDate) + ts.Time, 'ConvertFrom', 'datenum');
    eval([varname '= ts.Data;'])
    eval(['tt = timetable(Time, ' varname ');'])
end
