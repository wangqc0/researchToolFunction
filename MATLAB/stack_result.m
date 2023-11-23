function output = stack_result(mdl)
%STACK_RESULT Generate the long format of the regression result table
%   mdl: the model to be interpreted
    class_supported = {'LinearModel'; 'struct'};
    if ~any(string(class_supported(:)) == class(mdl))
        error('Model''s class is not supported.')
    end
    if isa(mdl, 'LinearModel')
        result = mdl.Coefficients;
        result.Variable = convertCharsToStrings(result.Properties.RowNames);
        result.Properties.RowNames = {};
        output = stack(result, {'Estimate', 'SE', 'tStat', 'pValue'}, ...
            'NewDataVariableName', 'Value', 'IndexVariableName', 'Type');
        output.Type = string(output.Type);
        output = [output; {'Observation', 'Value', mdl.NumObservations}; ...
            {'AIC', 'Value', mdl.ModelCriterion.AIC; 'BIC', 'Value', mdl.ModelCriterion.BIC}; ...
            {'Rsquared', 'Value', mdl.Rsquared.Ordinary; 'RsquaredAdj', 'Value', mdl.Rsquared.Adjusted}];
        output.Model = string(repmat('lm', size(output, 1), 1));
    elseif isa(mdl, 'struct')
        result = mdl.Table;
        result.Variable = convertCharsToStrings(result.Properties.RowNames);
        result.Properties.RowNames = {};
        output = stack(result, {'Estimate', 'SE', 'tStat', 'pValue'}, ...
            'NewDataVariableName', 'Value', 'IndexVariableName', 'Type');
        output.Type = string(output.Type);
        output = [output; {'Observation', 'Value', mdl.SampleSize}; ...
            {'AIC', 'Value', mdl.AIC; 'BIC', 'Value', mdl.BIC}; ...
            {'Rsquared', 'Value', mdl.Rsquared.Ordinary; 'RsquaredAdj', 'Value', mdl.Rsquared.Adjusted}];
        if strcmp(mdl.Description, 'ARMA(1,0) Error Model (Gaussian Distribution)')
            output.Model = string(repmat('lmar1', size(output, 1), 1));
        elseif strcmp(mdl.Description, 'IV Model (Gaussian Distribution)')
            output.Model = string(repmat('lmiv', size(output, 1), 1));
        end
    end
    output.Label = string(repmat(inputname(1), size(output, 1), 1));
    output = movevars(output, 'Label', 'Before', 1);
    output = movevars(output, 'Model', 'Before', 1);
end