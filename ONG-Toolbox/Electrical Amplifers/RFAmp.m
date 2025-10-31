function SignalOut = RFAmp(SignalIn, P)
% Models RF amplifier gain only
%
% SignalOut=Gain(SignalIn,P)
%
% Inputs:
% SignalIn - input signal structure
% P.GdB - amplifier gain (dB)
%
% Returns:
% SignalOut - output signal structure
%
% Author: Benn Thomsen, October 2005.

SignalOut = SignalIn;
G = 10^(P.GdB/10);                      % Linear gain
SignalOut.Et = G*SignalIn.Et;
end