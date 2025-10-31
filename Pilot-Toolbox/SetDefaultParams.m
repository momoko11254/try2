%% Signal Fundamentals
P.Fb = 15*1e9;                         % Symbol rate (Baud rate)
P.ModFormatData = '16QAM';             % Modulation format for payload
P.M = ReturnModOrder(P.ModFormatData); % Number of constellation points
P.PatternLength = 16;                  % Patternlength
P.FrameLen = 2^P.PatternLength;        % Frame Length
P.RandData = 1;                        % 1: random data instead of PRBS
P.SDiscard = 3e4;                      % Start discard samples
P.EDiscard = 1e5;                      % End discard samples
P.RandiDataLength = 16;                % Random data length
P.ModFormat = P.ModFormatData;         % Modulation format
P.ModFormatPilot = P.ModFormatData;    % Modulation format for pilot
P.PilotSeqLen = 0;                     % Pilot Sequence Lenth
P.PilotRat = 0;                        % Pilot insertion rate
P.OH = 0;                              % Overhead
P.InvJones = 0;                        % Invert Jones Matrix
P.Fc = 1550e-9;                        % Centre wavelength
%% RDE Options
P.FilterLength = 31;                   % Equaliser AFIR length
%% CPE options
P.CPELength = 31;
P.NTapsFFELength = P.CPELength;        % Half Number of CPE filter taps
P.PhaseRotation = 1;
%% RRC Options
P.RRCFilter = 1;                       % 1: RRC filter
P.RollOff = 0.01;                      % RRC rolloff factor
P.RRCAtt = 30;                         % Stop band attenuation for RRC filter (dB)
P.RRCType = 'Att';                     % Select RRC implememtaion (Ideal, Taps, Att)
