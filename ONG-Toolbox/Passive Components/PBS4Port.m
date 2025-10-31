function PBS4P = PBS4Port(varargin)
% Returns the transfer matrix for a four port polarising beam splitter
%
% PBS4P = PBS4Port(varargin)
% Etout=PBS4Port(coupling)*[Ex1; Ey1; Ex2; Ey2]
%
% varargin      - extinction ratio (dB). Omit parameter for ideal device
%
% Author: Benn Thomsen, September 2004.

if nargin == 1,
    ER=10^(-varargin{1}/10);
else
    ER=0;
end


PBS4P=[sqrt(1-ER) 0 -1j*sqrt(ER) 0;...
        0 sqrt(ER) 0 -1j*sqrt(1-ER);...
        -1j*sqrt(ER) 0 sqrt(1-ER) 0;...
        0 -1j*sqrt(1-ER) 0 sqrt(ER)];
end