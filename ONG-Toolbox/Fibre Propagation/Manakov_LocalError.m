function Signal = Manakov_LocalError(Signal, P)
% Two axis Manakov SSFM with local error adaptive step
% Symmeterised Split step Manakov equation solver with adaptive step size (local error),
% includes 2nd and 3rd order dispersion, PMD, SPM and XPM
%
% SSFM: C. R. Menyuk, "Nonlinear pulse propagation in birefringent optical
% fibers," IEEE Journal of Quantum Electronics, vol. 23, no. 2, (1987)
%
% Adaptive Local Error: O. V. Sinkin, "Optimization of the Split-Step Fourier Method in
% Modeling Optical-Fiber Communications Systems', vol. 21, no. 1, (2003)
%
% Signal = Manakov_LocalError(Signal, P)
%
% Inputs:
% SignalIn          - input signal structure
% P                 - Fibre parameters structure contains:
% P.Length          - fibre length (m)
% P.LocalErrorTol   - local error tolerance (lower = more steps but smaller error, use 1e-4 or less)
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
% Local Error method added by Ronit Sohanpal, 2022
%
% see also NLSE
%
% TO-DO
% Implement PMD

%% IO Verification
P=IOVerify(P);

if P.D==0
    if isfield(P,'verbose')&&P.verbose>0, disp('Zero dispersion fibre'), end
    return
end

if P.Att==0
    if isfield(P,'verbose')&&P.verbose>0, disp('Zero loss fibre'), end
    return
end

if P.GPU==0
    if isfield(P,'verbose')&&P.verbose>0, disp('GPU not used for SSFM'), end
    return
end

% if ~isfield(P,'Gamma')||P.Gamma == 0
%     error('Manakov_LocalError only applicable for non-zero D & Gamma!');
% end

%% Convert SI to Optical Units
P=SItoOpt(1,P);
c = physconst('lightspeed')*1e-3;

% [Np,~] = size(Signal.Et);                  % Total number of points
FF = MakeTimeFrequencyArray(Signal)/1e12;  % Frequency array [THz]

if isfield(P, 'Att')
    a=P.Att*log(10)/10;         % W/km
    % Calculate effective length for nonlinear interaction in presence of fibre loss
else
    a=0;
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

if ~isfield(P, 'LocalErrorTol')
    errtol = 1e-5;
else
    errtol = P.LocalErrorTol;
end

%% Transmission

dist = 0;
dz = P.Length/1e2;                                                         % set starting step size to 1/100 of fibre length
Ef0 = ifft(Signal.Et,[],2);

%tracking vars
itertrack = 1;
dztrack = dz;
dzEfftrack = [];
disttrack = dist;
errortrack = [];

%% GPU computing section
if isfield(P,'GPU') && (P.GPU==1)
    % Moves DATA on GPU
    P.Gamma=gpuArray(P.Gamma);
    d2 = gpuArray(d2);
    d3 = gpuArray(d3);
    Ef0=gpuArray(Ef0);
    dz=gpuArray(dz);
    a = gpuArray(a);
    dztrack = gpuArray(dztrack);
    dzEfftrack = gpuArray(dzEfftrack);
end

%% SSFM

if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using Two Axis Split Step Manakov (Local Error) with SPM and XPM'), end
fprintf('Manakov progress: 00%%')

while dist<P.Length
    
    if dist + dz > P.Length
        dz  = P.Length-dist;
    end
    
    %% Coarse step of total size dz
    
    dzEff = (1-exp(-a*dz))/a;
    D = exp(dz/2*(d2+d3));
    NLFactor = 8/9*dzEff*1i*P.Gamma;
    
    Ef = Ef0 .* D;                                                         % Apply Dispersion operator for the first half step
    Et = fft(Ef,[],2);                                                     % Fourier Transform to time domain
    aEt = abs(Et).^2;
    N = NLFactor*[aEt(1,:)+aEt(2,:); aEt(2,:)+aEt(1,:)];                   % Nonlinear operator SPM & XPM
    Et = Et .* exp(N-dz*a/2);                                              % Apply Nonlinear and loss operators at center of step
    Ef = ifft(Et,[],2);                                                    % Fourier Transform to frequency domain
    Ef = Ef .* D;                                                          % Apply Dispersion operator for the second half step
    Etcourse = fft(Ef,[],2);
    
    %% Fine step #1 of size dz/2
    
    dzf = dz/2;                                                            % define fine step size
    
    dzEff = (1-exp(-a*dzf))/a;
    D = exp(dzf/2*(d2+d3));
    NLFactor = 8/9*dzEff*1i*P.Gamma;
    
    Ef = Ef0 .* D;                                                         % Apply Dispersion operator for the first half step
    Et = fft(Ef,[],2);                                                     % Fourier Transform to time domain
    aEt = abs(Et).^2;
    N = NLFactor*[aEt(1,:)+aEt(2,:); aEt(2,:)+aEt(1,:)];                   % Nonlinear operator SPM & XPM
    Et = Et .* exp(N-dzf*a/2);                                             % Apply Nonlinear and loss operators at center of step
    Ef = ifft(Et,[],2);                                                    % Fourier Transform to frequency domain
    Ef = Ef.* D;                                                           % Apply Dispersion operator for the second half step
    
    %% Fine step #2 of size dz/2
    
    Ef = Ef .* D;                                                          % Apply Dispersion operator for the first half step
    Et = fft(Ef,[],2);                                                     % Fourier Transform to time domain
    aEt = abs(Et).^2;
    N = NLFactor*[aEt(1,:)+aEt(2,:); aEt(2,:)+aEt(1,:)];                   % Nonlinear operator SPM & XPM
    Et = Et .* exp(N-dzf*a/2);                                             % Apply Nonlinear and loss operators at center of step
    Ef = ifft(Et,[],2);                                                    % Fourier Transform to frequency domain
    Ef = Ef .* D;
    Etfine = fft(Ef,[],2);
    
    %% Relative Local Error
    localerror = sum(abs(Etfine - Etcourse).^2) / sum(abs(Etfine).^2);     % Calculate relative local error
    
    %% Adaptive step selection based on local error
    
    if localerror < 2*errtol
        dist = dist + dz;
        Et0 = (4/3)*Etfine - (1/3)*Etcourse;                               % keep solution
        
        if localerror < 0.5*errtol
            dz = dz * 2^(1/3);                                             % local error is too small -> increase dz for next step
        elseif localerror > 1*errtol
            dz = dz / 2^(1/3);                                             % local error is too large -> decrease dz for next step
        end
        
        Ef0 = ifft(Et0,[],2);
        
        %         if floor(dist/P.Length*100)~=ceil((dist+dz)/P.Length*100)          % the step takes us over a whole percent number
        %             fprintf('\b\b\b%02d%%',round(dist/P.Length*100))
        %         end
        if floor(dist/P.Length*100)~=ceil((dist+dz)/P.Length*100)          % the step takes us over a whole percent number
            fprintf('\b\b\b%02d%%',round(dist/P.Length*100))
        end
        
    else
        dz = dzf;                                                          % local error is way too large -> discard solution and repeat for 0.5*dz
    end
    
    itertrack = itertrack + 1;
    
    if isfield(P,'plot') && P.plot==1
        %monitoring/plotting
        dztrack(end+1) = dz;
        dzEfftrack(end+1) = dzEff;
        disttrack(end+1) = dist;
        errortrack(end+1) = localerror;
    end
    
end

if isfield(P,'plot') && P.plot==1
%     figure(); plot(disttrack,dztrack,'-*'); ylabel('Step size (km)'); xlabel('Distance (km)');
%     figure(); plot(disttrack,'-*'); ylabel('Distance (km)'); xlabel('Step no.');
%     figure(); plot(dztrack,'-*'); ylabel('Step Size (km)'); xlabel('Step no.');
    figure(); plot(errortrack,'-*'); ylabel('Local Error'); xlabel('Step no.'); yline(errtol); yline(errtol/2); ylim([0 2*errtol]);
%         figure(); plot(dzEfftrack,'-*'); ylabel('Effective Step Size (km)'); xlabel('Distance (km)');
end

% if isfield(P,'verbose') && P.verbose==1
fprintf('\n'); disp(strcat('Number of Manakov steps (local error method): ',num2str(itertrack)));
% end

Signal.Et=fft(Ef0,[],2);                                                   % Fourier Transform to time domain
Signal.Et = double(gather(Signal.Et));                                     % GPU --> CPU if required
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