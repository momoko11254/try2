function Nd=OptSamplePointNRZ(Signal)
% Clock recovery based on phase measurement using a full quadurature mixer
% to determine the optimum sampling point
%
% Nd=OptSamplePointNRZ(Signal)
%
% Inputs:
% signal    - structure containing signal parameters
%
% Returns:
% Nd        - the optimum sampling index on the range 1 to number of samples per bit
%
% Author: Benn Thomsen, May 2005.

Nt=length(Signal.Et);
Ns=Signal.Fs/Signal.Fb;
NN = [-Ns/2:Nt-Ns/2-1];	% Timebase in points
w=2*pi/Ns;                                  % Clock tone frequency (1/points)

Eave=sum(Signal.Et,2)./Nt;                  % Calculate signal average Power
Signal.Et=Signal.Et-Eave;                   % Subtract DC component
error=sum(exp(1i*w*NN).*Signal.Et.^2,2);    % Implement full quadature mixer and integrator on doubled signal

phase=angle(error);
Nd=round((Ns-1)*(phase+pi)/(2*pi))+1;
end