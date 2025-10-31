function SignalOut=Gain(SignalIn,P)

% Models amplifier gain only
%
% SignalOut=Gain(SignalIn,P)
%
% Inputs:
% SignalIn - input signal structure
% P.GdB - amplifier gain (dB)
% or
% P.Target - target optical mean power (dBm)
%
% Returns:
% SignalOut - output signal structure 
%
% Author: Benn Thomsen, May 2005.

SignalOut=SignalIn;

if isfield(P,'GdB')
    G=10^(P.GdB/10);                      % Linear gain
    SignalOut.Et = sqrt(G)*SignalIn.Et;
elseif isfield(P,'Target')
    G=1e-3.*10^(P.Target/10)/mean(sum(abs(SignalIn.Et).^2,1));          % Linear target
    SignalOut.Et = sqrt(G)*SignalIn.Et;
else
    warning('set field to either "P.GdB" or "P.Target"');
end