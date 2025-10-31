function [Signal1, Signal2] = MZIFilter(Signal, P)
% MZI Optical filter.
%
% [Signal1, Signal2] = MZIFilter(Signal, P)
%
% Inputs:
% Signal    - input signal structure
% P.FSR         - filter full width half maximum (Hz)
% p.ERdB -
% P.FreqOffset  - optional filter offset from reference wavelength (Hz)
%
% Returns:
% Signal        - output signal structure
%
% Author: Benn Thomsen, November 2006.
% Modified: Sean Kimurray, November 2013

[~,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

Signal1=Signal;
Signal2=Signal;

if ~isfield(P, 'FreqOffset'),
    P.FreqOffset=0;
end

if ~isfield(P,'ERdB'),
    a=0.5;
    b=0;
else
    b=10^(-P.ERdB/10);
    a=(1-b)/2;
end


if strcmp(Signal.Ftype,'Electrical')
    warning('You have used an optical filter on an electrical signal')
end

if ~isfield(P, 'n'),
    P.n=1;
end

hh1=sqrt(ones(Signal.Np,1)*a*(1+cos(2000*pi/P.FSR*(FF-P.FreqOffset)))+b);
hh2=sqrt(ones(Signal.Np,1)*a*(1+cos(2000*pi/P.FSR*(FF-P.FreqOffset)+pi))+b);

Ef=ifft(Signal.Et,[],2);
Gf1=hh1.*Ef;
Signal1.Et=fft(Gf1,[],2);

Gf2=hh2.*Ef;
Signal2.Et=fft(Gf2,[],2);


% figure(5),semilogy(FF,(abs(Ef(1,:)).^2./max(abs(Ef(1,:)).^2)),...
%     FF,(abs(hh1).^2),FF,(abs(hh2).^2))
% ylim([1e-6,1])
% title('MZI Filter')
end