function OSA(varargin)
% Calculates the Optical spectrum and plots it.
%
% figure(n),OSA(varargin)
%
% varargin - optical signal structure(s) to be displayed
%          - optional last parameter structure with the following parameters
%               P.Resolution - OSA resolution (GHz)
%               P.Points     - Number of point to include
%
% Author: Benn Thomsen, October 2010.

if isfield(varargin{nargin},'Et')
    N = nargin;
    chop = 0;
    res = 1;
    %     resolution = 12.5;          % 0.1nm
%     resolution = 1.25;          % 0.01nm
    
    temp = varargin{nargin}; % In GHz
    if isfield(temp,'Resolution')
        resolution = temp.Resolution;
    else
        resolution = 1.25;          % 0.01nm
    end
else
    N = nargin - 1;
    res = 1;
    P = varargin{nargin}; % In GHz
    if isfield(P,'Resolution')
        if P.Resolution==0;
            res = 0;
        else
            resolution = P.Resolution; % In GHz
        end
    else
        resolution = 12.5;          % 0.1nm
        %         resolution = 1.25;          % 0.01nm
    end
    if isfield(P,'Points')
        len = P.Points;
        chop=1;
    else
        chop=0;
    end
end

clf
colourstyle = {'b' 'g' 'r' 'c' 'm' 'y' 'k'};
for n=1:N,
    Signal = varargin{n};
    if chop
        len=min([len,length(Signal.Et)]);
        Signal.Et=Signal.Et(:,1:len);
    end
    [~,Nt] = size(Signal.Et);                 % Total number of points
    dF = 1e-9*Signal.Fs/Nt;                   % Spectral resolution (GHz)
    FF = [floor(-Nt/2):floor(Nt/2)-1] * dF;   % Frequency array (GHz)
    % Get signal Power spectral density in W. If is the Power spectral
    % density in W/GHz. Remember that the only difference between fft() and
    % ifft() is that ifft() normalises by a 1/N factor. Because
    % polarisations are orthogonal, we can add the squared values to get
    % Power.
    Efout = fftshift(ifft(Signal.Et, [], 2), 2);
    % If is the Power spectral density with dF resolution
    If = sum(abs(Efout).^2, 1);
    
    % If resolution is not zero, then average the spectrum to simulate that
    % resolution.
    if(res)
        NN= 2*round(resolution./(2*dF));
        b= ones(1,NN);
        if NN<512 % speed optimisation
            If = filter(b, 1, [If(NN:-1:1) If If(Nt:-1:Nt-NN-1)]);
        else
            If = fftfilt(b, [If(NN:-1:1) If If(Nt:-1:Nt-NN-1)]);
        end
        If=If(NN+NN/2+1:Nt+NN+NN/2);
    end
    IfdBm = 10*log10(If) + 30;
    plot(FF, IfdBm', char(colourstyle(rem(n-1,7)+1)));
    hold on;
end
hold off;
grid on;
ylabel('Intensity (dBm/res)')
title('Optical Spectrum')
xlabel('Frequency (GHz)')
end