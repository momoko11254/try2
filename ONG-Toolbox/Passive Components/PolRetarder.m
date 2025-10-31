function [Signal, varargout]=PolRetarder(Signal, P)
% Applies an arbitrary retarderdation and induces a relative phase shift
% between the two polarisations.
%
% [Signal, varargout]=PolRetarder(Signal, P)
%
% Inputs:
% Signal            - input signal structure
% P.retardation     - phase retardation [rads]
% 
% Returns:
% Signal    - output signal structure
%
% Author: Benn Thomsen, September 2004.

Phase=[exp(-1i*P.retardation/2) 0; 0 exp(1i*P.retardation/2)];

if size(Signal.Et,1)==1,
    Signal.Et=[Signal.Et; zeros(size(Signal.Et))];
end

Signal.Et=Phase*Signal.Et;

P.Phase = Phase;
varargout{1} = P;
end