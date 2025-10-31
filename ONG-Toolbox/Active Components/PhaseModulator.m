function SignalOut = PhaseModulator(SignalInElec, SignalInOpt, P)
% Implements a standart optical Phase Modulator
%
% Inputs:
% SignalInElec  - Input electrical signal structure
% SignalInOpt   - Input optical signal structure
% P.Vpi         - Vpi of modulator [V]
%
% Returns:
% SignalOut     - Output signal structure
%
% Author: Carsten Behrens
% Modified: Milen Paskov, February 2012
% Modified: Milen Paskov, December 2013
% Modified: Milen Paskov, October 2014

SignalOut = SignalInOpt;

%% Default Parameters
if ~isfield(P, 'Vpi'),
    P.Vpi = 1;
end

%% Modulator
if SignalInOpt.Np == 1
    SignalOut.Et = SignalInOpt.Et(1,:).*exp(1i*pi/(P.Vpi).*SignalInElec.Et);
elseif SignalInOpt.Np == 2
    SignalOut.Et(1,:) = SignalInOpt.Et(1,:).*exp(1i*pi/(P.Vpi).*SignalInElec.Et);
    SignalOut.Et(2,:) = SignalInOpt.Et(2,:).*exp(1i*pi/(P.Vpi).*SignalInElec.Et);
end

%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=2))
    disp(' ');
    disp('Phase Modulator');
    disp(['V_{\pi}: ' num2str(P.Vpi) 'V']);
end