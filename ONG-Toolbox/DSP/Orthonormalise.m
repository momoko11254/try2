function SignalOut = Orthonormalise(SignalIn, varargin)
% Orthogonalises the four signal quadratures (XI, XQ, YI, YQ)
% in terms of average power and removes any DC-offset.
% 
% SignalOut = Orthonormalise(SignalIn, varargin)
% 
% Inputs:
% SignalIn          - Signal structure
%
% Returns:
% SignalOut         - Output signal structure
% 
% Author: 

SignalOut = SignalIn;

StrRe1 = real(SignalIn.Et(1,:));  % Individual Signal Streams
StrIm1 = imag(SignalIn.Et(1,:));
StrRe2 = real(SignalIn.Et(2,:));
StrIm2 = imag(SignalIn.Et(2,:));

%% Remove mean
L = length(StrRe1);
StrRe1 = StrRe1-sum(StrRe1)/L;    % DC Removal
StrIm1 = StrIm1-sum(StrIm1)/L;
StrRe2 = StrRe2-sum(StrRe2)/L;
StrIm2 = StrIm2-sum(StrIm2)/L;

%% Normalise to unit power
L = 1/L;
StrRe1 = StrRe1/sqrt(L*sum(abs(StrRe1).^2));  % PRMS = 1/sqrt(2)
StrIm1 = StrIm1/sqrt(L*sum(abs(StrIm1).^2));
StrRe2 = StrRe2/sqrt(L*sum(abs(StrRe2).^2));
StrIm2 = StrIm2/sqrt(L*sum(abs(StrIm2).^2));

%% Separate I&Q Normalisation
SignalOut.Et(1,:) = StrRe1+1i*StrIm1;   % Output
SignalOut.Et(2,:) = StrRe2+1i*StrIm2;

SignalOut.Et(1,:) = SignalOut.Et(1,:)/sqrt(L*sum(abs(SignalOut.Et(1,:)).^2));   % Output
SignalOut.Et(2,:) = SignalOut.Et(2,:)/sqrt(L*sum(abs(SignalOut.Et(2,:)).^2));   % Output

%% Normalize when you operate at 2Sa/symbol
% TODO: What is the power when there are more than 2Sa/Symbol
% At 1Sa/Symbol this should not be run
if SignalIn.Fs/SignalIn.Fb == 2
    % At 2Sa/symbol the transition has half the power of the symbol
    SignalOut.Et(1,:) = SignalOut.Et(1,:)/sqrt(3/2);
    SignalOut.Et(2,:) = SignalOut.Et(2,:)/sqrt(3/2);
end