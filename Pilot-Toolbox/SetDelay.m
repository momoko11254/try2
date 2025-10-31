%% Skew

% ECOC19, April 2019
P.DelayXIQ = 0.8;
P.DelayYIQ = 1.4;
P.DelayXY  = -670;

if P.LoadWaveforms==3
    P.DelayXIQ = 0;
    P.DelayYIQ = 0;
    P.DelayXY  = 0;
end
