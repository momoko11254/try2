function [Pattern, varargout] = PRBS(Nb,PatternLength,varargin)
% [Pattern Seed] = PRBS2(Nb,PatternLength,{Seed},Method)
%
% Generates Nb bits from the PRBS sequence of length 2^PatternLength-1.
% Seed (optional) (integer) determines the initial seed for the
%      generator (default 1)
% Method = (optional) {'hardware','software'} hardware or software
%          optimised alogithm (default 'software')
%
% Optional output Seed is the final seed.
%
% Notes on operation:
% To calculate the Mask value from the generating polynomial (of which
% there are several possibilities) calculate the sum of the basis (2)
% raised to the power of the exponents minus 1 (not including the
% pattern length exponent).  That is, for a pattern length of 8 and a
% generating polynomial [8 4 3 2], the Mask=sum(2.^([4 3 2]-1)).  Note
% that in this code, some of the Masks do not match the polynomials.
%
% To check that these generating polynomials are correct, execute the
% following code:
%
% A = PRBS2(2^(PatternLength+1)-2,PatternLength)-0.5;
% plot(abs(ifft(fft(A).*conj(fft(A)))))
%
% Only two peaks should be observed in the output
%
% Author:
% Modified: Domanic Lavery, November 2013

if nargin>2, Seed = varargin{1}; else Seed=1; end
if nargin>3, Method = varargin{2}; else Method='software'; end

switch PatternLength
    case {1,2,3,4,6,7}
        Mask=1;
        ShiftReg=uint8(Seed);
        Bits=[PatternLength 1];
    case 5
        Mask=2;
        ShiftReg=uint8(Seed);
        Bits=[PatternLength 2];
    case 8
        Mask=14;
        ShiftReg=uint8(Seed);
        Bits=[PatternLength 4 3 2];
    case 9
        Mask=8;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 5];
    case 10
        Mask=4;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 7];
    case 11
        Mask=2;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 2];
    case 12
        Mask=41;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 6 4 1];
    case 13
        Mask=13;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 4 3 1];
    case 14
        Mask=21;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 5 3 1];
    case 15
        Mask=1;
        ShiftReg=uint16(Seed);
        %Bits=[PatternLength 1];   %Numerical Recipes Table
        Bits=[PatternLength 14];  %Anritsu PPG
    case 16
        Mask=20488;
        ShiftReg=uint16(Seed);
        Bits=[PatternLength 15 13 4];
    case 17
        Mask=8192;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 14];
    case 18
        Mask=132096;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 11];
    case 19
        Mask=35;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 6 2 1];
    case 20
        Mask=65536;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 17];
    case 21
        Mask=262144;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 19];
    case 22
        Mask=1048576;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 21];
    case 23
        Mask=131072;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 18];
    case 24
        Mask=6356992;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 23 22 17];
    case 25
        Mask=2097152;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 22];
    case 26
        Mask=35;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 6 2 1];
    case 27
        Mask=19;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 5 2 1];
    case 28
        Mask=16777216;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 25];
        % I assume the following work, but they take far too long to test %
    case 29
        Mask=67108864;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 27];
    case 30
        Mask=41;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 6 4 1];
    case 31
        Mask=134217728;
        ShiftReg=uint32(Seed);
        Bits=[PatternLength 28];
    otherwise
        error('PRBS not available for this pattern length')
end

Pattern=zeros(1,Nb);
ShiftMask=2^(PatternLength-1);

switch lower(Method)
    case 'hardware'              %% Hardware optimised implementation
        for n=1:Nb,
            %newbit=uint16(xor(bitget(ShiftReg,15),bitget(ShiftReg,1)));
            newbit=mod(sum(bitget(ShiftReg,Bits)),2);
            ShiftReg=bitshift(ShiftReg,1)+newbit;
            Pattern(n)=newbit;
        end
    case 'software'              %% Software optimised implementation
        for n=1:Nb,
            if bitand(ShiftReg,ShiftMask),
                ShiftReg=bitshift(bitxor(ShiftReg,Mask),1)+1;  % XOR masked bits, logical shift left, put 1 in bit 1;
                Pattern(n)=1;
            else
                ShiftReg=bitshift(ShiftReg,1);
                Pattern(n)=0;
            end
        end
end

varargout{1}=ShiftReg; % returns the final seed
end