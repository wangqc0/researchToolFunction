function forms = form_wilkinson(y, X, spec)
%FORM_WILKINSON Create formula (strings) in Wilkinson form for linear
%regression equations
%   y: dependent variable
%   X: independent variables
%   spec: specify which independent variables are included in each
%   regression specification (one specification for each row)
    arguments
        y (1, 1) string
        X (1, :) string
        spec double = ones(1, numel(X))
    end
    % check that the numbers of columns in "spec" and in "X" are equal
    if size(spec, 2) ~= numel(X)
        error(['The number of columns in specification must equal to ...' ...
            'the number of independent variables.'])
    end
    % check that all elements in "spec" are zero or one
    if ~(isequal(unique(spec), [0; 1]) || isequal(unique(spec), 1))
        error('Wrong input of specification: Only 0 and 1 are allowed.')
    end
    % check that no row in "spec" is all-zero
    if ~isempty(find(all(spec == 0, 2), 1))
        error('No row in the specification matrix can be all-zero.')
    end
    for i = 1:size(spec, 1)
        forms{i} = strjoin([y, strjoin(X(logical(spec(i, :))), ' + ')], ' ~ ');
    end
    forms = cellfun(@(x) x{1}, forms, 'UniformOutput', false);
end