function ts_output = cnyAdj(ts)
%CNYADJ Adjust China's monthly economic data regarding the Chinese New Year
%effect by adjusting data in January and February
%   ts: input time table
%   ts_output: adjusted time table
    for i = 1:numel(ts)
        if month(ts.Time(i)) == 1
            ts_date_i = ts.Time(i);
            ts_date_i_previous = dateshift(ts_date_i, 'start', 'month', 'previous');
            ts_date_i_next = dateshift(ts_date_i, 'start', 'month', 'next');
            if any(ts.Time(:) == ts_date_i_previous) && any(ts.Time(:) == ts_date_i_next)
                ts_i = ts{ts_date_i, :};
                ts_i_previous = ts{ts_date_i_previous, :};
                ts_i_next = ts{ts_date_i_next, :};
                delta = ts_i_previous * (ts_i_previous + 4 * (ts_i + ts_i_next));
                if delta >= 0
                    spread = (sqrt(delta) - (2 * ts_i + ts_i_previous)) / 2;
                else
                    spread = (ts_i_previous + ts_i_next - 2 * ts_i) / 3;
                end
                ts_i = ts_i + spread;
                ts_i_next = ts_i_next - spread;
                ts{ts_date_i, :} = ts_i;
                ts{ts_date_i_next, :} = ts_i_next;
            end
        end
    end
    ts_output = ts;
end