function [SignalOut, varargout] = DDMZModulator(SignalInElec, SignalInOpt, P)
% Implements a standart optical Phase Modulator
%
% Inputs:
% SignalInElec          - input electrical signal structure
% SignalInOpt           - input optical signal structure
% P.Vpi                 - Vpi of modulator [V]
%
% Input Optional:
% P.IL                  - Insertion loss [dB]
% P.ERdB                - Finite extinction ratio [dB]
%
% Returns:
% SignalOut - output signal structure
%
% Author: Milen Paskov, May 2012
% Modified: Milen Paskov, December 2013

%% Create Parameters
SignalOut = SignalInOpt;

%% Insertion loss
if isfield(P, 'IL')
    IL = 10^(-P.IL/10);                                                    % Insertion loss conversion dB->natural
    SignalInOpt.Et = sqrt(IL)*SignalInOpt.Et;
end

%% Finite Extinction Ratio
if isfield(P, 'ERdB')
    alfa_C = 1/2+1/2*(1/10^(P.ERdB/20));                                     % Field splitting ratio
else
    alfa_C = 0.5;
end

%% Seprate Electrical signals
ElecI = real(SignalInElec.Et);
ElecQ = imag(SignalInElec.Et);

%% Optical modulation
SignalOut.Et(1,:) = SignalInOpt.Et(1,:).*(alfa_C.*exp(1j*pi*(ElecI+P.Vbias)/P.Vpi)-...
                                      (1-alfa_C).*exp(-1j*pi*(ElecQ+P.Vbias)/P.Vpi));

varargout{1} = P;
end