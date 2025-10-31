function [Signal, varargout] = ACcouple(Signal, P)
% High pass RC filter such as those used to AC couple RF circuits.
% 
% [Signal, varargout] = ACcouple(Signal, P)
% 
% Inputs:
% SignalIn          - Signal structure
% P.Fc              - Cutoff frequency [Hz]
% Or:
% P.R               - Resistance (Default value - 50ohm) [ohm]
% P.C               - Capacitance [F]
% 
% Returns:
% SignalOut         - Output signal structure
%
% Author:

[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = Signal.Fs/Nt;                          % Spectral resolution (Hz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (Hz)

if isfield(P, 'Fc'),
    T=1./P.Fc;
else
    if isfield(P, 'R'),
        R=P.R;
    else
        R=50;
    end
    T=R*P.C;
end

P.hf=ones(Np,1)*(-1i*T*2*pi*FF./(1-1i*T*2*pi*FF));

if isreal(Signal.Et);
    Signal.Et=real(fft(P.hf.*ifft(Signal.Et)));
else
    Signal.Et=fft(P.hf.*ifft(Signal.Et));
end

varargout{1} = P;
end