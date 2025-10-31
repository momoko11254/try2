function BER = TheoreticalSensitivity(P)
% P.Ps = -50:-40; % signal Power (dBm)
% P.EDFA_NF = 4.5; % dB
%     P.eta = 1;  % quantum efficiency of photodiodes
%     P.B = 107e9; % signal bandwidth (Hz)
%     P.Fb = P.B/1e9;
%     P.T = 300; % ambient temperature (K)
%     P.Rin = 50; % input resistance front-end amplifier for double balanced photodiodes (Ohm)
%     kb = 1.3806503e-23 ; % Boltzmann constant (J/K)
%     T = P.T;
%     Rin = P.Rin;
%     eta = P.eta;

h = 6.626068e-34; % plank's constant (Js)
c = 299792458; % speed of light (m/s)
lambda = 1550e-9; % signal wavelength (m)
f = c/lambda; % signal frequency (Hz)
EDFA_NF = 3; % dB
B = P.DataRate;

EDFA_NF_LIN = 10.^(EDFA_NF/10); % linearise NF
nsp = EDFA_NF_LIN/2; % spontaneous emission factor

Ps = (10.^(P.Ps/10))/1e3; % signal Power (W)

gamma_s = (Ps)/(h*f*B*nsp);
% gamma_s = (eta*Ps)/(h*f*B);

P.SNRperBitdB = 10*log10(gamma_s);

BER = TheoreticalBER(P);
end