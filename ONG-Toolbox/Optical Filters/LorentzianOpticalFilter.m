function [Signal, varargout] = LorentzianOpticalFilter(Signal, P)
% LORENTZIANOPTICALFILTER(Signal, P) performs a filtering of the optical
% signal with a filter with Lorentzian response. P.n is optional filter
% order (default = 1). P.FWHM is the filter full width half
% maximum (Hz) and P.Offset is the optional filter offset from
% reference wavelength (Hz).
% 
% Source: "OptSim Models Reference", Chapter 10 "Optical Filters". (c)
% January 2006 Optical Networks Group, UCL, London. 
%
% [Signal, hh] = LORENTZIANOPTICALFILTER(Signal, P) optionally returns the
% frequency response of the filter. Use the following command to plot it.
% >> semilogy(FF, abs(hh).^2);
%
% See also GAUSSIANOPTICALFILTER, MZIFILTER.
% Author: Jose Manuel D. Mendinueta, March 2010.
% Modified: Sean Kimurray, November 2013

%% Check input parameters and fill default options
if ~isfield(P, 'FreqOffset'),
    P.FreqOffset = 0;
end

if ~isfield(P, 'n'),
    P.n = 1;
end

%% Compute frequency response and do the filtering
%  Look into "OptSim Models Reference", Chapter 10 "Optical Filters" for
%  the Lorentzian and supergaussian frequency response.
[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

Fo = (P.BW) ./ sqrt(2.^(1/P.n) - 1);
LKernel = (2./Fo) .* (FF - (P.FreqOffset));
LFilter = (1 ./ (1 + (LKernel.^2) )).^(P.n./2);
hh = ones(Np, 1) * LFilter;

Ef = ifft(Signal.Et, [], 2);
Gf = hh .* Ef;
Signal.Et = fft(Gf, [], 2);

P.hh = hh;
varargout{1} = P;
end