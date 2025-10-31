function [BitSym, P] = PilotTXRX_SymAlign(RxSymsIn, P)

% Function to align the recevied symbols and the transmitted symbols
% Inputs:   RxSymsIn - Received symbols (straight after CPE DSP block)
%           P.ModFormat - modulation format
%           P.Sdiscard = number of symbols to discard at start of sequence
%           P.Ediscard - number of symbols to discard at end of sequence
% Outputs:  RxSymsOut - Aligned received symbols (contains transmitted symbols and bits and received symbols)
% Author:   Robert Maher (December 2014)
% Modified: Yuta Wakayama (February 2019)

P.NumSym = length(RxSymsIn.X);                                            	% Number of symbols
[BitSym, P] = PilotTXSymGen(P);                                           % Generate transmitted bits and symbols

TI = real(BitSym.Symbols);                                                 % Transmitted symbols - I
TQ = imag(BitSym.Symbols);                                                 % Transmitted symbols - Q

RxSymsX = RxSymsIn.X;                                                       % Received symbols XPOL
RxSymsY = RxSymsIn.Y;                                                       % Received symbols YPOLz
RXI = real(RxSymsX(P.SDiscard:length(TI)+P.SDiscard-1));                   % Truncate to length equal to tranmitted symbols
RXQ = imag(RxSymsX(P.SDiscard:length(TI)+P.SDiscard-1));                   % Truncate to length equal to tranmitted symbols
RYI = real(RxSymsY(P.SDiscard:length(TI)+P.SDiscard-1));                   % Truncate to length equal to tranmitted symbols
RYQ = imag(RxSymsY(P.SDiscard:length(TI)+P.SDiscard-1));                   % Truncate to length equal to tranmitted symbols

%% Check X-POL Constellation
[XC1,~] = max(abs(ifft(fft(RXI).*conj(fft(TI(1,:))))));                                    % Cross correlation of I component - XPOL
[XC2,~] = max(abs(ifft(fft(RXQ).*conj(fft(TI(1,:))))));                                    % Cross correlation of I component - XPOL

if XC1<XC2
    disp('Rotate I/Q in XPOL')
    [RXQ,RXI] = deal(RXI,RXQ);
end

%% Check Y-POL Constellation
[YC1,~] = max(abs(ifft(fft(RYI).*conj(fft(TI(2,:))))));                                    % Cross correlation of I component - XPOL
[YC2,~] = max(abs(ifft(fft(RYQ).*conj(fft(TI(2,:))))));                                    % Cross correlation of I component - XPOL

if YC1<YC2
    disp('Rotate I/Q in YPOL')
    [RYQ,RYI] = deal(RYI,RYQ);
end

XCorrI = ifft(fft(RXI).*conj(fft(TI(1,:))));                                     % Cross correlation of Q component - XPOL
XCorrQ = ifft(fft(RXQ).*conj(fft(TQ(1,:))));                                     % Cross correlation of Q component - XPOL

YCorrI = ifft(fft(RYI).*conj(fft(TI(2,:))));                                     % Cross correlation of I component - YPOL
YCorrQ = ifft(fft(RYQ).*conj(fft(TQ(2,:))));                                     % Cross correlation of Q component - YPOL

%% Find index of cross-correlation maximum
[~, indXI] = max(abs(XCorrI));                                              % Find cross correlation peak
[~, indXQ] = max(abs(XCorrQ));                                              % Find cross correlation peak

[~, indYI] = max(abs(YCorrI));                                              % Find cross correlation peak
[~, indYQ] = max(abs(YCorrQ));                                              % Find cross correlation peak

%% Test for inverted data
XCorrImm = minmax(XCorrI);                                                  % Find minimum and maximum values of cross correlation
XCorrQmm = minmax(XCorrQ);                                                  % Find minimum and maximum values of cross correlation

YCorrImm = minmax(YCorrI);                                                  % Find minimum and maximum values of cross correlation
YCorrQmm = minmax(YCorrQ);                                                  % Find minimum and maximum values of cross correlation

if abs(XCorrImm(1)) > abs(XCorrImm(2))
    RXI = RXI*-1;
end

if abs(XCorrQmm(1)) > abs(XCorrQmm(2))
    RXQ = RXQ*-1;
end

if abs(YCorrImm(1)) > abs(YCorrImm(2))
    RYI = RYI*-1;
end

if abs(YCorrQmm(1)) > abs(YCorrQmm(2))
    RYQ = RYQ*-1;
end

%% Circularly shift data
RXI_Shift = circshift(RXI, [0 -indXI+1]);                                   % Align received in phase component (XPOL)
RXQ_Shift = circshift(RXQ, [0 -indXQ+1]);                                   % Align received quadrature phase component (XPOL)

RYI_Shift = circshift(RYI, [0 -indYI+1]);                                   % Align received in phase component (YPOL)
RYQ_Shift = circshift(RYQ, [0 -indYQ+1]);                                   % Align received quadrature phase component (YPOL)

%% Reconstruct Received Signals
BitSym.Symbols(3, :) = RXI_Shift+1i*RXQ_Shift;
BitSym.Symbols(4, :) = RYI_Shift+1i*RYQ_Shift;