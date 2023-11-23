function [R, P, RL, RU] = corrcoef_table(tab, options)
%CORRCOEF_TABLE Return the correlation coefficient table of a table with
%variable names
%   tab: table
%   options: name-value arguments inherited in the "corrcoef" function
    arguments
        tab
        options.Alpha (1, 1) double = 0.05
        options.Rows (1, 1) string = 'all'
    end
    varnames = tab.Properties.VariableNames;
    [R, P, RL, RU] = corrcoef(tab.Variables, 'Alpha', options.Alpha, 'Rows', options.Rows);
    R = array2table(R);
    R.Properties.RowNames = varnames;
    R.Properties.VariableNames = varnames';
    P = array2table(P);
    P.Properties.RowNames = varnames;
    P.Properties.VariableNames = varnames';
    RL = array2table(RL);
    RL.Properties.RowNames = varnames;
    RL.Properties.VariableNames = varnames';
    RU = array2table(RU);
    RU.Properties.RowNames = varnames;
    RU.Properties.VariableNames = varnames';
end