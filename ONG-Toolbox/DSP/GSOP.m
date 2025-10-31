function [SignalOut, varargout] = GSOP(SignalIn, varargin)
% Performs the Gram-Schmidt Orthogonalisation as shown in:
%
% Source: IEEE PTL Vol 20 No 20 oct 15 2008 pg 1733 (Fatadin)
% 
% SignalOut = GSOP(SignalIn, P)
%
% Inputs:
% SignalIn      - input signal structures
%
% Returns:
% SignalOut     - output signal structure
%
% Author: Domanic Lavery, April 2010
% Modified: M S Faruk, November 2015

SignalOut = SignalIn;
[Np, ~] = size(SignalIn.Et);

if nargin==1, P=[]; else P=varargin{1}; end

corr = ones(1,2); % preallocate
for index = 1:Np;
    ri = real(SignalIn.Et(index,:));
    rq = imag(SignalIn.Et(index,:));
    
    PI = mean(ri.^2);
   
    rho = mean(ri.*rq);

    I0 = ri/sqrt(PI);
    
    corr(index) = rho/PI;
    Qp = rq - ri*corr(index);
    PQp=mean(Qp.^2);
    Q0 = Qp/PQp;
    
    if(isfield(P, 'verbose') && (P.verbose==1))
        disp(['Correlation in polarization ' num2str(index) ': ' num2str(corr(index))]);
    end
    SignalOut.Et(index,:) = I0 + 1i*Q0;
end

%% Normalization
SignalOut = Orthonormalise(SignalOut, P);

%% Assign outputs
P.Correlation = corr;
varargout{1} = P;
end