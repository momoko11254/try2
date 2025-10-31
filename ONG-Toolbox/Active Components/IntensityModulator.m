function SignalOut = IntensityModulator(SignalInElec,SignalInOpt,P)
% Implements a standart Mach Zender optical modulator (Intensity Modulator)
%
% Inputs:
% SignalInElec  - Input electrical signal structure
% SignalInOpt   - Input optical signal structure
% P.Vbias       - Modulator bias voltage [V]
% P.Vpi         - Vpi of modulator [V]
%
% Returns:
% SignalOut     - output signal structure
%
% Author: Milen Paskov, June 2012
% Modified: Milen Paskov, October 2014

SignalOut = SignalInOpt;

%% Default Parameters
if ~isfield(P, 'Vbias'),
    P.Vbias = 0;
end
if ~isfield(P, 'Vpi'),
    P.Vpi = 1;
end

%% Modulator
if SignalInOpt.Np == 1
    SignalOut.Et = SignalInOpt.Et(1,:).*(1+exp(1i*P.Vbias)*exp(1i*pi/P.Vpi*SignalInElec.Et));
elseif SignalInOpt.Np == 2
    SignalOut.Et(1,:) = SignalInOpt.Et(1,:).*(1+exp(1i*P.Vbias)*exp(1i*pi/P.Vpi*SignalInElec.Et));
    SignalOut.Et(2,:) = SignalInOpt.Et(2,:).*(1+exp(1i*P.Vbias)*exp(1i*pi/P.Vpi*SignalInElec.Et));
end

%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=2))
    disp(' ');
    disp('Intensity Modulator');
    disp(['V_{\pi}: ' num2str(P.Vpi) 'V']);
    disp(['V_{bias}: ' num2str(P.Vbias) 'V']);
end
end