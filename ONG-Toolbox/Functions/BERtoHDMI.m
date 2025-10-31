function HDMI = BERtoHDMI(p)
% Compute BSC mutual information
% HDMI = BERtoHDMI(BER)
%
% 1 + p*log2(p) + (1-p)*log2(1-p)
%
% where p is the error probability (BER)

HDMI = (1-p).*log2(2*(1-p))+p.*log2(2*p);