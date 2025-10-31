function Signal = WDM_MUX_Homog(Signal, P)
% WDM Multiplexer generates N homogeneous WDM Channels
% where N is an odd integer on an equally spaced frequency grid.
%
% Inputs:
% P.nWDM        - number of WDM channels
% P.Spacing     - frequency spacing of grid (Hz)
% P.DecorrWDM   -  Symbol shift between adjacent WDM channels for decorrelation
%
% Optional input:
% P.PolRotate   - Random polarisation rotation applied to each channel for Dual Pol Signals only
% P.RandOffset  - Random symbol offset for each channel
%
% Return:
% Signal        - combined output signal structure
% 
% Author: David Millar, September 2008
% Modified: Sean Kimurray, November 2013

[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
dT = 1/Signal.Fs;                           % Temporal resolution (s)
TT = (0:Nt-1)*dT;                           % Time array (s)

channel_no = -floor(P.nWDM/2):floor(P.nWDM/2); % number of channel: 0 = center

F_Grid = P.WDMFreqOffset *channel_no;              % ideal frequency grid in Hz
Signal.Fchan = round(F_Grid/dF)*dF;        % rounded frequency grid in Hz

if isfield(P,'RandOffset')
    s_bits = randsrc(1,P.nWDM,(1:Nt));   % decorrelation shift in samples random
else
    s_bits = P.DecorrWDM*Signal.Fs/Signal.Fb*channel_no;  % decorrelation shift in samples
end

Off_Sig = zeros(size(Signal.Et)); % init final storage vector

for s = 1:P.nWDM
    P_Arr = exp(2j*pi*Signal.Fchan(s)*TT);        % dual pol phase array in channel,time
    Shift_Sig = circshift(Signal.Et,[0 s_bits(s)]);
    if Np == 2 && (isfield(P, 'PolRotate') && (P.PolRotate == 1))
        theta = rand*2*pi-pi;
        rotation = [cos(theta) sin(theta) ; -sin(theta) cos(theta)];
        Off_Sig = Off_Sig + rotation*[Shift_Sig(1,:).*P_Arr; Shift_Sig(2,:).*P_Arr];
    elseif Np == 2
        Off_Sig = Off_Sig + [Shift_Sig(1,:).*P_Arr; Shift_Sig(2,:).*P_Arr];
    else
        Off_Sig = Off_Sig + Shift_Sig.*P_Arr;
    end
end
Signal.Et = Off_Sig;
end