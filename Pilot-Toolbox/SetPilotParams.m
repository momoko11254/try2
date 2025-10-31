PauseSec = 0.1;
P.FilterLength = 31;
P.CPELength = 5;
P.RPElength = 31;
P.ModFormatPilot = 'QPSK';         % Modulation format for pilot
P.PatternLength = 19;              % Patternlength
P.FrameLen = 2^16;                % Frame Length = Pilot length + Payload lenght
P.PilotSeqLen = 1024;              % Pilot Sequence Lenth
P.PilotRat = 32;                   % Pilot insertion rate
P.SDiscard = 1;                    % Start discard samples
P.EDiscard = 0;                    % End discard samples
P.OH = PilotOH(P);                 % Overhead of pilot symbols
P.ShiftIdxY = 0;                   % Shift the CPE pilot position of Y-Pol.
P.PilotCPEMethod = 'PilotAided';   % 'DDCPE', 'PilotAided', 'ZeroPadDDCPE'

