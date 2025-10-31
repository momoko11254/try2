function Signal = Manakov(Signal, P)
% Two axis Manakov
% Symmeterised Split step Manakov equation solver, includes 2nd and 3rd order
% dispersion, PMD, SPM and XPM.
%
% Source: C. R. Menyuk, "Nonlinear pulse propagation in birefringent optical
% fibers," IEEE Journal of Quantum Electronics, vol. 23, no. 2, (1987)
% 
% Signal = Manakov(Signal, P)
%
% Inputs:
% SignalIn          - input signal structure
% P                 - Fibre parameters structure contains
% P.Length          - fibre length (m)
% P.dz              - simulation step size [m]
% P.RefWavelength   - reference wavelength [m]
% 
% Optional Inputs:
% Only specify the following parameters if the simulation requires it
% P.Att             - fibre attenuation [Np/m]
% P.D               - dispersion parameter at reference wavelength [s/m^2]
% P.S               - dispersion slope at reference wavelength [s/m^3]
% P.PMD             - PMD parameter at reference wavelength [s/m^0.5]
% P.Gamma           - nonlinear parameter [/W/m]
% P.GPU             - [0 1] for GPU computation
%
% Returns:
% SignalOut         - output signal structure
%
% Converted from NLSE function by Domanic Lavery, 2015
%
% see also NLSE

%% IO Verification
P=IOVerify(P);

if P.Length==0
    if isfield(P,'verbose')&&P.verbose>0, disp('Zero length fibre'), end
    return
end

%% Convert SI to Optical Units
P=SItoOpt(1,P);
% c=3e5;              % nm/ps
c = physconst('lightspeed')*1e-3;

[Np,~] = size(Signal.Et);                  % Total number of points
FF = MakeTimeFrequencyArray(Signal)/1e12;  % Frequency array [THz]

if ~isfield(P, 'Gamma') && ~isfield(P, 'PMD'),  
    Nz=1;           % single step for linear transmission
    dz=P.Length;
else
    Nz=ceil(P.Length/P.dz);
    dz=P.Length/Nz;
end

if isfield(P, 'Att')
    a=P.Att*log(10)/10;         % W/km
    % Calculate effective length for nonlinear interaction in presence of fibre loss
    dzEff = (1-exp(-a*dz))/a;
else
    a=0;
    dzEff = dz;
end

if isfield(P, 'D')
    B2=-P.D*P.RefWavelength.^2/(2*pi*c);   	                        % ps^2/km
    d2=1i/2*B2*(2*pi*FF).^2;
else
    d2=zeros(1,size(Signal.Et,2));
end

if isfield(P, 'S')
    B3=P.RefWavelength.^2/(2*pi*c).^2*(P.RefWavelength.^2*P.S+2*P.RefWavelength*P.D);      % ps^3/km
    d3=1i*B3/6*(2*pi*FF).^3;
else
    d3=zeros(1,size(Signal.Et,2));
end

%% Dispersion operator
D = ones(Np,1)*exp(dz/2*(d2+d3));

if isfield(P, 'PMD')
    mean_DGD = P.PMD*sqrt(P.Length);                        % mean DGD (ps)
    DGD_dz = mean_DGD/(0.9213*sqrt(Nz));
    % 1st order PMD operator
    PMD =exp(-1i*(DGD_dz/4)*(2*pi*FF));
    D = [PMD; 1./PMD].*D;
    
    % Rotation coefficients for PMD:
    theta = (2*rand(1,Nz)-1)*pi;   % random rotation: originally written as rand*2*pi-pi;
    phi = (2*rand(1,Nz)-1)*pi;     % another random rotation: originally written as rand*2*pi-pi;
    rotation = @(theta,phi) [cos(theta)*exp(-1i*phi/2), sin(theta) ; -sin(theta), exp(1i*phi/2)*cos(theta)]; % anonymous function for Jones matrix rotation
end

if isfield(P, 'Gamma'),
    Po=max(max(abs(Signal.Et).^2));
    Lnl=1/(P.Gamma*Po);
    if dz > abs(Lnl),
        warning('Step length is longer than the effective nonlinear length');
    end
else
    D=D.^2;
end


if (~isfield(P,'SinglePrecision')||(P.SinglePrecision~=1))
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Double precision Manakov (for accuracy)'), end
else
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Single precision Manakov (for speed)'), end
    if isfield(P,'PMD')
        theta = single(theta);
        phi = single(phi);
    end
    
        Signal.Et=single(Signal.Et);
        D = single(D);
        dz=single(dz);
        dzEff = single(dzEff);
        a = single(a);
end

%% GPU computing section
if isfield(P,'GPU') && (P.GPU==1)
    if isfield(P, 'Gamma') % No point using GPU if not doing FFT
        % Moves DATA on GPU
        if isfield(P,'PMD')
            theta = gpuArray(theta);
            phi = gpuArray(phi);
        end
        P.Gamma=gpuArray(P.Gamma);
        Signal.Et=gpuArray(Signal.Et);
        D = gpuArray(D);
        dz=gpuArray(dz);
        dzEff = gpuArray(dzEff);
        a = gpuArray(a);
    end
end

%% Transmission
Ef=ifft(Signal.Et,[],2);                                            % Fourier Transform to frequency domain
if isfield(P, 'PMD') && Np==2,
    if isfield(P, 'Gamma')
        if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using Two Axis Split Step Manakov with SPM, XPM and PMD'), end
        NLFactor = 8/9*dzEff*1i*P.Gamma;
        fprintf('Manakov-PMD progress: 00%%')
        for n=1:Nz,
            Ef=rotation(theta(n),phi(n))*Ef;                            % Apply random polarisation rotation and phase shift
            Ef=Ef.*D;                                                   % Apply Dispersion and PMD operators for the first half step
            Et=fft(Ef,[],2);                                            % Fourier Transform to time domain
            aEt = abs(Et).^2;
            N=NLFactor*[aEt(1,:)+aEt(2,:); aEt(2,:)+aEt(1,:)];          % Nonlinear operator SPM & XPM
            Et=Et.*exp(N-dz*a/2);                                       % Apply Nonlinear and loss operators at center of step
            Ef=ifft(Et,[],2);                                           % Fourier Transform to frequency domain
            Ef=Ef.*D;                                                   % Apply Dispersion and PMD operators  for the second half step
            if rem(n/Nz*100,1) == 0
                fprintf('\b\b\b%2.d%%',n/Nz*100)
            end
        end
        fprintf('\n')
    else
        if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using Two Axis Split Step Manakov with PMD'), end
        for n=1:Nz,
            Ef=rotation(theta(n),phi(n))*Ef;                        % Apply random polarisation rotation and phase shift
            Ef=Ef.*D.*exp(-dz*a/2);                                 % Apply Dispersion and PMD and loss operators                                               % Apply Dispersion and PMD operators  for the second half step
        end
    end
elseif isfield(P, 'Gamma') && Np==2,
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using Two Axis Split Step Manakov with SPM and XPM'), end
    NLFactor = 8/9*dzEff*1i*P.Gamma;
    fprintf('Manakov progress: 00%%')
    for n=1:Nz,
        Ef=Ef.*D;                                                       % Apply Dispersion operator for the first half step
        Et=fft(Ef,[],2);                                                % Fourier Transform to time domain
        aEt = abs(Et).^2;
        N=NLFactor*[aEt(1,:)+aEt(2,:); aEt(2,:)+aEt(1,:)];              % Nonlinear operator SPM & XPM
        Et=Et.*exp(N-dz*a/2);                                           % Apply Nonlinear and loss operators at center of step
        Ef=ifft(Et,[],2);                                               % Fourier Transform to frequency domain
        Ef=Ef.*D;                                                       % Apply Dispersion operator for the second half step
        if rem(n/Nz*100,1) == 0
            fprintf('\b\b\b%2.d%%',n/Nz*100)
        end
    end
    fprintf('\n')
elseif isfield(P, 'Gamma') && Np==1,
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using Single Axis Split Step Manakov'), end
    disp('Manakov: Why are you doing this?')
    NLFactor = dzEff*1i*P.Gamma;
    for n=1:Nz,
        Ef=Ef.*D;                                                       % Apply Dispersion operator for the first half step
        Et=fft(Ef,[],2);                                                % Fourier Transform to time domain
        N=9/8*NLFactor*abs(Et).^2;                                      % Nonlinear operator SPM & XPM
        Et=Et.*exp(N-dz*a/2);                                           % Apply Nonlinear and loss operators at center of step
        Ef=ifft(Et,[],2);                                               % Fourier Transform to frequency domain
        Ef=Ef.*D;                                                       % Apply Dispersion operator for the second half step
    end
else
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Simulating Dispersion only'), end
    Ef=Ef.*D.*exp(-dz*a/2);                                             % Apply Dispersion and loss operators only
end

Signal.Et=fft(Ef,[],2);                                                 % Fourier Transform to time domain
Signal.Et = double(gather(Signal.Et));                                  % GPU --> CPU if required
end

%% Input/Output Verification
function P=IOVerify(P)
    warningnum = 0;
    if isfield(P,'Att')&&P.Att>1e-3, warning(['Attenuation value is large: ' num2str(P.Att) ' Np/m']), warningnum=warningnum+1; end
    if isfield(P,'D')&&abs(P.D)>1e-3, warning(['Dispersion value is large: ' num2str(P.D) ' s/m^2']), warningnum=warningnum+1; end
    if isfield(P,'Gamma')&&abs(P.Gamma)>1e-1, warning(['Gamma value is large: ' num2str(P.Gamma) ' W/m']), warningnum=warningnum+1; end

    %% TODO
    % PMD, S, dz, Length
    % if P.PMD>1e-1, warning(['PMD value is large: ' num2str(P.PMD) ' s/m^0.5']), warningnum=warningnum+1; end

    %% ENDTODO

    if (P.RefWavelength<1200e-9)||(P.RefWavelength>1700e-9), warning(['wavelength beyond fiber transmission window: ' num2str(P.RefWavelength) ' m']), warningnum=warningnum+1; end

    if (isfield(P,'GPU')&&P.GPU==1&&gpuDeviceCount<1)
        warning('This machine does not support a GPU; Manakov will be computed on the CPU')
        P.GPU=0;
        warningnum=warningnum+1;
    end

    if (warningnum&&isfield(P,'verbose')&&(P.verbose>=1)), fprintf(['<strong>Manakov warnings: ' num2str(warningnum) '\n</strong>']), end
end