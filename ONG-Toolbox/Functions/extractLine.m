function [X,Y] = extractLine(varargin)
% EXTRACTLINE Extract all line data from an axis
%   [X,Y] = EXTRACTLINE() All data from current axis
%   [X,Y] = EXTRACTLINE(h) All data from current axis
%
%   
%   Author: Domanic Lavery 2010
%
%   See also GCA, GET, FINDOBJ.

if nargin
    % use the handle of a specified axis
    axis_handle = varargin{1};
else
    % gca gets handle of current axis
    axis_handle = gca;
end

h = findobj(axis_handle, 'Type', 'line');

% Initialise cell array
X = cell(1,numel(h));
Y = cell(1,numel(h));

for index = 1:numel(h)
    
    % displays a list of all the 'tags', one of which
    % is XData and YData, which contain the plot data
%     get(h(index));
    
    X{index} = get(h(index), 'XData');
    Y{index} = get(h(index), 'YData');
    
end
