function [ SignalOut ] = ClipSignal(  SignalIn, P )
%ClipSignal - Clips a signal to reduce the Peak to Avarage Power
%               - Ratio (PAPR) based on the resolution of the DAC
%
% [ SignalOut ] = ClipSignal( SignalIn, P )
%
% Inputs:
% SignalIn - Signal structure with SignalEt containing a real signal
% P.ClipRatiodB - clipping ratio
%
% Returns:
% SignalOut - Signal Structure
%
% Author: Sean Kilmurray, November 2010.

SignalOut = SignalIn;

% Convert to linear
ClipRatio = 10^(P.ClipRatiodB/20);

Pave_sqrt = std(SignalIn.Et);

% Set the maximum amplitude
Amax = ClipRatio*Pave_sqrt;

% Indices of abs(et) > Amax which we need to clip
EtClip = find(abs(SignalIn.Et) > Amax);

% Clip the Signal to A*exp(j*phi)
SignalOut.Et(EtClip) = Amax.*exp(1i.*(angle(SignalIn.Et(EtClip))));

end