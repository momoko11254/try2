function [FOout, SignalOut] = PilotAided_FO_Removal(SignalIn, P)
% Extract a known pilot sequence from a capture and use just these pilots
% for FO estimation. Prior RRC filtering is not required. 
%
% Thomas Gerard May 2019
%

%% Input Checks

temp = SignalIn; 

if temp.Fs/temp.Fb ~= 2
    disp('Error: two bits per symbol required for FO estimation') 
    return
end

%% Find Pilots

P.ModFormat = P.ModFormatPilot; % this should be QPSK 
P.mu = [50e-4 40e-4 30e-4 20e-4 10e-4 5e-4 3e-4 2e-4 1e-4 1e-4 1e-4];

% Equalise whole signal for QPSK amplitudes, roughly works even when RRC'd 
[Eq, P] = QAM_RDE_fast(temp, P);
temp = Eq; 

% smooth using Pilot sequence length and get positions 
[~,idx] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,(abs(P.ErrorX(:,2:2:end)).^2+abs(P.ErrorY(:,2:2:end)).^2),floor(length(P.ErrorX)/2)));
[~,idxX] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,abs(P.ErrorX(:,2:2:end)).^2,floor(length(P.ErrorX)/2)));
[~,idxY] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,abs(P.ErrorY(:,2:2:end)).^2,floor(length(P.ErrorY)/2)));

P.PilotDelay = mod(idx-P.PilotSeqLen, P.FrameLen);
P.PilotDelayX = mod(idxX-P.PilotSeqLen, P.FrameLen);
P.PilotDelayY = mod(idxY-P.PilotSeqLen, P.FrameLen);

% extract the pilots 
pilots = temp;
pilots.Et = temp.Et(:,2*P.PilotDelay+1:2*P.PilotDelay+2*P.PilotSeqLen);

%% Perform FO measurement

disp('Applying FO correction using Pilot tones only...'); 

temp = pilots;
temp.FF = MakeTimeFrequencyArray(temp);

P.N3dB = 1e9;
P.HetMethod = 'MeanFourier';
Homodyned = Heterodyne(temp, P);

P.HetMethod = 'Measured';
FOout = Homodyned.FreqOffset;

%% Frequency Offset Removal (from original SignalIn)
temp = SignalIn; 
FP.HetMethod = 'Measured';
FP.FreqOffset=FOout;
SignalOut = Heterodyne(temp,FP);

end