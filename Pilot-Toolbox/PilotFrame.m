function P = PilotFrame(P)
% This function generates a data frame with and without pilot symbols.
% If P.PilotBasedDSP is True or 1, this function generates a data frame
% with pilot symbols.
%
% Input:
%   P: Struct of Parameters
%       P.ModFormatPilot
%       P.ModFormatData
%       P.FrameLen
%       P.PilotSeqLen
%       P.PilotRat
%       P.PilotBasedDSP
%       P.ShiftIdxY
% Output:
%   Signal: Struct of Signal
%       class   | double
%       size    | (2, :)
%   P: Struct of Parameters
%       P.TxData 	| Transmitted symbols of payload
% Output (optional):
%   varargout{1}: Figure Object
%
% Author: Y. Wakayama June 2019

%% Generate Complex Pilot
P.ModFormat = P.ModFormatPilot;
if P.RandPilot == 0
    % Load binary sequence
%     PilotSequence = importdata(['pilot_sequence' num2str(P.PatternLength) '.mat']);
    PilotSequence = importdata(['sequence' num2str(P.PatternLength) '.mat']);
elseif P.RandPilot == 1
    % Generate binary random sequence
    PilotSequence = randi([0 1], 2, 2^P.PatternLength);
elseif  P.RandPilot == 2
    % Generate binary pseudorandom sequence (using mex)
    if ~isfield(P,'pilotSeed'); P.pilotSeed = 1; end
    PilotSequence = prbs_mex(2^(P.PatternLength)-1, P.PatternLength, P.pilotSeed);
end
[Pilot, ~] = QAM_Generator(P, PilotSequence);

%% Generate Complex Signal
P.ModFormat = P.ModFormatData;
if P.RandData == 0
    % Load binary sequence
%     DataSequence = importdata(['data_sequence' num2str(P.PatternLength) '.mat']);
    DataSequence = importdata(['sequence' num2str(P.PatternLength) '.mat']);
elseif P.RandData == 1
    % Generate binary random sequence
    DataSequence = randi([0 1], 2, 2^P.PatternLength);
elseif  P.RandData == 2
    % Generate binary pseudorandom sequence (using mex)
    if ~isfield(P,'dataSeed'); P.dataSeed = 1; end
    DataSequence = prbs_mex(2^(P.PatternLength)-1, P.PatternLength, P.dataSeed);
end
[Signal, P] = QAM_Generator(P, DataSequence);

%% Calculate frame indeces & compose a data frame with pilots
%     Signal.Et = Signal.Et(:,1:P.FrameLen);
%     Pilot.Et = Pilot.Et(:,1:P.FrameLen);
%     [P.Idx, P.IdxData, P.IdxPilot, P.IdxPilotCPE] = PilotFrameIdx(P.FrameLen, P.PilotSeqLen, P.PilotRat);
%     Signal.Et(:,P.IdxPilot) = Pilot.Et(:,P.IdxPilot);

[P.Idx, P.IdxData, P.IdxPilot, P.IdxPilotCPE] = ...
    PilotFrameIdx(P.FrameLen, P.PilotSeqLen, P.PilotRat);
Npayload = sum(P.IdxData);

if P.PilotBasedDSP
    check = ((P.FrameLen-P.PilotSeqLen)/P.PilotRat)*(P.PilotRat-1);
    assert(Npayload==check, 'Wrong Pilot Parameters!!')

    Npilotcpe = sum(P.IdxPilotCPE)-1;
    % This can be written as Npilotcpe = Npayload/(P.PilotRat-1);
    check = ((P.FrameLen-P.PilotSeqLen)/P.PilotRat);
    assert(Npilotcpe==check, 'Wrong Pilot Parameters!!')
    
    Payload.Et = Signal.Et(:,1:Npayload);
%     P.TxData = Payload.Et; % Transmitted data array
    PilotSeq.Et = Pilot.Et(:,1:P.PilotSeqLen);
    PilotCPE.Et = Pilot.Et(:,P.PilotSeqLen+1:P.PilotSeqLen+Npilotcpe);
    
    % Shift Y-pol.
    Payload.Et(2,:) = circshift(Payload.Et(2,:), P.ShiftCPEIdxY, 2);
    
    Ax = reshape(Payload.Et(1,:), P.PilotRat-1, Npayload/(P.PilotRat-1));
    Ay = reshape(Payload.Et(2,:), P.PilotRat-1, Npayload/(P.PilotRat-1));
    Bx = cat(1, Ax, PilotCPE.Et(1,:));
    By = cat(1, Ay, PilotCPE.Et(2,:));
    DataFrameX = [PilotSeq.Et(1,:) reshape(Bx, 1, P.FrameLen-P.PilotSeqLen)];
%     DataFrameY = [PilotSeq.Et(2,:) reshape(By, 1, P.FrameLen-P.PilotSeqLen)];
    DataFrameY = [PilotSeq.Et(2,:) circshift(reshape(By, 1, P.FrameLen-P.PilotSeqLen), -P.ShiftCPEIdxY, 2)];
    Signal.Et = [DataFrameX; DataFrameY];
else
    Signal.Et = Signal.Et(:,1:Npayload);
end
P.TxFrame = Signal.Et;

