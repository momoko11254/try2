function [SignalOut, varargout] = PhotoDiode(SignalIn, P)
% Polarisation independent square-law detector.
% Converts the optical field to an electrical field using either an IDEAL
% or NON-IDEAL photodiode including detector responsivity, receiver noise
% (shot & thermal noise) and finite electrical bandwidth applying Bessel LPF.
%
% Source: For SHOT noise, THERMAL noise and PhotoDiode current (Ipn) Eqs:
% Please see Fiber-Optic Communication Systems-4th edition, G. Agrawal,  pp.151--154
%
% [SignalOut, varargout] = PhotoDiode(SignalIn, P)
%
% Inputs:
% SignalIn - input signal structure
%
% PHOTODIODE parameters
% P.R  - detector responsivity (A/W)
% P.Id - Dark Current          (A)
% P.Fn - Noise figure
% P.G  - Gain
%
% BESSEL LPF parameters
% For Bessel Low Pass filter
% P.BW - electrical bandwidth (GHz)
% P.n  - filter order
%
% Returns:
% SignalOut - output signal structure
% SignalOut.Et - output Electrical field
%
% Author: Benn Thomsen, September 2004.
% Modified by Sezer Erkilinc, Nov 2013.

%% Create Parameters
[~, Nt] = size(SignalIn.Et);
[~, TT] = MakeTimeFrequencyArray(SignalIn);
dT = TT(2);

SignalOut = SignalIn;

%% Typical parameter calues for non-ideal photodiode
% P.R    = 0.8;         % Responsivity (A/W)
% P.Id   = 10e-9;       % Dark current (A)
% P.Fn   = 1;           % PreAmplifer noise figure
% P.G    = 1;           % PreAmplier Gain

if  ~isfield(P, 'R') || ~isfield(P, 'Id') || ~isfield(P, 'Fn') || ~isfield(P, 'G')
    SignalOut.Et = sum(real(SignalIn.Et).^2+imag(SignalIn.Et).^2,1);
    % Verbose
    if(isfield(P, 'verbose') && (P.verbose==1))
        disp('Ideal Photodiode');
    end
else
    % Constants
    Load   = 50;          % Load Resistance (Ohm)
    T      = 273+25;      % Temperature (K)
    Kb     = 1.38e-23;    % Boltzmann Constant (J/K)
    q      = 1.6e-19;     % Elementary charge (C)
    
    Ip = P.R*sum(abs(SignalIn.Et).^2,1); % Detect optical signal
    
    shotNoise    = 2*q*(Ip+P.Id);        % Shot Noise     referred as (\sigma_s) in Eq. 4.4.5
    thermalNoise = 4*Kb*T*P.Fn/Load;     % Thermal Noise  referred as (\sigma__T) in Eq. 4.4.9
    Ipn          = Ip + sqrt(1/(dT)*(shotNoise+thermalNoise)./Nt).*randn(1,Nt); % Eq 4.4.6
    Vout         = Load*Ipn;             % Detected electrical field (Et)
    
    SignalOut.Et = Vout;
    SignalOut    = BesselLowPassFilter(SignalOut, P);
    
end

varargout{1} = P;

end