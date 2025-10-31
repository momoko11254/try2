function varargout=interleave(direction, varargin)
% function varargout=interleave(direction, varargin)
%
% Direction: +1 to interleave, -1 to deinterleave
% Input as many vectors as you like
%
% Author: Domanic Lavery, 2014

varargout = cell(nargout);

if direction==1
    for index = 1:(nargin-1)
        varargout{index} = reshape([real(varargin{index});imag(varargin{index})],1,2*length(varargin{index}));
    end
else
    for index = 1:(nargin-1)
        temp = reshape([varargin{index}],2,length(varargin{index})/2);
        varargout{index} = temp(1,:)+1i*temp(2,:);
    end
end