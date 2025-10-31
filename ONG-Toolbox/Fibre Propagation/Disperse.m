function Signal = Disperse(Signal,P)
%
% Inputs:
% P.D               - Dispersion parameter [s/m^2]
% P.S               - dispersion slope at reference wavelength [s/m^3]
% P.Length          - Fibre Length [m]
% P.RefWavelength   - Reference wavelength [m]
%
% Returns:
% SignalOut         - Output signal structure
% 
% Author: Benn Thomsen, January 2006.
% Modified: Benn Thomsen, Oct. 2010

% Convert SI to Optical Units
P=SItoOpt(1,P);

c=3e5;                                  % nm/ps

[Np,Nt] = size(Signal.Et);                  % Total number of points
dF = 1e-12*Signal.Fs/Nt;                    % Spectral resolution (THz)
FF = [0:floor(Nt/2)-1,floor(-Nt/2):-1]*dF;  % Frequency array (THz)

if ~isfield(P, 'RefWavelength')
    P.RefWavelength=1550;
end

if isfield(P, 'D')
    B2=-P.D*P.RefWavelength.^2/(2*pi*c);   	                        % ps^2/km
    d=1j/2*B2*(2*pi*FF).^2;
else
    d=0;
end

if isfield(P, 'S')
    B3=P.RefWavelength.^2/(2*pi*c).^2*(P.RefWavelength.^2*P.S+2*P.RefWavelength*P.D);      % ps^3/km
    d=d+1j*B3/6*(2*pi*FF).^3;
end

Hf=ones(Np,1)*exp(P.Length*d);
Signal.Et=fft(Hf.*ifft(Signal.Et,[],2),[],2);
end