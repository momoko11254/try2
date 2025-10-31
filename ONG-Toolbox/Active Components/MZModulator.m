function [SignalOut, varargout] = MZModulator(SignalInElec, SignalInOpt, P)
% Models an differentially driven MZ modulator.
%
% Input:
% SignalInElec          - electrical driving signal structure
% SignalInOpt           - optical signal structure (polarized signal)
% P.Vbias               - Bias voltage [V]
% P.Vpi                 - MZ Vpi [V]
%
% Input Optional:
% P.IL                  - Insertion loss [dB]
% P.ERdB                - Finite extinction ratio [dB]
%
% Output:
% SignalOut             - Optical modulated signal
%
% Author: Gabriele Liga, March 2012.
% Modified: Milen Paskov, December 2013

%% Create Parameters
SignalOut = SignalInOpt;

if ~isreal(SignalInElec.Et)
    error('Input Electrical signal is complex');
end

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

%% Optical modulation
SignalInElec.Et=SignalInElec.Et/2;                                         % Split the voltage diffentially for the MZ inputs
% MZ transfer function
SignalOut.Et(1,:) = SignalInOpt.Et(1,:).*(alfa_C.*exp(1j*pi*(SignalInElec.Et+P.Vbias)/P.Vpi)-...
                                       (1-alfa_C).*exp(-1j*pi*(SignalInElec.Et+P.Vbias)/P.Vpi));

varargout{1} = P;
end