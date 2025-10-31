function [out] = BERtoQ(input, varargin)
% Converts bit error rate to Q^2-factor in dB
% Run with one parameter does forward conversion
% Run with two parameters does inverse conversion (Q in dB to BER)
%
% forward - ber2q( input ):
% 0 < input < 0.5
%
% inverse - ber2q( input , -1 ):
% -inf < input < inf
%
% Author: Domanic Lavery, December 2013

if nargin==2
    disp('inverse calulation (Q^2 [dB] to BER)')
    out = 0.5*erfc((1/sqrt(2))*10.^(input/20));
else
    disp('BER to Q^2 [dB]')
    if(sum(sum((input<0)|(input>0.5))))
        disp('input BER out of bounds');
    else
        out = 20*log10(sqrt(2)*erfcinv(2*input));
    end
end
end