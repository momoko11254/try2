function [ Y ] = Polylogy( X, Y, varargin)
% POLYLOGY calculates a straight line fit on a double-log (y-axis) scale
%
% Y = Polylogy( X , Y) fits straight line (on double-log y scale) to X
% Y = Polylogy( X , Y, Xout) fits straight line (on double-log y scale) to X and outputs Y values corresponding to Xout
%
% Author: Domanic Lavery 2010/15

[Y] = polyfit(X,(log10(Y)),1);

if nargin>2
    X=varargin{1};
end

Y = real((10.^(Y(2))).*(10.^(Y(1)*X)));
end