function RealSigOut = Normalise(ComplexSig)
% Signal Normalisation for full DAC range
%
% Input:
%   ComplexSig
%       class   | complex<double>
%       size    | (1, :) or (2, :) for single or dual pol data
% Output:
%   RealSigOut
%       class   | double
%       size    | (2, :) or (4, :) for single or dual pol data
%
% Author: Y. Wakayama June 2019

RealSigIn = Complex2Real(ComplexSig);
RemoveDC = RealSigIn-mean(RealSigIn,2);
RealSigOut = RemoveDC./max(abs(RemoveDC),[],2);

end
