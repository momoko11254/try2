function [varargout] = GPUmem( varargin )
%GPUMEM displays the free/used memory of a GPU device in human readable
%format (default is current GPU).
%   [] = GPUmem( ) % Display memory of currently select GPU
%   [] = GPUmem(n) % Display memory of GPU #n (will also select this GPU)
%   [Used, {Free}] = GPUmem(n) % return the memory usage of GPU (display nothing)
% 
% Author: Domanic Lavery, 2014

if ~(nargin==0)
    A = gpuDevice(varargin{1});
else
    A = gpuDevice;
end

Used = A.TotalMemory-A.FreeMemory;
Free = A.FreeMemory;

switch nargout
    case 0
        disp(['Memory used is ' num2str(Used/(2^30)) ' GiB'])
        disp(['Memory free is ' num2str(Free/(2^30)) ' GiB'])
    case 1
        varargout{1} = Used;
    case 2
        varargout{1} = Used;
        varargout{2} = Free;
end
end