function out = OSNR(SignalIn, P)
% out = OSNR(SignalIn, P) calculates the OSNR of an optical signal the
% same way it is calculated in the lab with a real OSA.
%
% Inputs:
% SignalIn            input signal structure
% P.SigBW        (Hz) signal integration bandwidth
% P.NoiseBW      (Hz) noise integration bandwidth
% P.NoiseCentre  (Hz) position of noise calculation. Noise will be
%                     calculated in two frequency areas
% P.NoiseCentre is the distance between the centre of the signal
% integration area and the centre of each of the noise integration areas.
%
% Optional inputs:
% P.SigCentre    (Hz) centre of the signal intergration area
% P.SigCentre is the distance between the centre of the whole spectrum
% and the centre of the Signal integration area. If not specified the
% centre of the signal is where the whole signal Power integral has half
% of its maximum value.
%
% The function returns and structure containing
% NoisePdBm     noise Power (dBm/P.SigBW)
% SignalPdBm    signal Power (dBm)
% OSNR_OSA      naive OSNR ((S+N) - N) (in dB)
% OSNR_Standard naive OSNR with 0.1 nm reference (standard)
%
% See also WRITEME.
% 
% Codebase: Benn Thomsen, June 2005
% Modified: Heribert Brust, Dec 2005
% Modified: Benn Thomsen, May 2006
% Modified: JMD Mendinueta, Aug 2008
% Modified: Maria Ionescu, Nov 2013

%% Check input arguments
debug__ = 0;

%% Do it

[~,Nt] = size(SignalIn.Et);             % Total number of points
dF = SignalIn.Fs/Nt;                    % Spectral resolution (Hz)
FF = [0:(Nt/2)-1,-Nt/2:-1] * dF;        % Frequency array (Hz)

% half number of samples of signal integration bandwidth
n = round(0.5 * P.SigBW/dF);
% half number of samples of each of the noise intergation areas
m = round(0.5 * P.NoiseBW/dF);

% If is the Power spectral density with dF resolution
If = sum(abs(fftshift(ifft(SignalIn.Et, [], 2), 2)).^2, 1);

if ~isfield(P, 'SigCentre'),
    % warning('Using calculated centre of mass for signal centre')
    s=0;
    i=0;
    t=sum(If);
    while s<(t/2),
        s=s+If(i+1);
        i=i+1;
    end % centre of signal
    % "scentre" is the location of the centre of the signal integration
    % area in the spectrum. It should be typically frequency 0 for NRZ
    % modulated signals.
    scentre = i-1;
else
    % required location in the spectrum
    scentre = round(length(If)/2)+round(P.SigCentre/dF);
end

% ncentre1 is the location of the centre of the 1. Noise calculation area
ncentre1 = scentre - round(P.NoiseCentre/dF);
ncentre2 = scentre + round(P.NoiseCentre/dF);

% DEBUG: print all center in GHz units
if(debug__),
    freqAxisGHz = 1e-9 * fftshift(FF);
    fprintf('OSNR: Signal center = %f GHz\n', freqAxisGHz(scentre));
    fprintf('OSNR: Signal BW = %f GHz\n', P.SigBW * 1e-9);
    fprintf('OSNR: Noise1 center = %f GHz\n', freqAxisGHz(ncentre1));
    fprintf('OSNR: Noise2 center = %f GHz\n', freqAxisGHz(ncentre2));
    fprintf('OSNR: Noise BW = %f GHz\n', P.NoiseBW * 1e-9);
    fprintf('\n');
end

% Mean value of the noise (N_0/2)
AveNoisePower = sum([If(ncentre1-m:ncentre1+m-1), If(ncentre2-m:ncentre2+m-1)]) / floor(4*m); % Noise Power in Watts (in noise bandwidth)
% AveNoisePower = max([If(ncentre1-m:ncentre1+m-1), If(ncentre2-m:ncentre2+m-1)]); % Noise Power in Watts (in noise bandwidth)
% 0.1 nm reference bandwidth
RefBW = 12.5e9; % (Hz)

%% Powers in Watts
% Noise Power within the reference bandwidth, typically 0.1nm.
out.NoisePowerW = AveNoisePower/dF*RefBW; % (W)
% Signal Power within the signal bandwidth, without noise.
out.SigPowerW = sum(If(scentre-n:scentre+n-1))-AveNoisePower/dF*P.SigBW; %(W)

%% Powers in dBm
out.NoisePdBm = 10*log10(out.NoisePowerW) + 30;
out.SignalPdBm = 10*log10(out.SigPowerW) + 30;
% OSNR as returned by OSA (at least Avantest)

%% Calculate the OSNR = [(S+N) - N](in SigBW)/N(in 12.5GHz)
out.OSNR_OSA = out.SignalPdBm - out.NoisePdBm;

%% Plot spectrum
%%
if(1==0)
    figure(1), clf(1), hold all, grid on
    IfdBm = 10*log10(If)+30;
    freqAxisGHz = 1e-9 * fftshift(FF);
    plot(freqAxisGHz, IfdBm)
    plot(freqAxisGHz(scentre-n:scentre+n-1),IfdBm(scentre-n:scentre+n-1))
    plot(freqAxisGHz(ncentre1-m:ncentre1+m-1),IfdBm(ncentre1-m:ncentre1+m-1),'y')
    plot(freqAxisGHz(ncentre2-m:ncentre2+m-1),IfdBm(ncentre2-m:ncentre2+m-1),'y')
end
end