function SignalOut = KronUpsampler(SignalIn, ImResp)
% Upsampler using Kron function
% See also Complex2Real.m and Real2Complex.m
%
% Input:
%   In: Signal
%       class   | struct
% Output:
%   Out: Signal
%       class   | struct
%
% Author: Y. Wakayama June 2019

RealSig = Complex2Real(SignalIn.Et);
RealZeroPadded = kron(RealSig, ImResp);
SignalOut.Et = Real2Complex(RealZeroPadded);

end