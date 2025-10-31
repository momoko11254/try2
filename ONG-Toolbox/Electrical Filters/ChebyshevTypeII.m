function [Signal, varargout] = ChebyshevTypeII(Signal, P)
% Analogue Chebyshev Type II filter.
% Chebyshev Type II filters are monotonic in the passband and equiripple
% in the stopband. Type II filters do not roll off as fast as type I
% filters, but are free of passband ripple
%
% Signal=ChebyshevTypeII(Signal,P) - returns the filtered signal
% [Signal, hh, FF] = ChebyshevTypeII(Signal,P) - returns the filtered
% signal and the frequency response of the filter.
% Use the following command to plot it.
% >> semilogy(FF, abs(hh).^2);
%
%
% Inputs:
% Signal            - input signal structure
% P.n               - filter order
% P.SbeHz           - Stopband edge frequency (Hz)
% P.SbRipple        - stop band ripple (dB)
%
% Returns:
% Signal            - output signal structure
%
% Author: Sean Kimurray, November 2013

[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

s=1i*FF;
[b,a] = cheby2(P.n, P.SbRipple, P.SbeHz,'s');
P.hh = polyval(b,s) ./ polyval(a,s);
P.hh=P.hh./max(abs(P.hh));

P.hh = ones(Np,1)*P.hh;

Ef=fft(Signal.Et,[],2);

if isreal(Signal.Et);
    Signal.Et=real(ifft(P.hh.*Ef,[],2));
else
    Signal.Et=ifft(P.hh.*Ef,[],2);
end

varargout{1} = P;
end