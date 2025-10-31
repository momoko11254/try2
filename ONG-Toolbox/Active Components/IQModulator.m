function [SignalOut, varargout] = IQModulator(SignalInElec, SignalInOpt, P)
% Models an IQ modulator.
%
% Input:
% SignalInElec          - electrical driving signal structure
% SignalInOpt           - optical signal structure (polarized signal)
% P.Vbias               - Bias voltage [V]
% P.Vpi                 - MZ Vpi [V]
%
% Input Optional:
% P.IL                  - Insertion loss [dB]
% P.ERdB                - Finite extinction ratio for MZModulator [dB]
% P.ParER               - Finite extinction ratio for IQModulator [dB]
%
% Output:
% SignalOut             - Optical modulated signal
%
% Author: Gabriele Liga, March 2012.
% Modified: Milen Paskov, December 2013

%% Create Parameters
SignalOut = SignalInOpt;

%% Finite Extinction Ratio
if isfield(P, 'ERdB')
    alfa_P = 1/2+1/2*(1/10^(P.ParER/20));                                  % Parent MZ splitting ratio derived by the given ER
else
    alfa_P = 0.5;
end

%% IQ optical modulation
SignalInElecI = SignalInElec;
SignalInElecQ = SignalInElec;
SignalInElecI.Et = real(SignalInElec.Et);
SignalInElecQ.Et = imag(SignalInElec.Et);

SignalOutI = MZModulator(SignalInElecI, SignalInOpt, P);                   % Output signal from MZ1
SignalOutQ = MZModulator(SignalInElecQ, SignalInOpt, P);                   % Output signal from MZ2

%% Optical modulation
SignalOut.Et(1,:) = alfa_P*SignalOutI.Et(1,:) +...
                -1j*(1-alfa_P)*SignalOutQ.Et(1,:);                                  % Recombining in the parent structure arms

varargout{1} = P;
end