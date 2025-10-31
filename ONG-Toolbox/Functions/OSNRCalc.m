function OSNR = OSNRCalc(SignalPower, NoisePower, NoiseBW)
% Calcuates the OSNR and normalises it t0.1nm bandwidth.
% 
% OSNR = OSNRCalc(SignalPower, NoisePower, NoiseBW)
% 
% Inputs:
% SignalPower       - power of the signal from the OSA
% NoisePower        - power of the noise floor from the OSA
% NoiseBW           - bandwidth of the measurement
% 
% Returns:
% OSNR              - OSNR in a 0.1nm bandwidth
% 
% Authors:

SNR_Meas = SignalPower-mean(NoisePower);
Ref_BW = NoiseBW;                           % Reference Bandwidth in nm
SNRLin = 10.^(SNR_Meas./10);                % Linear OSNR over ref BW
OSNRLin = SNRLin-1;                         % SNR - not (S+N)/N
OSNR_RefBW = 10.*log10(OSNRLin);            % True OSNR over ref BW (dB)
OSNR = OSNR_RefBW+10.*log10(Ref_BW/0.1);    % True OSNR over 0.1nm

end