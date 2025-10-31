function Fs = FindFs(P)
%% Fs = FindFs(P) 
% finds the best samplerate for P.minFs <= Fs <= P.maxFs for P.Fb
% constraint by P.Patternlength = k* P.blocksize with $k\in\mathbb{N}$
%
% Eric Sillekens, Nov 2016

% minimum and maximum number of blocks that fit the blocklength
tSequenceLength = 1/P.Fb*pow2(P.PatternLength);
minNoBlocks = round(tSequenceLength/(1/P.minFs)/P.blocksize);
maxNoBlocks = round(tSequenceLength/(1/P.maxFs)/P.blocksize);

% calculate the required downsampling for every posible number of blocks
possibleNoBlocks = minNoBlocks:maxNoBlocks;
downSampleRate = zeros(maxNoBlocks-minNoBlocks+1,1);
for i = 1:(maxNoBlocks-minNoBlocks+1)
    Fs = P.Fb*possibleNoBlocks(i)*128/pow2(P.PatternLength);
    [downSampleRate(i),~] = rat(Fs/P.Fb,1e-7);
end

% use the smallest value
[~,i] = min(downSampleRate);
Fs = possibleNoBlocks(i)*P.blocksize/tSequenceLength;

