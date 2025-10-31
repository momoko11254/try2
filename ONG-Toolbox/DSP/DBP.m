function SignalOut = DBP(SignalIn, P)
% Digital Back Propagation algorithm based on Wiener-Hammenstein scheme,
% GPU VERSION 
%
% SignalOut = DBP(SignalIn, P)
% 
% Inputs:
% P.Att - Attenuation [Np/m]
% P.D = Dispersion constant of fiber - in [s/m^2]
% P.GammaBp - adjustmust factor to optimise the DBP algorithm [/W/m]
% P.NSpans = number of spans to be compensated
% P.Length= Fibre span length [m]
% P.RefWavelength = wavelength of interest - in [m]
% P.LaunchPower - Signal launch power into the fibre [W]
% P.NSteps_NLC - number of steps per span for DBP
%
% Optional inputs:
% P.WH_Split - Splitting factor for dispersion operator (0 to 1, default 0.5)
% P.SinglePrecision - Set to one for single precision calculations (GPU only)
%
% Authors: Gabriele Liga, 2013
% Modified: Damanic Lavery, 2014

SignalOut = SignalIn;

%% IO Verification
IOVerify(P);

%% Setup
c=3e8;                                  % Light speed [m/s]
[Np,~]=size(SignalIn.Et);
FF=MakeTimeFrequencyArray(SignalIn);

if ~isfield(P, 'WH_Split')             % If not specified sets to .5 WH splitting ratio
    P.WH_Split=.5;
end

% Normalises input signal power to 1
Pow=mean(sum(abs(SignalIn.Et).^2));
Et=SignalIn.Et/sqrt(Pow);

%% Frequency domain implementation of dispersion compensation
LaunchPower = P.LaunchPower; % Launch Power [W]
a=P.Att;                                 % Attenuation in Np/m

%  Dispersion Parameters
B2=-P.D*P.RefWavelength.^2/(2*pi*c);
d2=1j/2*B2*(2*pi*FF).^2;

% Step size
dz =P.Length/P.NSteps_NLC;                % Step size [m]

% Effective nonlinear step size
dzNLEff = (1-exp(-a*dz))/a;

%Inverse Dispersion Operators
Dinv1 = conj(ones(Np,1)*exp(d2*P.WH_Split*dz));
Dinv2 = conj(ones(Np,1)*exp(d2*(1-P.WH_Split)*dz));

% Normalised Gamma Parameter
GammaBP=P.GammaBP;

if (~isfield(P,'SinglePrecision')||(P.SinglePrecision~=1))
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Double precision DBP (for accuracy)'), end
else
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Single precision DBP (for speed)'), end
    Et =single(Et);
    dz = single(dz);
    LaunchPower = single(LaunchPower);
    dzNLEff = single(dzNLEff);
    GammaBP = single(GammaBP);
    a = single(a);
    Dinv1 = single(Dinv1);
    Dinv2 = single(Dinv2);
end

%% GPU computing section
if isfield(P,'GPU') && (P.GPU==1) && gpuDeviceCount % Check GPU computing availability on host machine
    
    if (isfield(P,'verbose')&&(P.verbose>=1)), disp('Using GPU for DBP'), end
    
    %% Moves DATA on GPU
    NSpans=gpuArray(P.NSpans);
    NSteps_NLC=gpuArray(P.NSteps_NLC);
    
    Et=gpuArray(Et);
    % WH_Split=gpuArray(P.WH_Split); % Comment: Faster on CPU
    dz=gpuArray(dz);
    LaunchPower=gpuArray(LaunchPower);
    dzNLEff=gpuArray(dzNLEff);
    GammaBP=gpuArray(GammaBP);
    a=gpuArray(a);
    Dinv1=gpuArray(Dinv1);
    Dinv2=gpuArray(Dinv2);
    
    % N.B. this is the average power times the nonlinear coefficients
    AveragePowerAtStep = -1j*(8/9)*dzNLEff*GammaBP*LaunchPower.*exp(-a*(NSteps_NLC-(gpuArray.colon(1,NSteps_NLC)))*dz);
    
    %% Span loop on GPU
    Ef=ifft(Et,[],2);                                                  % Fourier Transform to frequency domain
    for s = gpuArray.colon(1,NSpans)
        if (isfield(P,'verbose')&&(P.verbose>=1)), disp(['DBP Span: ' num2str(s) ' of ' num2str(NSpans)]), end
        
        % Step loop
        for k = gpuArray.colon(1,NSteps_NLC)
            
            % Undoes dispersion in first half of step (GPU computing version)
            Ef=Ef.*Dinv1;                                                      % Applies inverted dispersion
            Et = fft(Ef,[],2);                                                 % Back to time domain
            
            % Nonlinear compensation using Manakov equation
            [Et(1,:), Et(2,:)] = arrayfun(@NLStep_Manakov,Et(1,:),Et(2,:),AveragePowerAtStep(k));
            
            % Undoes dispersion in second half of step
            Ef=ifft(Et,[],2);                              % Fourier Transform to frequency domain
            if (P.WH_Split~=1) % Evaluate this condition on the CPU for speed
                Ef=Ef.*Dinv2;
            end
        end
    end
    Et = fft(Ef,[],2); % Final transform back to the time domain
    SignalOut.Et = double(gather(Et)); % Move data back to CPU and ensure double precision
    
else
    if isfield(P,'GPU') && (P.GPU==1)
        warning('No CUDA GPU available on this machine');
    end
    
    
    %% Run on CPU
    % N.B. this is the average power times the nonlinear coefficients
    AveragePowerAtStep = -1j*(8/9)*dzNLEff*P.GammaBP*LaunchPower.*exp(-a*(P.NSteps_NLC-(1:P.NSteps_NLC))*dz);
    % keyboard
    
    % Span loop
    Ef=ifft(Et,[],2);                                      % Fourier Transform to frequency domain
    for s = 1:P.NSpans
        % Step loop
        for k = 1:P.NSteps_NLC
            
            % Undoes dispersion in first half of step (GPU computing version)
            Ef=Ef.*Dinv1;                                                      % Applies inverted dispersion
            Et = fft(Ef,[],2);                                                 % Back to time domain
            
            % Nonlinear compensation using Manakov equation
            [Et(1,:), Et(2,:)] = NLStep_Manakov(Et(1,:),Et(2,:),AveragePowerAtStep(k));
            
            % Undoes dispersion in second half of step
            Ef=ifft(Et,[],2);                              % Fourier Transform to frequency domain
            if (P.WH_Split~=1)
                Ef=Ef.*Dinv2;
            end
        end
    end
    Et = fft(Ef,[],2); % Final transform back to the time domain
    
    SignalOut.Et = double(Et);
end

end

function [ Et1_out , Et2_out ] = NLStep_Manakov( Et1 , Et2 , AveragePowerAtStep )
%NLSTEP Computes a single Manakov nonlinear step (useful for GPU)
% for compiled CUDA use:
% [Et(1,:), Et(2,:)] = arrayfun(@NLStep_Manakov,Et(1,:),Et(2,:),AveragePowerAtStep(k));
% (See DBP function)

Et1_out = exp(AveragePowerAtStep*(abs(Et1).^2 + abs(Et2).^2));
Et2_out = Et2.*Et1_out;
Et1_out = Et1.*Et1_out;

end

function [ Et1_out , Et2_out ] = NLStep_NLSE( Et1 , Et2 , AveragePowerAtStep )
%NLSTEP Computes a single NLSE nonlinear step (useful for GPU)
% N.B. This code operates correctly, but the normalisation does NOT
% match NLSE.m
% for compiled CUDA use:
% [Et(1,:), Et(2,:)] = arrayfun(@NLStep_NLSE,Et(1,:),Et(2,:),AveragePowerAtStep(k));
% (See DBP function)

Et1_out = Et1.*exp(AveragePowerAtStep*(abs(Et1).^2 + 2/3*abs(Et2).^2));
Et2_out = Et2.*exp(AveragePowerAtStep*(2/3*abs(Et1).^2 + abs(Et2).^2));

end

%% Input/Output Verification
function IOVerify(P)
    warningnum = 0;
    if P.Att>1e-3, warning(['Attenuation value is large: ' num2str(P.Att) ' Np/m']), warningnum=warningnum+1; end
    if P.D>1e-3, warning(['Dispersion value is large: ' num2str(P.D) ' s/m^2']), warningnum=warningnum+1; end
    if P.GammaBP>1e-1, warning(['GammaBP value is large: ' num2str(P.GammaBP) ' W/m']), warningnum=warningnum+1; end

    if (P.RefWavelength<1200e-9)||(P.RefWavelength>1700e-9), warning(['wavelength beyond fiber transmission window: ' num2str(P.RefWavelength) ' m']), warningnum=warningnum+1; end

    if P.LaunchPower>1, warning(['Launch power greater than 1W: ' num2str(P.LaunchPower) ' W']), warningnum=warningnum+1;
    elseif P.LaunchPower<=0,
        error(['Launch power cannot be less than or equal to zero: ' num2str(P.LaunchPower) ' W']);
    end

    if (P.WH_Split<0)||(P.WH_Split>1), error(['WH_Split range is [0 1]. Current split is: ' num2str(P.WH_Split)]), end

    if (warningnum&&isfield(P,'verbose')&&(P.verbose>=1)), fprintf(['<strong>DBP warnings: ' num2str(warningnum) '\n</strong>']), end
end

%% Old Code
% Old method for nonlinear step (easier to read)
% AveragePowerAtStep = LaunchPower.*exp(-a*(P.NSteps_NLC-k)*dz);     % Average power at beginning of each DBP step [W]
%  Et = Et.*(ones(2,1)*exp(-1j*P.GammaBP*dzNLEff*(8/9)*AveragePowerAtStep*(abs(Et(1,:)).^2 + abs(Et(2,:)).^2)));