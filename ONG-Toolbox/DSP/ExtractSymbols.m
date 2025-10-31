function [SignalOut] = ExtractSymbols(SignalIn)
% Extracts the even samples from signal struct, discard the transitions.
% 
% [SignalOut] = ExtractSymbols(SignalIn)
% 
% Inputs:
% SignalIn          - Signal structure
% 
% Returns:
% SignalOut         - Output signal structure
% 
% Author: 

SignalOut = SignalIn;

% Downsampling
pol1 = SignalOut.Et(1,2:2:end); % even samples are symbols
pol2 = SignalOut.Et(2,2:2:end);

SignalOut.Et = pol1;
SignalOut.Et(2,:) = pol2;

SignalOut.Fs = SignalIn.Fs/2;       % Save new sampling rate
end