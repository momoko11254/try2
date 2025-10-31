function Signal = ZeroPad(Signal, P)
% Implements delta function upsampling.
% Works for all signal types, real, complex, single or dual pol
%
% Signal = ZeroPad(Signal, P)
% 
% Inputs:
% Signal        - signal structure
% P.Ns          - (integer) oversampling
%
% Returns:
% Signal structure with upsampled Et field
%
% Modified: Milen Paskov & Domanic Lavery, December 2013
%
% See also SAMPLEANDHOLD

delta = zeros(1,P.Ns);
delta(1) = 1;
Signal.Et = kron(Signal.Et, delta);

% Adjust the Signal sampling frequency of the signal
Signal.Fs = Signal.Fs*P.Ns;

end