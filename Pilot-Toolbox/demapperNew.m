function LLR =  demapperNew(C,X,Y,Ik1,Ik0,flag_demapper)
% This function computes L-values for a given constellation C based on the
% channel observations Y. The function returns a matrix of m times Ns LLRs.
% The input vectors are:
%
% C     : Column vector of M=2^m constellation symbols
% X     : Column vector of complex transmitted symbols
% Y     : Column vector of complex received symbols
% Ik1   : M/2 times m matrix with pointers to the symbols in C labeled with
% a one in a given bit position.
% Ik0   : M/2 times m matrix with pointers to the symbols in C labeled with
% a zero in a given bit position.
% If flag_demapper==0, then exact LLR calculation (Sum-Exp) is performed.
% If flag_demapper==1, then approximated LLR calculation (Max-Log) is
% performed
%
% Alex Alvarado
% November 2015

Ns = size(Y,1);             % Number of received symbols
M = size(C,1);              % Constellation size
m = log2(M);                % Number of bits per symbol
VarZ = var(Y-X);            % Noise variance

LLR = zeros(m,Ns);          % LLR output matrix
% Ymat = repmat(Y,1,M/2);     % For LLR calculation
for k = 1:m
    Cmat1 = C(Ik1(:,k)).';
    Cmat0 = C(Ik0(:,k)).';
    if flag_demapper==0 % Sum-Exp
        if exist('pdist2')
            num = sum(exp(-pdist2([real(Cmat1.'),imag(Cmat1.')],[real(Y),imag(Y)],'squaredeuclidean')/VarZ),1);
            den = sum(exp(-pdist2([real(Cmat0.'),imag(Cmat0.')],[real(Y),imag(Y)],'squaredeuclidean')/VarZ),1);
        else
            num = sum(exp(-abs(Y-Cmat1).^2/VarZ),2).';
            den = sum(exp(-abs(Y-Cmat0).^2/VarZ),2).';    
        end
    elseif flag_demapper==1 %Max-log
        num = max(exp(-abs(Y-Cmat1).^2/VarZ),[],2).';
        den = max(exp(-abs(Y-Cmat0).^2/VarZ),[],2).';
    end
    LLR(k,:) = log(num)-log(den);
end