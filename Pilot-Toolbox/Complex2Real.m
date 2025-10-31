function Out = Complex2Real(In)
% Complex-to-Real converter
% See also Real2Complex.m
%
% Input:
%   In: Signal.Et
%       class   | complex<double>
%       size    | (1, :) or (2, :) for single or dual pol data
% Output:
%   Out: Signal.Et
%       class   | double
%       size    | (2, :) or (4, :) for single or dual pol data
%
% Author: Y. Wakayama June 2019

Out = reshape([real(In) imag(In)].', size(In, 2), []).';

end