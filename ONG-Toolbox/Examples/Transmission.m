function [SignalOut, varargout] = Transmission(SignalIn, P)
% Function that applies transmission imapairments and/or ASE noise. Only CD
% is implemented for now.
%
% [SignalOut, varargout] = Transmission(SignalIn, P)
%
% Inputs:
% SignalIn                  - Input signal structure
% P.BackToBack              - Set to 1 to applies transmission imapairments
% P.OSNR                    - If ASE loading is used [dB]
%
% Returns:
% SignalOut                 - Output signal structure
% P                         - Parameter structure
%
% Author: Milen Paskov, December 2013

%% Paramaters
temp = SignalIn;

%% Add CD
if (isfield(P, 'BackToBack') && (P.BackToBack == 0))
    P.D = -1*P.D;
    CDApp = CD_Ideal(temp, P);
    temp = CDApp;
end

%% Noise Loading Module
if isfield(P, 'OSNR')
    NoiseLoaded = AddNoise(temp, P);
    temp = NoiseLoaded;
end

%% Transmission Impairments
% Polarization rotations
% PMD
% PDL
% Non-Linear effects

SignalOut = temp;
varargout{1} = P;
end