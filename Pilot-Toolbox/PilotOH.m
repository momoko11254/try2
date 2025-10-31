function OH = PilotOH(P)
[~, ~, IdxPilot, ~] = PilotFrameIdx(P.FrameLen, P.PilotSeqLen, P.PilotRat);
OH = sum(IdxPilot)/P.FrameLen;
end