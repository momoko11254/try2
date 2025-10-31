function [BER, varargout] = SequenceBER(Sequence, DataIn, varargin)
% Correlates Sequence and DataIn, returning the average error probability.
% DataIn can be an MxN array.
%
% [BER, varargout]=SequenceBER(Sequence, DataIn ,{P})
% 
% Inputs:
% Sequence      - binary sequence
% DataIn        - seperated data sequences (one per row)
% 
% Optional Inputs:
% P.SDiscard    - discard amount at the start of each sequence
% P.EDiscard    - discard amount at the end of each sequence
% 
% Returns:
% BER           - average error probability across all sequences 
%
% Author: Domanic Lavery, December 2013

if nargin>2, P=varargin{1}; else P=[]; end

L1 = length(Sequence); % binary sequence is (currently) only one-dimensional
[W1, L2] = size(DataIn); % get the length of each Data input

nseqs = floor(L2/L1);
DataC = repmat(Sequence,[1 nseqs]);

%% xcorr of DataC and Data
seqfft = fft(DataC-mean(DataC));
Errors = zeros(W1,L2);
loc = zeros(1,W1);
for index=1:W1 % iterate over each Data input vector
    [Errors(index,:), loc(index)] = getErrors(seqfft,DataC,DataIn(index,:));
end

if(isfield(P,'SDiscard'))
    BER=mean(Errors(:,P.SDiscard:(end-P.EDiscard)),2);
else
    BER=mean(Errors,2);
end

%% Optional Outputs
if nargout>1, varargout{1}=Errors; end
if nargout>2, varargout{2}=loc; end

end

% Function to quickly cross correlate binary sequences and compute error vectors.
% N.B for speed, seqfft is precomputed.
function [Errors, loc1] = getErrors(seqfft,DataC,DataIn)
% Notes: DataC is integer number of Sequences while DataIn does not have to
% be. After cross correlation extra bits are added to DataC from a the
% begining of the Sequence to match the length of DataIn.

%% Cross correlation
xcorr1 = ifft(conj(seqfft).*(fft(DataIn(1:length(seqfft))-mean(DataIn(1:length(seqfft))))));
[~, loc1] = max(abs(xcorr1));

%% Derotate DataC
DataD = [circshift(DataC,[0 loc1-1]) DataC(loc1:(loc1+length(DataIn)-length(DataC)-1))];

%% Account for n*pi/2 phase rotations
rotvar = 1*((angle(xcorr1(loc1)))>0);

%% xor and BER calculation
Errors = xor(DataD,rotvar*(~DataIn)+(~rotvar)*DataIn); % if ~rotvar, Errors = xor(DataC,Data2); else Errors = xor(DataC,~Data2); end
end