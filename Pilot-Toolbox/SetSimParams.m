% Rx data frame
P.NumFrames = 2;
P.ShiftIdx = 5000;                 % shift idx between x and y
% DAC
P.DAC.Res = 8;
P.DAC.Vsw = 1;
P.DAC.ENOB = 5.0;
P.Vmin = -7.0;
P.Vmax =  7.0;
P.minFs = 86e9;
P.maxFs = 92e9;
P.blocksize = 128;
P.Fs = FindFs(P);
P.Ns = P.Fs/P.Fb;
P.upsample = 1;
% MZM
P.Vbias = 1.5;
P.Vpi = 3;
% ADC
P.CoRx = 0;
P.ADC.Res = 8;
% Noise
P.FreqOffset = 100e6;
P.Linewidth = 900e3;
P.commonphase = 1;
P.OSNR = 43;
% Manakov
P.RefWavelength = 1550e-9;
P.Length = 1;
P.dz = 1;
P.PMD = 1e-12;
