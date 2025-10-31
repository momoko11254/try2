function [Signal, varargout] = BesselLowPassFilter(Signal, P)
% Analogue Bessel filter.
% Analog Bessel lowpass filters have maximally flat
% group delay at zero frequency and retain nearly constant group delay across
% the entire passband. Filtered signals therefore maintain their waveshapes
% in the passband frequency range. Multichannel signals are all filtered
% idependently with the same filter
%
% Signal=BesselLowPassFilter(Signal,P) - returns the filtered signal
% [Signal, hh, FF] = BesselLowPassFilter(Signal, P) - returns the filtered
% signal and the frequency response of the filter.
% Use the following command to plot it.
% >> semilogy(FF, abs(hh).^2);
%
% Inputs:
% Signal        - input signal structure
% P.n           - filter order
% P.BW          - filter 3dB bandwidth (Hz)
%
% Returns:
% Signal        - output signal structure
%
% Author: Seb Savory, June 2005
% Equations for Bessel filter based on
% Digital Signal Processing Proakis & Manolakis 3rd Ed. p690
% Modified: Benn Thomsen, November 2005.
% Modified: Benn Thomsen, October 2010.
% Modified: Sean Kimurray, November 2013


[Np,~] = size(Signal.Et);                  % Total number of points
FF = MakeTimeFrequencyArray(Signal);       % Frequency array [Hz]

if isfield(P,'n')
    N=P.n;
else
    N=5;
end
if floor(N)~=N
    disp('Filter order must be a positive integer')
    return
end
B=factorial(2*N)/2^N/factorial(N);
A = zeros(1,N+1);

for k=0:N
    A(N+1-k) = factorial(2*N-k)/(2^(N-k)*factorial(k)*factorial(N-k));
end

if N<=8
    scale_factors=[1,1.36165412871613,1.75567236868121,2.11391767490422,...
        2.42741070215263,2.70339506120292,2.95172214703872,3.17961723751065];
    scale3dB=scale_factors(N);
else
    % numerically obtain 3dB normalisation constants using Maple Kernel
    syms x H Hc F
    disp('Calculating 3dB normalisation constants')
    H=0;Hc=0;
    for k=1:N+1
        H=H+(1i*x)^(N+1-k)*A(k);
        Hc=Hc+(-1i*x)^(N+1-k)*A(k);
    end
    F=expand(H*Hc)-2*B*B;
    Fsols=solve(F,x);
    scale_factors=double(maple('fsolve',Fsols,'x=2'));
    scale3dB=min(abs(scale_factors));
end

s=1i*FF*scale3dB/P.BW;
P.hh = ones(Np,1)*(B./ polyval(A,s));

Ef=fft(Signal.Et,[],2);
if isreal(Signal.Et);
    Signal.Et=real(ifft(P.hh.*Ef,[],2));
else
    Signal.Et=ifft(P.hh.*Ef,[],2);
end
varargout{1} = P;
end