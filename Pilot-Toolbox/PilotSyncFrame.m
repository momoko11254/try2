function [P, RxSym, Equalised] = PilotSyncFrame(Sig, P)
% Frame Synchronisation
% Equalise received data with RDE and roughly find the index of the first
% symbonl in the data frame. Take cross-correlations with received data and 
% transmitted pilot sequence to find the exact index offset.
%
% Input:
%   Sig: Signal
%       class   | struct
%       Sig.Et  | Electric field (2, :)
%   P: Parameters
%       class   | struct
%       P.ModFormatPilot
%       P.PilotSeqLen
%       P.FrameLen
%       P.TrainingSequence
%       P.TrainingCPE
% Output:
%   TxFrame: Data Frame
%       class   | double
%       size    | (2, :)
%   TxSig: Data for DAC
%       class   | complex<double>
%       size    | (2, :)
%   P: Struct of Parameters
%       P.PilotDelay        | The first index of the transmitted data frame
%       P.ErrorX            | Error function for X-pol output by RDE
%       P.ErrorY            | Error function for Y-pol output by RDE
%       P.TrainingSequence  | Updated if I/Q channels are spwapped
%       P.TrainingCPE       | Updated if I/Q channels are spwapped
%
% Author: Y. Wakayama February 2019
% Modified: E. Sillekens March 2019
% Modified: Y. Wakayama June 2019

%% RDE (CMA)
P.ModFormat = P.ModFormatPilot;
P.mu = [50e-4 40e-4 30e-4 20e-4 10e-4 5e-4 3e-4 2e-4 1e-4 1e-4 1e-4];
[Equalised, P] = QAM_RDE_fast(Sig, P);

% % compensate for filterdelay
% P.ErrorX = circshift(P.ErrorX,[0,-(P.FilterLength-1)/2-1]);
% P.ErrorY = circshift(P.ErrorY,[0,-(P.FilterLength-1)/2-1]);

%% Coarse retrieve the first symbol of the data frame
[~,idx] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,(abs(P.ErrorX(:,2:2:end)).^2+abs(P.ErrorY(:,2:2:end)).^2),floor(length(P.ErrorX)/2)));
% [~,idxX] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,abs(P.ErrorX(:,2:2:end)).^2,floor(length(P.ErrorX)/2)));
% [~,idxY] = min(cconv(ones(1,P.PilotSeqLen)/P.PilotSeqLen,abs(P.ErrorY(:,2:2:end)).^2,floor(length(P.ErrorY)/2)));
P.PilotDelay = mod(idx-P.PilotSeqLen, P.FrameLen);
% P.PilotDelayX = mod(idxX-P.PilotSeqLen, P.FrameLen);
% P.PilotDelayY = mod(idxY-P.PilotSeqLen, P.FrameLen);

%% Take cross-correlations and check correspondence for I/Q channels
RxSym = Equalised.Et(:, 2*P.PilotDelay+1:2*P.PilotDelay+2*P.PilotSeqLen);

% Calc cross-correlations
% X-Pol
TxSym = P.TrainingSequence(1,:);
[xc,  lag]          = xcorr(RxSym(1,:), kron(TxSym, [0,1]));
[xc(2,:), lag(2,:)] = xcorr(RxSym(2,:), kron(TxSym, [0,1]));
[xc(3,:), lag(3,:)] = xcorr(RxSym(1,:), kron(1i*conj(TxSym), [0,1]));
[xc(4,:), lag(4,:)] = xcorr(RxSym(2,:), kron(1i*conj(TxSym), [0,1]));
[mxc, li] = max(abs(xc),[],2);
[mmxc, chosen] = max(mxc);
IdxOffset = floor(lag(chosen, li(chosen))/2);
% Y-Pol
TxSym = P.TrainingSequence(2,:);
[xc,  lag]          = xcorr(RxSym(1,:), kron(TxSym, [0,1]));
[xc(2,:), lag(2,:)] = xcorr(RxSym(2,:), kron(TxSym, [0,1]));
[xc(3,:), lag(3,:)] = xcorr(RxSym(1,:), kron(1i*conj(TxSym), [0,1]));
[xc(4,:), lag(4,:)] = xcorr(RxSym(2,:), kron(1i*conj(TxSym), [0,1]));
[mxc, li] = max(abs(xc),[],2);
[mmxc(2), chosen(2)] = max(mxc);

% Finalise the start index of the data frame in the received data sequence
if mmxc(1) < mmxc(2)
    IdxOffset = floor(lag(chosen(2), li(chosen(2)))/2);
end
P.PilotDelay = P.PilotDelay + IdxOffset;
disp(['P.PilotDelay: ' num2str(P.PilotDelay) ' symbols']);

% Swap I/Q channels
swap =  [chosen(1)>2; chosen(2)>2];
if swap(1), disp('Swap I/Q channels on X-Pol'); end
if swap(2), disp('Swap I/Q channels on Y-Pol'); end
if sum(swap)>0
    warning('trying to swap I/Q, but Filipe disabled this because it was doing more harm than good')
    swap(1) = false;
    swap(2) = false;
    P.SwapIQ = swap;
    P.TrainingSequence(swap,:) = 1i*conj(P.TrainingSequence(swap,:));
    P.TrainingCPE(swap,:) = 1i*conj(P.TrainingCPE(swap,:));
end

end

% % Cross-correlations
% for i = 1:size(TxSym,1)
%     max_mx  = 0;
%     max_mxc = 0;
%     for j = 1:size(RxSym,1)
%         mx  = max(abs(xcorr(RxSym(j,:), kron(TxSym(i,:),[0,1]))).^2);
%         mxc = max(abs(xcorr(RxSym(j,:), kron(1i*conj(TxSym(i,:)),[0,1]))).^2);
%         if max_mx < mx, max_mx = mx; end
%         if max_mxc < mxc, max_mxc = mxc; end
%     end
%     % Swap I/Q channelsplot(lag.',abs(xc).')
%     if max_mx < max_mxc
%         P.TrainingSequence(i,:) = 1i*conj(P.TrainingSequence(i,:));
%         P.TrainingCPE(i,:) = 1i*conj(P.TrainingCPE(i,:));
%     end
% end
% 
% [xcX, lag] = xcorr(temp.Et(1,:), kron(P.TrainingSequence(1,:), [0,1]));
% xcY = xcorr(temp.Et(1,:), kron(P.TrainingSequence(2,:), [0,1]));
% [mcX, liX] = max(abs(xcX));
% [mcY, liY] = max(abs(xcY));
% 
% if mcX > mcY
%     li = liX;
% else
%     li = liY;
% end
% 
% P.PilotDelay = P.PilotDelay+floor(lag(li)/2);
