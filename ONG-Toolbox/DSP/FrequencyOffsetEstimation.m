function [FreqOffset] = FrequencyOffsetEstimation(SignalIn, P)
% FrequencyOffsetEstimation is a function that pre-equalizes the signal and
% uses FrequencyOffsetRemoval to estimate the frequency. This is useful
% in combination with matched filtering.
%
% [FreqOffset] = FrequencyOffsetEstimation(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
%
% Returns:
% SignalOut         - Output signal structure
%
% Author: Milen Paskov, Deccember 2013
%
% See also QAM_RDE_FAST FREQUENCYOFFSETREMOVAL

%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=1))
    disp('Estimating Frequency Offset for RRC');
end

%% CMA Equalisation
P.ModFormat = 'QPSK';
P.mu = [5e-3];
[~, P] = QAM_RDE_fast(PreEQ, P);

if (false)
    Hxx = P.Taps(1,:);
    Hxy = P.Taps(2,:);
    Hyx = fliplr(-1*conj((Hxy)));
    Hyy = fliplr(1*conj((Hxx)));
    P.Taps = [Hxx; Hxy; Hyx; Hyy];
end

P.mu = [5e-3 3e-3 1e-3];
[Equalised, P] = QAM_RDE_fast(SignalIn, P);
if(isfield(P, 'verbose') && (P.verbose>0)); disp(' ');end

%% RDE Equalisation
% P.ModFormat = '16QAM';
% P.mu = [5e-3 4e-3 3e-3 1e-3 3e-4];
% [Equalised, P] = QAM_RDE_fast(SignalIn, P);
% if(isfield(P, 'verbose') && (P.verbose>0)); disp(' ');end
temp = Equalised;

%% Frequency Offset Removal
[~, P] = FrequencyOffsetRemoval(temp, P);
FreqOffset = P.FreqOffset;
end