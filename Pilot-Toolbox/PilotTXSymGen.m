function [BitSym, P] = PilotTXSymGen(P)
% Function to generate transmitted bits and symbols
% Inputs:   Nb - number of symbols
%           P.M - modulation order
%           P.Patternlength - PRBS length
% Outputs:  BitSym.Bits - tranmitted bits
%           BitSym.Symbols - transmitted symbols
% Author: Robert Maher December 2014
% Added pilot handling: Yuta Wakayama (February 2019)
% Modified: Yuta Wakayama (June 2019)

Symbols = P.TxFrame(:,P.IdxData);

% if strcmp(str,'shaped1024QAM')
% Decode on this constellation
xsequence_long = genqamdemod(Symbols(1,:), P.Conste);
ysequence_long = genqamdemod(Symbols(2,:), P.Conste);
try
    hIntToBit = comm.IntegerToBit(log2(P.M));
    BitsX = step(hIntToBit, xsequence_long.');
    BitsY = step(hIntToBit, ysequence_long.');
catch
    BitsX = int2bit(xsequence_long.', log2(P.M));
    BitsY = int2bit(ysequence_long.', log2(P.M));
end

% else
% % Decode on this constellation
% hQAMDemod = comm.RectangularQAMDemodulator('ModulationOrder',P.M,'NormalizationMethod','Average power');
% xsequence_long = step(hQAMDemod, Symbols(1,:).');
% ysequence_long = step(hQAMDemod, Symbols(2,:).');
% hIntToBit = comm.IntegerToBit(log2(P.M));
% BitsX = step(hIntToBit, xsequence_long);
% BitsY = step(hIntToBit, ysequence_long);
% end
% % Decode on this constellation
% hIntToBit = comm.IntegerToBit(log2(P.M));
% xsequence_long = genqamdemod(Symbols(1,:), P.Conste);
% ysequence_long = genqamdemod(Symbols(2,:), P.Conste);
% BitsX = step(hIntToBit, xsequence_long.');
% BitsY = step(hIntToBit, ysequence_long.');

BitsX = reshape(BitsX, [log2(P.M), length(BitsX)/log2(P.M)]);
BitsY = reshape(BitsY, [log2(P.M), length(BitsY)/log2(P.M)]);
Bits = cat(3, BitsX, BitsY);
%%
BitSym.Bits = Bits;
BitSym.Symbols = Symbols;