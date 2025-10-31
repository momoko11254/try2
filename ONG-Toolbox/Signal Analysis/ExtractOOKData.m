function Data=ExtractOOKData(Signal)
% Recovers the data from an electrical signal. Calculates the
% optimum sampling time
%
% Data=ExtractData(Signal)
%
% Input:
% SignalIn      - signal structure
%
% Returns:
% Data          - Recovered Data
%
% Author: Benn Thomsen, May 2005.


Nd=OptSamplePoint(Signal);                      % Determine optimal sampling point
Eave=sum(Signal.Et,2)./Signal.Nt;               % Calculate signal average Power
Signal.Et=Signal.Et-Eave;                       % Subtract DC component
Eye=reshape(Signal.Et,Signal.Ns,Signal.Nb);     % Reshape shifted signal to produce eye diagram
%figure(11),plot(Eye(:,1:1000))
Sample=Eye(Nd,:);                               % Sample at the optimum point
Data=(Sample > 0);                              % Threshold samples to determine data
end