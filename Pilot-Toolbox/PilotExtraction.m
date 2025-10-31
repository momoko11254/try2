function [SigPilot, SigCPE, P] = PilotExtraction(SignalIn, P)
% Calculate indices for extracting pilot sequences and CPE symbols from
% SignalIn. 
%
% Input:
%   SiganlIn: Signal
%       class   | struct
%       SignalIn.Et  | Electric field (2, :)
%   P: Parameters
%       class   | struct
%       P.PilotDelay
%       P.FilterLength
%       P.FrameLen
%       P.PilotSeqLen
% (optional):
%       P.ShiftCPEIdxY  | Shift index for CPE symbols on Y-Pol
% Output:
%   SigPilot: Extracted pilot sequence from SignalIn
%       class   | double
%       size    | (2, :)
%   SigCPE: Extracted CPE symbols from SignalIn
%       class   | complex<double>
%       size    | (2, :)
%   P: Struct of Parameters
%       P.TapCor           | Delay corresponding to tap filtering length
%       P.ExIdxFrameX      | Index for extracting a data frame on X-Pol
%       P.ExIdxFrameY      | Index for extracting a data frame on Y-Pol
%       P.ExIdxPilSeqX     | Index for extracting a pilot sequence on X-Pol
%       P.ExIdxPilSeqY     | Index for extracting a pilot sequence on Y-Pol
%       P.ExIdxCPEblocksX  | Index for extracting CPE symbols on X-Pol
%       P.ExIdxCPEblocksY  | Index for extracting CPE symbols on Y-Pol
%
% Author: Y. Wakayama and E. Sillekens March 2019
% Modified: Y. Wakayama June 2019

P.TapCor = (2*ceil(P.FilterLength/2))-1;  % Filter Length

% Index for data frame
idx0 = (P.PilotDelay+1)*2+1;
idx1 = (P.PilotDelay+P.FrameLen)*2;
P.ExIdxFrameX = idx0:idx1;
P.ExIdxFrameY = idx0:idx1;

% Index for pilot sequence
idx0 = (P.PilotDelay+1)*2-P.TapCor;
idx1 = (P.PilotDelay+P.PilotSeqLen)*2;
P.ExIdxPilSeqX = idx0:idx1;  
P.ExIdxPilSeqY = idx0:idx1;

% Index for CPE symbols
idx0 = (P.PilotDelay+P.PilotSeqLen)*2;
step = P.PilotRat*2;
idx1 = (P.PilotDelay+P.FrameLen)*2;
P.ExIdxCPEblocksX = idx0:step:idx1;
P.ExIdxCPEblocksY = idx0:step:idx1;
if isfield(P,'ShiftCPEIdxY') && P.ShiftCPEIdxY~=0
    P.ExIdxCPEblocksY = idx0+P.ShiftCPEIdxY*2:step:idx1;
    P.ExIdxCPEblocksY = [P.ExIdxCPEblocksY (P.PilotDelay+P.FrameLen)*2];
end

% Pilot Sequence
SigPilot = SignalIn;
SigPilot.Et = SignalIn.Et(1, P.ExIdxPilSeqX);
SigPilot.Et(2,:) = SignalIn.Et(2, P.ExIdxPilSeqY);

% CPE symbols
SigCPE = SignalIn;
SigCPE.Et = SignalIn.Et(1, P.ExIdxCPEblocksX);
SigCPE.Et(2,:) = SignalIn.Et(2, P.ExIdxCPEblocksY);

end