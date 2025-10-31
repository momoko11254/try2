function Signal=SetPower(Signal,P)
% Sets the signal Power per channel
%
% SignalOut = SetPower(SignalIn,P)
%
% Inputs:
% SignalIn      - input signal structure
% P.PdBm        - required average output Power dBm
% 
% Returns:
% SignalOut     - output signal structure
%
% Author: Benn Thomsen, October 2010
% 
% See also POWERMETER


if isfield(Signal,'Fchan')
    G=P.PdBm-(PowerMeter(Signal)-10*log10(length(Signal.Fchan)));
else
    G=P.PdBm-PowerMeter(Signal);
end

Signal.Et = 10^(G/20)*Signal.Et;
end