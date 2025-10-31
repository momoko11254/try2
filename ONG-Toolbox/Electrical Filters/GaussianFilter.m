function [Signal, varargout] = GaussianFilter(Signal, P)
% Analogue Gaussian filter.
%
% [Signal, varargout] = GaussianFilter(Signal, P)
%
% Inputs:
% SignalIn      - input signal structure
% P.n           - optional filter order (default = 1)
% P.BW          - filter bandwidth (Hz)
% P.FreqOffset  - optional filter offset from reference wavelength (Hz)
%
% Returns:
% SignalOut     - output signal structure
%
% Author: Benn Thomsen, 27 July 2006.
% Modified: Sean Kimurray, November 2013

[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

if ~isfield(P, 'FreqOffset'),
    P.FreqOffset=0;
end

if ~isfield(P, 'n'),
    P.n=1;
end

Fo=P.BW/log(2).^(1/(2*P.n));
P.hh=ones(Np,1)*exp(-1/2*((FF-P.FreqOffset)./Fo).^(2*P.n));

Ef = fft(Signal.Et,[],2);

if isreal(Signal.Et);
    Signal.Et=real(ifft(P.hh.*Ef,[],2));
else
    Signal.Et=ifft(P.hh.*Ef,[],2);
end

varargout{1} = P;
end