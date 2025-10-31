function [SignalOut, P] = FrequencyShifter(SignalIn, P)
% Shifts the carrier frequency by the specified amount.
% N.B. Frequency shift is negative
%
% SignalOut = FrequencyShifter(SignalIn,P)
%
% Inputs:
% SignalIn - input signal structure
% P.FreqOffset - frequency offset (Hz)
%
% Returns:
% SignalOut - output signal structure
%
% Author: Benn Thomsen, May 2005.
% Modified: Milen Paskov and Domanic Lavery, December 2013.

SignalOut = SignalIn;
[Np,~] = size(SignalIn.Et);                  % Total number of points
[FF, TT] = MakeTimeFrequencyArray(SignalIn);  % Time array [s]
dF = FF(2);
P.FreqOffset = dF*round(P.FreqOffset/dF);

SignalOut.Et = ones(Np,1)*exp(1j*2*pi*P.FreqOffset*TT).*SignalIn.Et;
SignalOut.Fc = SignalIn.Fc+P.FreqOffset;
end
