function [XDifference, varargout] = dinput(varargin)
% Allows the user to obtain the relative difference between a set of
% x-axis coordinates by clicking on these points on the current axis
% graph.
%
% [XDifference, varargout] = dinput(varargin)
%
% Operation:
% dinput() - defaults to the difference between two coordinates
% dinput(n) - difference between a vector of coordinates, length n,
%             and the smallest-valued coordinate.
%
% A second output will return the vector of y-axis differences
%
% Author: Domanic Lavery, December 2013

switch nargin
    case 0
        [x,y] = ginput(2);
        XDifference = abs(x(2)-x(1));
        varargout{1} = abs(y(2)-y(1));
    case 1
        [x,y] = ginput(varargin{1});
        XDifference = x-min(x);
        varargout{1} = y-min(y);
    otherwise
        error('dinput invalid argument {0,1}')
end
end