function [ SignalOut ] = ExtractSymbolsFixed( SignalIn )

% EXTRACTSYMBOLS Extracts the symbols from signal struct

SignalOut = SignalIn;

pol1 = SignalOut.Et(1,2:2:end); % even samples are symbols
pol2 = SignalOut.Et(2,2:2:end);

SignalOut.Tr(1,:) = SignalOut.Et(1,1:2:end); % odd samples are transitions
SignalOut.Tr(2,:) = SignalOut.Et(1,1:2:end);

SignalOut.Et = pol1;
SignalOut.Et(2,:) = pol2;

SignalOut.TT = SignalOut.TT(2:2:end); % update temporal resolution
SignalOut.dT = SignalOut.dT*2;
SignalOut.Ns = 1;

end

