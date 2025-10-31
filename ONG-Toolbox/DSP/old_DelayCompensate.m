function [SignalOut, varargout] = DelayCompensate(SignalIn, P)
% Correct Delays in receiver resulting from different optical path lengths
%  in Rx (Hard Coded from IM-DD measurements: resolution 0.1ps)

SignalOut = SignalIn;
varargout{1} = P;

scale = 1e-12;
%% Set Delays
if isfield(P,'Delays')
    delays = P.Delays;
elseif (~isfield(P,'CohRx') || P.CohRx == 0)            % Simulations
    return
elseif P.CohRx == 1
    % Date 22.06.12 Seb CohRx
    delays = [0*scale...     % XI
              -18.2*scale... % XQ
              -14*scale...   % YI
              -34*scale];    % YQ
    SignalIn.Et(2,:) = conj(SignalIn.Et(2,:));                   % If using inverted second output 'Old CohRx'
elseif P.CohRx == 2
    % SEnded
    delays =[0*scale...
             880*scale...
             2.9*scale...
             3.4*scale];
end

%% Create Parameters
FF = MakeTimeFrequencyArray(SignalIn);

%% Split input into streams    
in2 = imag(SignalIn.Et(1,:));
in3 = real(SignalIn.Et(2,:));
in4 = imag(SignalIn.Et(2,:));
 
%% Fast implementation
FF = 1j*2*pi*FF;            % input frequency array
sh1 = real(SignalIn.Et(1,:)); 
if(delays(1)~=0)
    sh1 = real(ifft(fft(sh1).*exp(FF*delays(1)))); % apply delay as phase shift
end

SignalOut.Et(1,:) = sh1+1j*real(ifft(fft(in2).*exp(FF*delays(2))));
SignalOut.Et(2,:) = real(ifft(fft(in3).*exp(FF*delays(3))))+1j*real(ifft(fft(in4).*exp(FF*delays(4))));

%% Assign outputs
P.Delays = delays;