function Signal = Delay(Signal,T)
% Delays the input signal by an arbitrary amount
%
% Signal = Delay(Signal,T)
%
% Inputs:
% Signal    - signal input structure
% T         - delay (s)
% 
% Returns:
% Signal    - output signal structure
%
% Author: Benn Thomsen, May 2005.


FF = MakeTimeFrequencyArray(SignalIn);        % Frequency array (Hz)
hh=ones(Np,1)*exp(-1i*T*2*pi*FF);
Signal.Et=ifft(hh.*fft(Signal.Et,[],2),[],2);
end