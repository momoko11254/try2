
%% Convert SNR to Q^2 (and vice versa) factor in dB or the other way around
%% for a given square M-QAM modulation

%Assumptions:
% Circ. Symmetric Gaussian Noise 
% Q to SNR is approximated for high SNRs values


% INPUTS
% M - modulation order
% X - matrix containing BER values or Q values
% Mode - 'SNR' or 'Q' to specify type of input values. If 'Q' values need
% to be specified in dB

% OUTPUTS
% Y - matrix containing converted values

function Y= SNRtoQ (X,M,Mode)

if isequal(Mode,'SNR')
 
 ber=berawgn((X-5*log10(M)),'qam',M);
 Y=sqrt(2)*erfcinv(2*ber);
 Y=20*log10(Y);
    
elseif isequal(Mode, 'Q')
 
 Y=10.^(X/20);
 BER=1/2*erfc(Y/sqrt(2));
 snr=2*(M-1)*log2(M)/(3*log2(M))*erfcinv(BER*sqrt(M)*log2(sqrt(M))/(sqrt(M)-1)).^2;
 Y=10*log10(snr);
 
else
    error('Wrong input specifier');
end


end