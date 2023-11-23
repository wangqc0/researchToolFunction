function array_replaced = replace_exact_group(array, old, new)
%REPLACE_GROUP Replace the old strings with the new strings by group,
%imposing exact matches
%   array: the cell array with strings to be replaced
%   old: a cell array of strings or cell arrays to be replaced
%   new: a cell array of strings or cell arrays to replace
    arguments
        array string
        old cell
        new cell
    end
    if numel(old) ~= numel(new)
        error('Length of the old array must match length of the new array')
    end
    for i = 1:numel(old)
        old_i = ifelse(isa(old{i}, 'char'), old(i), old{i});
        new_i = ifelse(isa(new{i}, 'char'), new(i), new{i});
        if (numel(old_i) ~= numel(new_i)) && numel(new_i) > 1
            error(['Pair ', num2str(i), ': For each old-new pair, ', ...
                'length of the new array must be ', ...
                'one or matching the length of the old array'])
        end
        if numel(new_i) > 1
            for j = 1:numel(old_i)
                array(strcmp(array, old_i{j})) = replace(array(strcmp(array, old_i{j})), old_i{j}, new_i{j});
            end
        else
            for j = 1:numel(old_i)
                array(strcmp(array, old_i{j})) = replace(array(strcmp(array, old_i{j})), old_i{j}, new_i{1});
            end
        end
    end
    array_replaced = array;
end