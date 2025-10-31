function [SignalOut,varargout] = CPE_BlindPhaseSearch(SignalIn,P)
%% [SignalOut,P] = CPE_BlindPhaseSearch(SignalIn,P)
%
% Blind phase search from 
% Pfau et al, Hardware-Efficient Coherent.. 27,8 (2009)
%
% Inputs:
%   - NumberOfTestPhases
%   - CPELength
%   - ModFormat
%
%  Optional Wiener Filter:
%   - WienerFilter
%
%  Outputs:
%   - Signal
%   - 
% Author: Kai Shi, 2015
% Modified: Eric Sillekens, Hubert Dzieciol, March 2019

if isfield(P,'NumberOfTestPhases')
    B = P.NumberOfTestPhases;
else
    B = 2^6;% 6 for 15Gbaud
end

if isfield(P,'WienerFilter')&&P.WienerFilter==1
    P.Fb = SignalIn.Fb;
    P = WienerCoefficients(P);
    
    W = P.KFIR;
    V = 2*P.CPELength+1;
else
    V = P.CPELength*2+1;%257 127 FOR 15Gbaud
    W = ones(1,V)/V;
end

if ~isfield(P,'ModFormat')
    P.ModFormat = 'QPSK';
end

str = P.ModFormat;
if strcmp(str(end-2:end),'QAM')
    M = str2double(str(1:end-3));
elseif strcmp(str,'QPSK')
    M = 4;
else
    disp('Warning: Constellation in P.ModFormat not recognised');
    return
end

Const = qammod(0:M-1,M,'bin','UnitAveragePower',true);

SignalOut = SignalIn;
%%
[Np,Nt] = size(SignalIn.Et);
CPh = zeros(Np,Nt+V-1);
for i = 1:Np
    fprintf('Carrier phase estimation of Pol %d\n',i);
    % create parrallel copies with shifted phase
    phib = (0:B-1)*pi/2/B;
    % make sure input signal is unit power
    SignalIn.Et(i,:) = SignalIn.Et(i,:)/rms(SignalIn.Et(i,:));
    Ykb = exp(-1j*phib).'*SignalIn.Et(i,:);
    
    % create array with decisions 
    Xkb = Const(qamdemod(Ykb,M,'bin','UnitAveragePower',true)+1);
    % distance
    dkb= real(Ykb-Xkb).^2+imag(Ykb-Xkb).^2;
    
    % filter the distance for each test phase in the time domain
    [skb] = filter(W,1,[dkb,zeros(B,V-1)],[],2);
    
    %select minimum phase
    [~,minSkbInd] = min(skb);
    CPh(i,:) = phib(minSkbInd);
    
    % unwrap the phase
    p = [0 floor(0.5+(CPh(i,1:end-1)-CPh(i,2:end))*2/pi)];
    CPh(i,:) = CPh(i,:) + cumsum(p)*pi/2;
end

%% Apply estimated phase
% remove filter delay
CPh = CPh(:,(V+1)/2:end-(V-1)/2);

% apply phase
SignalOut.Et = SignalIn.Et.*exp(-1j*CPh);

% write estimated phase noise to output
P.PhaseX = CPh(1,:);
if Np>=2
    P.PhaseY = CPh(2,:);
end

varargout{1} = P;