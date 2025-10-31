function data = AddError(data,Nerr)
% Adds specified number of errors to the data sequence at random locations
%
% data = AddError(data,Nerr)
%
% Inputs:
% data      - input data
% Nerr      - number of errors to add
%
% Returns:
% data      - data with errors
% 
% Author: Benn Thomsen, May 2005.

Nerr=round(Nerr);

if Nerr == 0,
    return
elseif Nerr > 0,
    Nd=length(data);
    indAll = (1:Nd);
    ind = zeros(1,Nerr);
    for n=1:Nerr,
        ind(n)=indAll(ceil((Nd-n)*rand)+1);
        indAll=indAll(find(indAll ~= ind(n)));
    end
    data(ind)=~data(ind);
else
    error('Number of errors must be a positive integer')
end
end