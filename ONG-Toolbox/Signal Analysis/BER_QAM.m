function [SignalOut, Pout] = BER_QAM(SignalIn, P, varargin)
% Calculates the BER for arbitrary square QAM.
% N.B. For convenience, actual operation always generates for Np=2.
% 
% [SignalOut,Pout]=BER_QAM(SignalIn,P,Sequence)
%
% Inputs:
% SignalIn      - input signal structure
% P.M           - Number of constellation points
% 
% Optional Inputs:
% Sequence      - binary bit sequence used for decoding each quadrature
%                 (default is PRBS of 2^(P.PatternLength)-1)
% 
% Returns:
% SignalOut     - output signal structure
% 
% Author: Domanic Lavery, December 2013
% 
% See also QAM_GENERATOR

SignalOut = SignalIn;

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
if nargin>2
    Sequence = varargin{1};
else
    Sequence = prbs_mex(2^(P.PatternLength)-1,P.PatternLength,1); % Generate binary pseudorandom sequence (using mex)
end


%%
if ~isfield(P,'Np'), P.Np=2; end % Dual polarisation by default

%% Input verification
if floor(log2(P.M)/2)~=log2(P.M)/2, warning([num2str(P.M) ' constellation points cannot be square'],'square QAM warning'); end

%% Symbol-to-Integer Mapping
hQAMDemod = comm.RectangularQAMDemodulator('ModulationOrder',P.M,'NormalizationMethod','Average power');

% Decode on this constellation
xsequence_long = step(hQAMDemod, SignalIn.Et(1,:).');
ysequence_long = step(hQAMDemod, SignalIn.Et(2,:).');


%% Integer-to-Bit Mapping
% Convert the log2(M)-bit integers to a binary stream.
hIntToBit = comm.IntegerToBit(log2(P.M));

xbits = step(hIntToBit,xsequence_long);
ybits = step(hIntToBit,ysequence_long);

%% Extract bit sequences
xsequence=zeros(log2(P.M),length(xbits)/log2(P.M));
ysequence=zeros(log2(P.M),length(ybits)/log2(P.M));
for index = 1:log2(P.M)
    xsequence(index,:)=xbits(index:log2(P.M):end);
    ysequence(index,:)=ybits(index:log2(P.M):end);
end

[BERX, ErrorsX,locX] = SequenceBER(Sequence,xsequence,P);
if P.Np~=1
    [BERY, ErrorsY, locY] = SequenceBER(Sequence,ysequence,P);
else
    BERY=BERX; ErrorsY=ErrorsX; locY=locX;
end

Pout.BERvec = [BERX;BERY]';
Pout.BERX = mean(BERX);
Pout.BERY = mean(BERY);
Pout.BER = mean(Pout.BERvec);
Pout.Errors = [ErrorsX; ErrorsY];
locX = mod(locX,length(Sequence));
locY = mod(locY,length(Sequence));
Pout.Delays = [locX locY];
Pout.Delays = Pout.Delays-min(Pout.Delays);

if(sum(Pout.Delays<P.FilterLength/2)>1)
    disp('**********FALSE LOCKING************');
end
end