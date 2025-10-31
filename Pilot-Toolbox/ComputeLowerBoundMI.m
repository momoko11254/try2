function MI=ComputeLowerBoundMI(X,Y)
% ComputeLowerBoundMI(X,Y) computes a lower bound on the mutual information
% between the vectors X and Y using a AWGN as auxiliary channel. The
% transmitted constellation points need not to be normalized, however, it
% is expected (for the bound to be tight) that the noisy received symbols
% are around the transmitted ones.
%
% X     : Column vector of complex transmitted symbols
% Y     : Column vector of complex received symbols
%
%
% Alex Alvarado
% November 2014
C=unique(X,'rows');         % Constellation
M=size(C,1);                % Constellation size
VarZ=var(Y-X);              % Noise variance
MI=0;
for i=1:M
    pnt=find(X==C(i));              % Pointer to all times when the ith symbol was tx
    dij=C(i)-C;                     % Vector of differences x_i-x_j for all j
    Dij=repmat(dij,1,length(pnt));          % Matrix version of the differences
    Ymat=repmat((Y(pnt)-C(i)).',M,1);       % Matrix version of the samples
    MI=mean(-log2(sum(exp(-(abs(Dij).^2+2*real(Ymat.*Dij))/VarZ),1)))+MI;    
end
MI=log2(M)+MI/M; 
return