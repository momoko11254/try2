function Out = Real2Complex(In)
% Real-to-Complex Converter
% See also Complex2Real.m
%
% Input:
%   In: Signal.Et
%       class   | double
%       size    | (2, :) or (4, :) for single or dual pol data
% Output:
%   Out: Signal.Et
%       class   | complex<double>
%       size    | (1, :) or (2, :) for single or dual pol data
%
% Author: Y. Wakayama June 2019

Out = complex(In(1:2:end, :), In(2:2:end, :));

end