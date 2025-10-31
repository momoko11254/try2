function [pdBm, Power]=PowerMeter(Signal)
% Returns the Average Power of the optical field in (dBm).
%
% [pdBm, Power]=PowerMeter(Signal)
% 
% Inputs:
% SignalIn - input signal structure
%
% Returns:
% pdBm          - average Power in dBm
% Power         - average Power in W
% 
% Author: Benn Thomsen, October 2010

Power=mean(sum(abs(Signal.Et).^2,1));   % Average Power (W)
pdBm=10*log10(Power)+30;                % Average Power (dBm)
end