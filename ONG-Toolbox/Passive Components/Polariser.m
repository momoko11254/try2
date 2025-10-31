function [Signal, varargout] = Polariser(Signal, P)
% Polarises signal based on a given rotation angle.
%
% [Signal, varargout] = Polariser(Signal, P)
%
% Inputs:
% Signal    - input signal structure
% P.angle   - rotation angle [rads]
% 
% Returns:
% Signal    - output signal structure
%
% Author: Benn Thomsen, September 2004.


R = @(theta) [cos(theta) sin(theta);...
    -sin(theta) cos(theta)]; % Rotation matrix (anonymous func)

Pol=R(-P.angle)*[1 0; 0 0]*R(P.angle);

if size(Signal.Et,1)==1,
    Signal.Et=[Signal.Et; zeros(size(Signal.Et))];
end

Signal.Et=Pol*Signal.Et;

P.Pol = Pol;
varargout{1} = P;
end