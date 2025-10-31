function [ Signal ] = AddShotNoise( Signal )
% Convenience function: adds White Gaussian noise with zero mean and
% standard deviation equal to the minimum added by shot noise
% (Gaussian approximation of Poisson)
%
% Inputs:
% SignalIn          - Signal structure
%
% Returns:
% SignalOut         - Output signal structure
% 
% Author: Domanic Lavery, June 2014
% 
% See also EDFA

% Planck constant [J s]
h = 6.62606957e-34; % Kaye and Laby (2015) defines as 6.62606957(29)e-34

noiset = sqrt(0.5*h*Signal.Fc*Signal.Fs)*(randn(2,length(Signal.Et))+1i*randn(2,length(Signal.Et)));
Signal.Et = Signal.Et+noiset;
end