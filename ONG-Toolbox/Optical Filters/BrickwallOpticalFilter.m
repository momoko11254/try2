function [SignalOut, varargout] = BrickwallOpticalFilter(SignalIn, P)
% BRICKWALLOPTICALFILTER: SignalOut = BrickwallOpticalFilter( SignalIn,P )
% Performs a optical filtering with a rectangular response.
% P.GHzBW (Hz) is FWHM and P.GHzOffset (Hz) is the optional filter offset from
% reference wavelength. Setting P.GHzOffset to "O" Hz --> symmetric around reference wavelength.
%
% Inputs:
% SignalIn    - input signal structure
% OPTICAL FILTER parameters
% P.BW         - Bandwidth of the optical filter [Hz]
% P.FreqOffset - Offset value for the filter     [Hz],
%
%
% Returns:
% SignalOut    - output signal structure
%
% See also GAUSSIANOPTICALFILTER, LORENTZIANOPTICALFILTER, MZIFILTER.
%
% Author: Carsten Behrens,  May 2010.
% Modified: Sezer Erkilinc, Nov 2013.

SignalOut   = SignalIn; % copy signal structure

%% Check input parameters and fill default options
if ~isfield(P, 'FreqOffset'),
    P.FreqOffset = 0;
end

[Np, Nt] = size(SignalIn.Et);
dF = SignalIn.Fs/Nt;           % Spectral resolution [Hz]

%% Compute frequency response and do the filtering
u            = ones(1,round(P.BW/dF));                      % Flat impulse response
delta        = 1e-15*(zeros(1, Nt-round(P.BW/dF)+1));    % Set the freq. of delta function by P.GHzBW
delta( Nt/2 + 1 + round((P.FreqOffset-P.BW/2)/dF) ) = 1;  % Shift the delta function by P.GHzOffset

hh           = ones(Np,1)*conv(delta,u);   % Convolve the flat impulse response with delta function to create the brickwall filter at the desired frequencies
hh           = circshift(hh,[0 -Nt/2]);    % Apply circular shift to make the response symmetric around 0

Ef           = ifft(SignalIn.Et, [], 2);     % Take fourier transform of the input signal
Gf           = hh.*Ef;                     % Apply brickwall filter
SignalOut.Et = fft(Gf,[],2);

%% PLOT the response of the filter
% FF = [0:Nt/2-1, -Nt/2:-1]*dF; % Frequency array [Hz]
% FF = FF/1e-9;                 % Frequency array [GHz]
% figure; semilogy( FF, abs(Ef) );
% hold on; plot( FF, hh, '.r', 'Linewidth', 2 );
% xlabel('Frequency [GHz]'); ylabel('Intensity [dB]')
% ylim([1e-15 1])
% set(gca,'XTick', -100:10:100 ); grid on;
%
% PLOT the signal before and after filtering
% figure(6); semilogy( FF, (abs(Ef(1,:)).^2./max(abs(Ef(1,:)).^2)), FF, abs(hh).^2 )
% ylim([1e-6,1]); title('Brickwall Filter')
% figure(7); plot( FF,angle(Ef(1,:)), FF, angle(hh) )
% title('Brickwall Filter'); ylim([1e-6,1])


varargout{1} = P;
end
