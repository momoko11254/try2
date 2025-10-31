function Signal = Manakov_Adaptive(Signal,P)
% Two axis Adaptive Manakov Equation Solver
% Symmeterised Split step NLSE solver, includes 2nd and 3rd order
% dispersion, PMD, SPM and XGM.
%
% Signal=Manakov_Adaptive(Signal,P)
%
% Inputs:
% SignalIn - input signal structure
% P - Fibre parameters structure contains
%  .Length - fibre length (km)
%  .dz - simulation step size (km)
%  .RefWavelength - reference wavelength (nm)
% Only specify the following parameters if the simulation requires it
%  .Att - fibre attenuation (dB/km)
%  .D - dispersion parameter at reference wavelength (ps/nm/km)
%  .S - dispersion slope at reference wavelength (ps/nm^2/km)
%  .Gamma - nonlinear parameter (/W/km)
%  .PhiMax - Maximum nonlinear phase shift per nonlinear step - rads


% Returns:
% Signal - output signal structure
%
% Author: D Millar - Aug. 2010
% Modified: B Thomsen - Oct. 2010

c=3e5;              % nm/ps

[~,Nt] = size(Signal.Et);                  % Total number of points
dF = 1e-12*Signal.Fs/Nt;                    % Spectral resolution (THz)
FF = [0:(Nt/2)-1,-Nt/2:-1] * dF;            % Frequency array (THz)

if isfield(P, 'Att')&&(P.Att~=0)
    a=P.Att*log(10)/10;         % /km
else
    a=0;
end

if isfield(P, 'D')
    B2=-P.D*P.RefWavelength.^2/(2*pi*c);   	                        % ps^2/km
    d2=1i/2*B2*(2*pi*FF).^2;
else
    d2=zeros(1,size(SignaIn.Et,2));
end

if isfield(P, 'S')
    B3=P.RefWavelength.^2/(2*pi*c).^2*(P.RefWavelength.^2*P.S+2*P.RefWavelength*P.D);      % ps^3/km
    d3=1i*B3/6*(2*pi*FF).^3;
else
    d3=zeros(1,size(SignaIn.Et,2));
end

Po=max(max(real(Signal.Et).^2+imag(Signal.Et).^2));

Ef=ifft(Signal.Et,[],2);                              % Fourier Transform to frequency domain

disp('Using Two Axis Adaptive Split Step NLSE with Manakov Nonlinear estimation')

dist=0;
while dist<P.Length,
    
    if ~isfield(P, 'PhiMax')
        dz=0.003/(abs(P.Gamma)*Po);
    else
        dz=P.PhiMax/(abs(P.Gamma)*Po);
    end
    
    if dist+dz>P.Length,
        dz=P.Length-dist;
    end
    
    dzEff = (1-exp(-a*dz))/a;
    D = exp(dz/2*(d2+d3));
    Ef(1,:)=Ef(1,:).*D;                               % Apply Dispersion operator for the first half step
    Ef(2,:)=Ef(2,:).*D;                               % Apply Dispersion operator for the first half step
    Et=fft(Ef,[],2);                                  % Fourier Transform to time domain
    Power = sum(real(Et(1,:)).^2+imag(Et(1,:)).^2,1); % Intermediate per polarisation Power measurements
    % N=dzEff*i*P.Gamma*[abs(Et(1,:)).^2+2/3*abs(Et(2,:)).^2; abs(Et(2,:)).^2+2/3*abs(Et(1,:)).^2];  % Nonlinear operator SPM & XPM
    N=dzEff*1i*P.Gamma*8/9*Power;                     % Nonlinear operator SPM & XPM
    Et(1,:)=Et(1,:).*exp(N(1)-dz*a/2);                % Apply Nonlinear and loss operators at center of step to pol state 1
    Et(2,:)=Et(2,:).*exp(N(2)-dz*a/2);                % Apply Nonlinear and loss operators at center of step to pol state 2
    Po=max(max(real(Et).^2+imag(Et).^2));             % Calculate peak Power
    Ef=ifft(Et,[],2);                                 % Fourier Transform to frequency domain
    Ef(1,:)=Ef(1,:).*D;                               % Apply Dispersion operator for the second half step
    Ef(2,:)=Ef(2,:).*D;                               % Apply Dispersion operator for the second half step
    dist=dist+dz;
end
Signal.Et=fft(Ef,[],2);                              % Fourier Transform to time domain
end