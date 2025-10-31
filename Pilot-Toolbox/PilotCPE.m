function [CarrierPhaseRecoveredSig, Phase, P] = PilotCPE(RxFrame, P)
CarrierPhaseRecoveredSig = RxFrame;

RxPilot.Et = RxFrame.Et(:,P.IdxPilotCPE);

if ~isfield(P, 'PilotCPEMethod')
    P.PilotCPEMethod = 'PilotAided';
end

switch (P.PilotCPEMethod)
    case 'DDCPE'
        P.ModFormat = P.ModFormatPilot;
        CarrierRecovered = QAM_DD_CPE_fast_SingleThread(RxPilot, P);
        phi1 = movmean(CarrierRecovered.Phase1, 1);
        phi2 = movmean(CarrierRecovered.Phase2, 1);
        phi1(1, 1:P.CPELength+2) = (P.CPELength+1:-1:0)*(mean(phi1(1,P.CPELength+2:2*P.CPELength+2))-mean(phi1(1,P.CPELength+3:2*P.CPELength+3)))+phi1(1,P.CPELength+2);
        phi1(1, end-P.CPELength-1:end) = (1:P.CPELength+2)*(mean(phi1(1,end-2*P.CPELength-2:end-P.CPELength-2))-mean(phi1(1,end-2*P.CPELength-3:end-P.CPELength-3)))+phi1(1,end-P.CPELength-2);
        phi2(1, 1:P.CPELength+2) = (P.CPELength+1:-1:0)*(mean(phi2(1,P.CPELength+2:2*P.CPELength+2))-mean(phi2(1,P.CPELength+3:2*P.CPELength+3)))+phi2(1,P.CPELength+2);
        phi2(1, end-P.CPELength-1:end) = (1:P.CPELength+2)*(mean(phi2(1,end-2*P.CPELength-2:end-P.CPELength-2))-mean(phi2(1,end-2*P.CPELength-3:end-P.CPELength-3)))+phi2(1,end-P.CPELength-2);                
        % Linear Interpolation
        Phase(1,:) = interp1(0:P.PilotRat:P.FrameLen-P.PilotSeqLen, phi1, 0:P.FrameLen-P.PilotSeqLen);
        Phase(2,:) = interp1(0:P.PilotRat:P.FrameLen-P.PilotSeqLen, phi2, 0:P.FrameLen-P.PilotSeqLen);
    case 'PilotAided'
        PilotPhase = conj(P.TrainingCPE).*RxPilot.Et;
        PilotPhase= PilotPhase./abs(PilotPhase);
        phi1 = unwrap(angle(movmean(PilotPhase(1,:),P.CPELength)));
        phi2 = unwrap(angle(movmean(PilotPhase(2,:),P.CPELength)));            
        pMinMax = minmax(phi1-phi2);
        if pMinMax(2)-pMinMax(1) < 1
            phi1 = mean([phi1;phi2]);
            phi2 = phi1;
        end
        % Linear Interpolation
        Phase(1,:) = interp1(0:P.PilotRat:P.FrameLen-P.PilotSeqLen, phi1, 0:P.FrameLen-P.PilotSeqLen);
        Phase(2,:) = interp1(0:P.PilotRat:P.FrameLen-P.PilotSeqLen, phi2, 0:P.FrameLen-P.PilotSeqLen);
    case 'PilotAided2'
        RxPilot.Et(2,1:end-1) = RxFrame.Et(2,P.PilotSeqLen+P.ShiftCPEIdxY:P.PilotRat:end);
        RxPilot.Et(2,end) = 1;
        PilotPhase = conj(P.TrainingCPE).*RxPilot.Et;
        PilotPhase= PilotPhase./abs(PilotPhase);
        phi = reshape(PilotPhase,1,[]);
        phi = phi(1,1:end-1);
        phi = unwrap(angle(movmean(phi(1,:),P.CPELength)));
        % Linear Interpolation
        Phase(1,:) = interp1(0:floor(P.PilotRat/2):P.FrameLen-P.PilotSeqLen, phi, 0:P.FrameLen-P.PilotSeqLen);
        Phase(2,:) = Phase(1,:);
    case 'ZeroPadDDCPE'
        RxPilotZeroPad = RxFrame;
        RxPilotZeroPad.Et = zeros(size(RxFrame.Et(:, P.IdxData)));
        RxPilotZeroPad.Et(:, P.IdxPilotCPE) = RxPilot.Et;
        P.ModFormat = P.ModFormatPilot;
        CarrierRecovered = QAM_DD_CPE_fast_SingleThread(RxPilotZeroPad, P);
        Phase(1,:) = movmean(CarrierRecovered.Phase1, P.CPELength);                
        Phase(2,:) = movmean(CarrierRecovered.Phase2, P.CPELength);
end        

assert(sum(isnan(Phase(1,:)))+sum(isnan(Phase(2,:))) == 0, 'NaN in Estimated Carrier Phase!!')

CarrierPhaseRecoveredSig.Et(1,P.PilotSeqLen:end) = RxFrame.Et(1,P.PilotSeqLen:end).*exp(-1j*Phase(1,:));
CarrierPhaseRecoveredSig.Et(2,P.PilotSeqLen:end) = RxFrame.Et(2,P.PilotSeqLen:end).*exp(-1j*Phase(2,:));                

end