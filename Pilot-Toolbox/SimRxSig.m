function [CoSig, P] = SimRxSig(CoSig, P)
%% Copy Frames
CoSig.Et = repmat(CoSig.Et,1,P.NumFrames);
%% Circshift
CoSig.Et = circshift(CoSig.Et, P.ShiftIdx*floor(P.Ns), 2);
% DAC (Quantisation noise, ENOB)
CoSig = DAC(CoSig, P);
% % DP-IQ modulator (Vpi, Vbias)
SigElecX = CoSig;
SigElecX.Et = SigElecX.Et(1,:);
SigElecY = CoSig;
SigElecY.Et = SigElecY.Et(2,:);
SigOptX = CoSig;
SigOptX.Et = SigOptX.Et(1,:);
SigOptY = CoSig;
SigOptY.Et = SigOptY.Et(2,:);
SigOptX = IQModulator(SigElecX, SigOptX, P);
SigOptY = IQModulator(SigElecY, SigOptY, P);
CoSig.Et = [SigOptX.Et; SigOptY.Et];
CoSig = GaussianFilter(CoSig, P);
% Frequency offset
P.HetMethod = 'Measured';
CoSig = Heterodyne(CoSig, P);
% Phase noise caused by linewidth
[CoSig, P] = AddPhaseNoise(CoSig, P);
% Additive white Gaussian noise
CoSig = AddNoise(CoSig, P);
% Fiber propagation (PMD, PDL, Gamma)
if P.BackToBack~=1
CoSig = Manakov(CoSig, P);
end
% % ADC
% P.Res = P.ADC.Res;
% P.Vmin = P.ADC.Vmin;
% P.Vmax = P.ADC.Vmax;
% tmpIx = ADC(real(CoSig.Et(1,:)), P);
% tmpQx = ADC(imag(CoSig.Et(1,:)), P);
% tmpIy = ADC(real(CoSig.Et(2,:)), P);
% tmpQy = ADC(imag(CoSig.Et(2,:)), P);
% CoSig.Et = [tmpIx+1j.*tmpQx; tmpIy+1j.*tmpQy];
end
