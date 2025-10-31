function Signal = Attenuator(Signal, P)
% Attenuates the optical field
%
% Signal=Attenuator(Signal,AdB)
%
% Inputs:
% Signal        - input signal structure
% P.AdB         - attenuation (dB)
%
% Returns:
% Signal        - output signal structure
%
% Author: Benn Thomsen, May 2005.

A = 10^(-P.AdB/20);
Signal.Et = A*Signal.Et;
end