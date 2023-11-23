function output = save_list(filename, lists)
%SAVE_LIST Save a list of files in the workspace
%   filename: target location to save the file
%   lists: a cell array containing objects to save
    evalin('base', strcat('save(''', filename, ''', ''', strjoin(lists, ''', '''), ''');'))
end