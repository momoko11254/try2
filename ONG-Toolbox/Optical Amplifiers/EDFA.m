function Signal=EDFA(Signal,P)
% Black box EDFA models gain, gain saturation and ASE
% The noise is split equally to both polarisation states
% Uses 'fsolve' from the optimisation toolbox
% Signal = EDFA(Signal,P)
%
% Inputs:
% Signal        - input signal structure
% P.GdB         - amplifier gain (dB)
% P.NFdB        - amplifier noise figure (dB)
% P.PsatdBm     - saturated output Power (dBm) at G=Go/2 (Go small signal gain) [optional]
% P.PLimit      - Limiting output power (dBm)
%
% Returns:
% SignalOut     - output signal structure
%
% Author: Benn Thomsen, May 2005.
% Modfied: Milen Paskov, November 2014


h = 6.62606957e-34;            % Plank constant (J/s)
[Np,Nt] = size(Signal.Et);

if isfield(P, 'PsatdBm')
    % Fiber-Optic Communication Systems 3rd Ed - Agrawal, Equation 6.1.10
    Go=10^(P.GdB/10);                                               % Linear small signal gain
    PsatOut = 10^((P.PsatdBm-30)/10);                               % Linear saturated output Power at G=Go/2 (W)
    Psat = (Go-2)/(Go*log(2))*PsatOut;                              % Saturated output Power (W)
    Pin = sum(sum(abs(Signal.Et).^2,1),2)/Nt;                       % Average Signal Power (W)
    GainSat = @(G,Go,Pin,Psat) Go*exp(-(G-1)*Pin/Psat)-G;           % Amplifier gain saturation (function)
    G = fsolve(GainSat,Go,optimset('fsolve'),Go,Pin,Psat);          % Determine input Power dependent gain
elseif isfield(P, 'PLimit')
    % This is an approximationg if PsatdBm is unknown. Assumes that the
    % EDFA operates in a saturated region.
    G=P.PLimit-PowerMeter(Signal);
    G=10^(G/10);
else
    G=10^(P.GdB/10);                                                % Linear small signal gain
end

if isfield(P, 'NFdB')&&(P.GdB>0),
    if Np == 1,            % check number of polarisation states if only 1 then create other state
        Signal.Et=[Signal.Et; zeros(1,Nt)];
    end
    
    NF=10^(P.NFdB/10);                  % Linear noise figure
    Nsp=(NF*G-1)/(2*(G-1));             % Calculate spontaneous emission factor from gain and noise figure
    Pase=2*Nsp*(G-1)*h*Signal.Fc*Signal.Fs;     % ASE Power over simulation bandwidth (W)
    
    % White Gaussian noise zero mean and standard deviation equal to ASE
    % Power split equally across the dimensions
    noiset = sqrt(0.25*Pase)*(randn(2,Nt)+1i*randn(2,Nt));
    Signal.Et = sqrt(G)*Signal.Et+noiset;
else
    if isfield(P,'verbose')&&(P.verbose>0); disp('Gain only EDFA (no noise added)'), end
    Signal.Et = sqrt(G)*Signal.Et;
end
end