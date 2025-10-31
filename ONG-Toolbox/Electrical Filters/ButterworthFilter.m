function [Signal, varargout]=ButterworthFilter(Signal,P)
% Analogue Butterworth filter.
% Butterworth filters are characterized by a magnitude
% response that is maximally flat in the passband and monotonic overall.
%
% Signal=ButterworthFilter(Signal,P)

% Signal=ButterworthFilter(Signal,P) - returns the filtered signal
% [Signal, hh, FF] = ButterworthFilter(Signal,P) - returns the filtered
% signal and the frequency response of the filter.
% Use the following command to plot it.
% >> semilogy(FF, abs(hh).^2);
%
% Inputs:
% Signal        - input signal structure
% P.n           - filter order
% P.BW          - filter passband bandwidth (Hz)
%
% Returns:
% Signal        - output signal structure
%
% Author: Benn Thomsen, May 2005.
% Modified: Sean Kimurray, November 2013

[~,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                         % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF; % Frequency array (Hz)

s=1i*FF;
[b,a] = butter(P.n,P.BW/2,'s');
P.hh = polyval(b,s) ./ polyval(a,s);
P.hh=P.hh./max(abs(P.hh));

Ef=fft(Signal.Et,[],2);

if isreal(Signal.Et);
    Signal.Et=real(ifft(P.hh.*Ef,[],2));
else
    Signal.Et=ifft(P.hh.*Ef,[],2);
end

varargout{1} = P;
end