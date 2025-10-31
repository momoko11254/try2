function [varargout] = AWGDemux(SignalIn,P)
% If single output works as an AWG Demultiplexer with all channels separeted on output cell.
% If dual output works as a deinterleaver
% Filter shape, Parabolic or Gaussian pulses is specified by P.AWG.Type
%
% Inputs
% SignalIn      - Input optical signal structure
% P.Spacing     - Channel spacing [Hz]
% P.nWDM        - Number of WDM channels
% P.AWG.order   - Optical filtering order
% P.AWG.BW      - Bandwidth of optical filtering
% P.AWG.Type    - Optical filter type ('Gaussian','Parabolic')
% 
% Optional for deinteleaver mode:
% P.Int.ER  Limited extiction ratio for the deinterleaver   [dB]
% 
% Returns:
% Sch  - Cell containing output filtered channels
% Sodd - Odd channels
% Seven- Even channels
% 
% Author: Benn Thomsen, September 2004.
% Modified: Gabriele Liga, November 2013

order=P.AWG.order;
Spacing=P.Spacing;
BW=P.AWG.BW;

[Np,Nt]=size(SignalIn.Et);
Nc=P.nWDM;
Sch=cell(1,P.nWDM);
dF = P.Fs/Nt;                           %
FF = (-Nt/2:(Nt/2)-1) * dF; 	        %
Fo=BW/(2*log(2).^(1/(2*order)));        %
ER=10^(P.Int.ER/20);
filtType=P.AWG.Type;

Ef=fftshift(ifft(SignalIn.Et,[],2),2);                                          % Frequency domain
Efout = zeros(Nc,Nt);

for n=1:Nc
    Fsh=((n-1)*Spacing-(Nc-1)*Spacing/2);
    if strcmp(filtType,'Gaussian'),
        hh = ones(Np,1)*exp(-1/2*((FF-Fsh)./Fo).^(2*order));                          % Gaussian Filter
    elseif strcmp(Format,'Parabolic'),
        hh = ones(Np,1)*(1-(1-sqrt(0.5))*((FF-Fsh)./(0.5e-3*BW)).^2);                   % Parabolic Filter
        hh(hh<0)=zeros(size(find(hh<0)));
    else
        error('Format string must be either Gaussian or Parabolic')
    end
    
    Efout = hh.*Ef;
    SignalIn.Et=fft(fftshift(Efout,2),[],2);
    Sch{1,n}=SignalIn;
end

% DeInterleaver case (Odd and Even channels)
if isequal(nargout,2)
    Sodd=SignalIn;
    Seven=SignalIn;
    Sodd.Et=zeros(Np,Nt);
    Seven.Et=zeros(Np,Nt);
    
    % Select and put together odd and even channels
    Seven.Et=Sch{1,1}.Et;
    for n=1:(Nc-1)/2
        Sodd.Et=Sodd.Et+Sch{1,2*n}.Et;
        Seven.Et=Seven.Et+Sch{1,2*n+1}.Et;
    end
    
    temp=Sodd.Et;
    Sodd.Et=Sodd.Et+ER*Seven.Et;
    Seven.Et=Seven.Et+ER*temp;
    
    varargout{1}=Sodd;
    varargout{2}=Seven;
end
end