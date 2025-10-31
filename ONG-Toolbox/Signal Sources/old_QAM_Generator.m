function [SignalOut, varargout] = QAM_Generator(P,varargin)
% Generates arbitrary square QAM.
% Sequence is either a 1xN binary sequence (which is used multiple
% times with equal decorrelation) or a Np*log2(M)xN matrix of binary
% sequences which are mapped to the Np*log2(M) bits of this signal.
% N.B. For convenience, actual operation always generates for Np=2, then
% discards one polarisation.
% 
% Signal=QAM_Generator(Sequence,P)
% 
% Inputs:
% P.M           - Number of constellation points
% 
% Optional Inputs:
% Sequence      - binary bit sequence used for decoding each quadrature
%                 (default is PRBS of 2^(P.PatternLength)-1)
% 
% Returns:
% SignalOut     - Output QAM-modulated signal structure
% 
% Author: Domanic Lavery, December 2013
% 
% See also BER_QAM

str = P.ModFormat;
if strcmp(str(end-2:end),'QAM')
    P.M = str2double(str(1:end-3));
else
    switch str
        case 'QPSK'
            P.M = 4;
        otherwise
            error([str ' not a recognised modulation format'])
    end
end

%% Generate or use a binary sequence
if nargin>1
    Sequence = varargin{1};
else
    Sequence = prbs_mex(2^(P.PatternLength)-1,P.PatternLength,1); % Generate binary pseudorandom sequence (using mex)
end


%%
if ~isfield(P,'Np'), P.Np=2; end % Dual polarisation by default

bitpersym = 2*log2(P.M); % sum of bits per symbol on both polarizations
Nb = length(Sequence);

%% Input verification
if floor(log2(P.M)/2)~=log2(P.M)/2, warning([num2str(P.M) ' constellation points cannot be square'],'square QAM warning'); end

%%
Data = zeros(bitpersym,Nb);
for index = 1:bitpersym
    Data(index,:) = circshift(Sequence,[0 floor(index*(2^P.PatternLength)/(bitpersym+1))]);
end

%% QAM mod on odd indices for pol1 and even for pol2
DataX = zeros(1,Nb*log2(P.M));
DataY = zeros(1,Nb*log2(P.M));
for index = 1:log2(P.M)
    DataX(index:log2(P.M):(Nb*log2(P.M))) = Data(2*index-1,:);
    DataY(index:log2(P.M):(Nb*log2(P.M))) = Data(2*index,:);
    % Possible workaround if streams are correlated
%     DataX(index:log2(P.M):(Nb*log2(P.M))) = Data(index,:);
%     DataY(index:log2(P.M):(Nb*log2(P.M))) = Data(2*log2(P.M)-index+1,:);
end

%% Bit-to-integer mapping
% Convert the bits in x into log2(M)-bit integers.
hBitToInt = comm.BitToInteger(log2(P.M));

xsym = step(hBitToInt,DataX.');
ysym = step(hBitToInt,DataY.');

%% Integer-to-symbol mapping
hQAMMod = comm.RectangularQAMModulator('ModulationOrder',P.M,'NormalizationMethod','Average power');

%% Output symbols
SignalOut.Et(1,:) =          step(hQAMMod, xsym);
SignalOut.Et(2,:) = (P.Np-1)*step(hQAMMod, ysym);

%% Add modulation parameters to signal struct
if isfield(P,'Fb')
    SignalOut.Fb = P.Fb;
    SignalOut.Fs = P.Fb;
    SignalOut.Fc = P.Fc;
end

P.Sequence = Sequence;
varargout{1} = P;
end