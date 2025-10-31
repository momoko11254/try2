function ESA(varargin)
% Calculates the Electrical spectrum and Group delay and plots it.
%
% figure(n),ESA(varargin)
%
% varargin - electrical signal structure(s) to be displayed
%
% Author: Benn Thomsen, September 2004.

clf
colourstyle={'b' 'g' 'r' 'c' 'm' 'y' 'k'};
for n=1:nargin,
    signal=varargin{n};
    [~,Nt] = size(signal.Et);                  % Total number of points
    dF = 1e-9*signal.Fs/Nt;                    % Spectral resolution (GHz)
    FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF; % Frequency array (GHz)
    Efout=fftshift(ifft(signal.Et,[],2),2);
    If=abs(Efout);
    phase=unwrap(angle(Efout));
    subplot(211),plot(1000*FF',10*log10(If')+30,[char(colourstyle(rem(n-1,7)+1))])
    grid
    ylabel('Intensity (dBm)')
    title('Electrical Spectrum')
    subplot(212),plot(1000*FF',phase',[char(colourstyle(rem(n-1,7)+1))])
    ylabel('Phase (rad)')
    xlabel('Frequency (GHz)')
    hold on
end
hold off
end