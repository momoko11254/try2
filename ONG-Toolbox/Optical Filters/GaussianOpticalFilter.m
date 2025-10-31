function [Signal, varargout] = GaussianOpticalFilter(Signal, P)
% GAUSSIANOPTICALFILTER(Signal, P) performs a filtering of the optical
% signal with a filter with Gaussian response. P.n is optional filter
% order (default = 1). P.FWHM is the filter full width half
% maximum (Hz) and P.FreqOffset is the optional filter offset from
% reference wavelength (Hz).
%
% Source: "OptSim Models Reference", Chapter 10 "Optical Filters". (c)
% January 2006 Optical Networks Group, UCL, London. 
% 
% [Signal, hh, FF] = GAUSSIANOPTICALFILTER(Signal, P) optionally returns the
% frequency response of the filter. Use the following command to plot it.
% >> semilogy(FF, abs(hh).^2);
%
% See also LORENTZIANOPTICALFILTER, MZIFILTER.
% 
% Author: Benn Thomsen, May 2005
% Modified: Seb Savory, June 2005
% Modified: Benn Thomsen, January 2006.
% Modified: Sean Kimurray, November 2013

%% Check input parameters and fill default options
if ~isfield(P, 'FreqOffset'),
    P.FreqOffset = 0;
end

if ~isfield(P, 'n'),
    P.n = 1;
end

%% Compute frequency response and do the filtering
%  This is actually a supregaussian filter, according to OptSim
%  documentation. Look into "OptSim Models Reference", Chapter 10 "Optical
%  Filters".
[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

Fo = P.BW / (2*log(2).^(1/(2*P.n)));
hh = ones(Np, 1) * exp(-1/2 * ((FF-P.FreqOffset)./Fo).^(2*P.n));

Eff = ifft(Signal.Et, [], 2);
Gf = hh .* Eff;
Signal.Et = fft(Gf, [], 2);

P.hh = hh;
varargout{1} = P;

%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=2))
    disp(' ');
    disp('Gaussian Optical Filter');
    disp(['3dB Bandwodth: ' num2str(P.BW/1e9) 'GHz']);
    disp(['Filter order: ' num2str(P.n)]);
    disp(['Filter Offset: ' num2str(P.FreqOffset/1e9) 'GHz']);
end
end