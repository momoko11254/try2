function [Idx, IdxData, IdxPilot, IdxPilotCPE] = PilotFrameIdx(frame_len, pilot_seq_len, pilot_ins_rat)
    Idx = 1:frame_len;
    IdxPilot_seq = Idx < pilot_seq_len;
    if pilot_seq_len == 0
        IdxData = ~IdxPilot_seq;
    end
    if pilot_ins_rat == 0
        IdxPilot = IdxPilot_seq;
        IdxPilotCPE = IdxPilot;
    else
        if mod((frame_len - pilot_seq_len), pilot_ins_rat) ~= 0
            assert(mod((frame_len - pilot_seq_len), pilot_ins_rat) ~= 0, 'Frame lenght without pilot sequence divided by pilot rate needs to be an integer.')
        end
        %% Payload + Pilot
        IdxData = (mod((Idx - pilot_seq_len), pilot_ins_rat) ~= 0) & (Idx - pilot_seq_len > 0);
        %% Pilot + Payload
        % IdxData = (mod((Idx-1 - pilot_seq_len), pilot_ins_rat) ~= 0) & (Idx - pilot_seq_len > 0);
        %%
        IdxPilot = ~IdxData;
        IdxPilotCPE = IdxPilot;
        IdxPilotCPE(1,1:pilot_seq_len-1) = ~IdxPilot(1,1:pilot_seq_len-1);
%         IdxPilotCPE(1,1:pilot_seq_len) = ~IdxPilot(1,1:pilot_seq_len);
    end
end
