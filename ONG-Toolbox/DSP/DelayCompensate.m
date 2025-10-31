function [SignalOut, varargout] = DelayCompensate(SignalIn, P, varargin)
warning('a duplicate exists on Pilot-Toolbox')
% Correct Delays in receiver resulting from different optical path lengths
%  in Rx (Hard Coded from IM-DD measurements: resolution 0.1ps)
% Modified: Y. Wakayama, April 2019.

SignalOut = SignalIn;
scale = 1e-12;
%% Set Delays
if P.CoRx == 1                              % Old Seb CoRx
    delay31 = 0*scale;
    delay32 = -18.2*scale;
    delay33 = -14*scale;
    delay34 = -34*scale;
    disp('Delays for scope 1 applied')
elseif P.CoRx == 2                          % Integrated U2T_1
    delay31 = 0*scale;
    delay32 = 12.55*scale;
    delay33 = 3.4*scale;
    delay34 = 14.1*scale;
    disp('Delays for scope 2 applied')
elseif P.CoRx == 3                          % Integrated U2T_2
    delay31 = 0*scale;
    delay32 = 0*scale;
    delay33 = 0*scale;
    delay34 = 0*scale;
    disp('Delays for scope 3 applied')
elseif P.CoRx == 4                          % Integrated U2T_3
    delay31 = 0*scale;
    delay32 = 0*scale;
    delay33 = 0*scale;
    delay34 = 0*scale;
    disp('Delays for scope 4 applied')
elseif P.CoRx == 5                      	% 65GHz U2T
     delay31 = 0*scale;                     % XI
     delay32 = P.RxDelayXIQ*scale;            % XQ - delay between XI and XQ
     delay33 = P.RxDelayXY*scale;             % YI - delay between XY
     delay34 = (P.RxDelayXY+P.RxDelayYIQ)*scale;% YQ - delay between YI and YQ
else
    disp('no receiver skew compensation')
    return
end

%% Split input into streams
in2 = imag(SignalIn.Et(1,:));
in3 = real(SignalIn.Et(2,:));
in4 = imag(SignalIn.Et(2,:));

%% Fast
FreqArray = 1j*2*pi*MakeTimeFrequencyArray(SignalIn);       % input frequency array
sh1 = real(SignalIn.Et(1,:));
if(delay31~=0)
    sh1 = real(ifft(fft(sh1).*exp(FreqArray*delay31)));     % apply delay as phase shift
end

SignalOut.Et(1,:) = sh1+1j*real(ifft(fft(in2).*exp(FreqArray*delay32)));
SignalOut.Et(2,:) = real(ifft(fft(in3).*exp(FreqArray*delay33)))+1j*real(ifft(fft(in4).*exp(FreqArray*delay34)));

if nargout>1
    delays(1)=delay31;
    delays(2)=delay32;
    delays(3)=delay33;
    delays(4)=delay34;
    
    varargout{1}=delays;
end
