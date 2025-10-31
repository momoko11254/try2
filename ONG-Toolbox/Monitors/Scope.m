function Scope(varargin)
% Oscilloscope. User selectable vertical scale Power in dBm or
% Watts. Accepts an arbitrary number of electrical signals. displays the
% optical intensity, phase and chirp.
%
% Scope(varargin)
%
% Inputs:
% varargin          - field(s) to be displayed
% 
% Optional Inputs:
% yScale            - optional vertical scale type ('dBm' 'mW' 'W') default is mW
%
% Author: Benn Thomsen, September 2004.

if ischar(varargin{nargin})
    N=nargin-1;
    yScale=varargin{nargin};
else
    N=nargin;
    yScale='mW';
end

clf
colourstyle={'b' 'g' 'r' 'c' 'm' 'y' 'k'};
for n=1:N,
    signal=varargin{n};
    It=abs(signal.Et);
    if strcmp('dBm',yScale),
        It=10*log10(It)+30;
    elseif strcmp('W',yScale)
        It=It;
    elseif strcmp('mW',yScale)
        It=1000*It;
    end
    
    phase=unwrap(angle(signal.Et));
    [Nc,Nt]=size(phase);
    dT = 1e12/signal.Fs;                         % Temporal resolution (ps)
    TT = [0:Nt-1] * dT;                                      % Time array (ps)
    for m=1:Nc,
        chirp(m,:)=-1000*gradient(phase(m,:),TT)./(2*pi);
    end
    
    subplot(311),plot(TT,It,[char(colourstyle(rem(n-1,7)+1))]);
    yl=['Intensity (' yScale ')'];
    ylabel(yl)
    title('Temporal Fields')
    hold on
    subplot(312),plot(TT,phase,[char(colourstyle(rem(n-1,7)+1))]);
    ylabel('Phase (rad)')
    hold on
    subplot(313),plot(TT,chirp,[char(colourstyle(rem(n-1,7)+1))]);
    ylabel('Chirp (GHz)')
    xlabel('Time (ps)')
    hold on
end
end