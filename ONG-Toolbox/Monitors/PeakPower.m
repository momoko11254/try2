function [pdBm, Power]=PeakPower(Signal)
% Returns the Peak Power of the optical field in (dBm).
%
% [pdBm, Power]=PeakPower(Signal)
%
% Inputs:
% SignalIn      - input signal structure
%
% Returns:
% pdBm          - peak Power in dBm
%
% Author: Benn Thomsen, May 2005.

Power=max(sum(real(Signal.Et).^2+imag(Signal.Et).^2,1));
pdBm=10*log10(Power)+30;
end