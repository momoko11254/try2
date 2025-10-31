function Signal = SampleAndHold(Signal, P)
% Implements the sample and hold function of an ideal DAC/ADC
% Works for all signal types, real, complex, single or dual pol
%
% Signal = SampleAndHold(Signal, P)
% 
% Inputs:
% Signal        - signal structure
% P.Ns          - (integer) oversampling
%
% Returns:
% Signal structure with upsampled Et field
%
% Author: Sean Kilmurray, November 2013
% Modified: Domanic Lavery, December 2013
%
% See also ZEROPAD

delta=ones(1,P.Ns);
Signal.Et = kron(Signal.Et, delta);

% Adjust the Signal sampling frequency of the signal
Signal.Fs = Signal.Fs*P.Ns;

end