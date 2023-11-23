function output = ifelse(condition, method_1, method_0)
%IFELSE Output differently based on a condition
%   condition: a condition that is either true or false
%   method_1: output if the condition is true
%   method_0: output if the condition is false
%   output: the output
    arguments
        condition (1, 1) logical
        method_1
        method_0
    end
    if condition
        output = method_1;
    else
        output = method_0;
    end
end