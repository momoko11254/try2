function [Signal, varargout]=PolRotate(Signal,P)

% Rotates the Signal Polarisation and returns the transfer matrix for an arbitrary polarisation rotator
%
% PolRotate(angle)*[EinX; EinY]
%
% P.angle - ccw rotation angle (rads)
%
% Benn Thomsen, September 2004.

Rotate=[cos(P.Angle) -sin(P.Angle); sin(P.Angle) cos(P.Angle)];

if size(Signal.Et,1)==1,
    Signal.Et=[Signal.Et; zeros(size(Signal.Et))];
end

Signal.Et=Rotate*Signal.Et;

P.Pol = Rotate;
varargout{1} = P;