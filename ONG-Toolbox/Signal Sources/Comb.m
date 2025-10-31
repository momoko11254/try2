function SignalOut = Comb(SignalIn, P)
% Generates a comb of lasers lines with identical phase noise specifying at
% the input either a vector of frequencies or number of lines and spacing
% (in which case the number of lines must be odd for the comb to be symmetric).
% 
% Inputs:
% P.Fc                  - Central channel frequency [Hz]
% P.Fs                  - Sampling frequency [Hz]
% 
% Optional inputs
% P.Fchan               - Channel frequencies vector [Hz]
% P.nWDM                - Number of lines to generate (odd)
% P.Spacing             - Lines spacing [Hz]
% P.Linewidth           - Laser linewidth [Hz]
% 
% Returns:
% SignalOut             - Comb signal structure
% 
% Author:

[Np,Nt]=size(SignalIn.Et);
SignalOut = SignalIn;
SignalOut.Et=zeros(Np,Nt);
TT=1/SignalIn.Fs*(0:Nt-1);                                     % Time vector

% Generate original CW source with given phase noise
P.Offset=0;
CW=CWLaser(SignalIn,P);

% Specified frequencies case
if isfield(P,'Fchan')
    for k=1:length(P.Fchan)                            % Odd channels
        P.Offset=(P.Fchan(k)-P.Fc);
        Line=CW.Et.*kron(ones(Np,1),exp(1i*2*pi*P.Offset*TT));          % Frequency shifted line
        SignalOut.Et=SignalOut.Et+Line;
    end
    
    % Specified spacing and number of lines
else
    for k=1:P.nWDM
        P.Offset=(k-(P.nWDM-1)/2)*P.Spacing;
        Line=CW.Et.*kron(ones(Np,1),exp(1i*2*pi*P.Offset*TT));         % Frequency shifted line
        SignalOut.Et=SignalOut.Et+Line;
    end
end
end