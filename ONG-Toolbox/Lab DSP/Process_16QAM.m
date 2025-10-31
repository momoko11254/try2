% close all;
clear variables;
TicScript = tic;

%% Parameters
P.Fb = 6e9;                                 % Symbol rate [Hz]
P.verbose = 1;

%%% Scope Options
P.Scope = 5;
P.CohRx = 1;
P.Symbols = 2^17;                           % Symbols to capture
P.Fs = 80e9;                                % Sample rate [Hz]
P.RecordLength = ceil(P.Symbols*(P.Fs/(2*P.Fb)));

%%% Channels
P.Channels = 1;                             % Number of channels to be processed
P.Spacing = 10e9;                           % Spacing of channels [Hz]
P.RefWavelength = 1550e-9;                  % Center wavelength [m]
P.Fc = 3e8/P.RefWavelength;                 % Center frequency [Hz]
P.Fchan = P.Fc+P.Spacing*((1:P.Channels)-ceil(P.Channels/2));

%%% RRC options
P.RRCFilter = 0;                            % Uncomment for RRC matched filtering
P.RRCType = 'Ideal';                        % RRC filter implementation: 'Ideal', 'Taps', 'Att'
P.RRCTaps = 32;                             % Number of taps for RRC Filter type 'Taps'
P.RRCAst = 60;                              % Stop band attenuation for RRC Filter type 'Att'
P.RollOff = 0.01;                           % Rolloff of RRC filter

%%% Transmission Compensation Options
P.BackToBack = 1;                           % Uncomment for B2B Operation
% P.NLComp = 1;                             % Uncomment to Implement Nonlinear Compensation

%%% Chromatic Dispersion
P.NSpans = 0;
P.Span = 80e3;                              % Fiber length per span [m]
P.totalFibreSpan = P.NSpans*P.Span;         % Total fiber length [m]
P.D = 16.78e-6;                             % Dispersion [s/m^2]

%%% EQ options
P.RealEQ = 0;                               % RealEQ = 1 - will use 4x4EQ
P.SuperConvergence = 1;                     % run the equaliser many times
P.FilterLength = 15;                        % equaliser filter length
% P.RotateEQTaps = 1;                       % pi/4 rotation of initial EQ taps
P.PhaseRotation = 1;                        % rotation of constellation to optimum position

%%% CPE options
% P.XPCorr = 0;                             % XPol Correlation in Phase
% P.CommonPhase = 1;
P.CPELength = 32;                           % CPE Length

%%% BER Options
P.ModFormat = '16QAM';
P.kmeans_iterations = 3;
P.PatternLength = 15;                       % PRBS Length
% P.Interleaver = 1;
P.SDiscard = 1e4;
P.EDiscard = 1e4;

%%% File Options
% P.SaveFile = 1;                           % Save input to file
% P.LoadFile = 1;                           % Load input from file
% FName = '.mat';

%% Signal Acquisition
if (isfield(P, 'LoadFile') && (P.LoadFile == 1))
    %%% Load file
    load(FName);
    CoSig = ConvertStruct(CoSig, P);
elseif (P.Scope == 0)
    %%% Simulations
    % Generation, Transmission/Noiseloading and receiver
    TxSig = QAM_Transmitter(P);
    TrSig = Transmission(TxSig, P);
    CoSig = QAM_Receiver(TrSig, P);
else
    %%% Capture from the Scope
    CoSig = PollScope(P);
end
temp = CoSig;

%% Correct Delays
[Comp, ~] = DelayCompensate(temp, P);
temp = Comp;

%% Normalise
Normalized = Orthonormalise(temp, P);
temp = Normalized;

Signal = temp;
%% Process Channel
for Channel = 1:length(Signal.Fchan)
    TicChannel = tic;
    P.FreqOffset = Signal.Fchan(Channel)-P.Fc;
    temp = FrequencyShifter(Signal, P);
    
    %% Resample
    P.sample_ratio = temp.Fs/temp.Fb/2; % 2 Sa/sym
    [ReSampSig, ~] = Resampler(temp, P);
    temp = ReSampSig;
    
    %% Dispersion or Non-Linear Compensation
    if (isfield(P, 'BackToBack') && (P.BackToBack == 0))
        if ~isfield(P, 'NLComp')
            DComp = CD_FIR(temp, P);
            temp = DComp;
        else
            error('Not yet implemented and tested');
        end
    end
    
    %% Root Raised Cosine Filtering (RRC)
    if (isfield(P, 'RRCFilter') && (P.RRCFilter == 1))
        P.RRCOffset = FrequencyOffsetEstimation(temp, P);
        MFilter = RRCFilter(temp, P);
        temp = MFilter;
    end
    PreEQ = temp;
    
    %% CMA Equalisation
    if (isfield(P, 'SuperConvergence') && (P.SuperConvergence == 1))
        mu = [5e-3 3e-3 1e-3 5e-4 3e-4 1e-4];
    else
        mu = [5e-3 3e-3];
    end
    
    numAve = length(mu);
    for q = 1:numAve
        disp(['Simulating CMA ' num2str(q) ' of ' num2str(numAve)]);
        P.mu = mu(q);
        P.ModFormat = 'QPSK';
        
        if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
            [Equalized, P] = QAM_RDE_4x4_fast(PreEQ, P);
        else
            [Equalized, P] = QAM_RDE_fast(PreEQ,P);
        end
        
        % define matix as inverse Jones matrix of polarisation rotation
        if (q==0)
            Hxx = P.Taps(1,:);
            Hxy = P.Taps(2,:);
            Hyx = fliplr(-1*conj((Hxy)));
            Hyy = fliplr(1*conj((Hxx)));
            P.Taps = [Hxx; Hxy; Hyx; Hyy];
        end
    end
    
    %% RDE Equalisation
    if (isfield(P, 'SuperConvergence') && (P.SuperConvergence == 1))
        mu = [5e-3 5e-3 5e-3 4e-3 4e-3 3e-3 1e-3 3e-4];
    else
        mu = [5e-3 3e-3];
    end
    
    numAve = length(mu);
    for q = 1:numAve
        disp(['Simulating RDE 16QAM ' num2str(q) ' of ' num2str(numAve)]);
        P.mu = mu(q);
        P.ModFormat = '16QAM';
        
        if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
            [RDEEqualized16QAM, P] = QAM_RDE_4x4_fast(PreEQ, P);
        else
            [RDEEqualized16QAM, P] = QAM_RDE_fast(PreEQ,P);
        end
        
    end
    temp = RDEEqualized16QAM;
    
    %% Normalise and Compensate for Skew
    Normalized = Orthonormalise(temp, P);
    temp = Normalized;
    
    %% Frequency Offset Removal
    [Homodyned, ~] = FrequencyOffsetRemoval(temp, P);
    temp = Homodyned;
    
    %% Remove transitions
    Symbols = ExtractSymbols(temp);
    temp = Symbols;
    
    %% Carrier Phase Recovery
    [CarrierRecovered, ~] = QAM_CPE_DD_fast(temp, P);
    temp = CarrierRecovered;
    
    %% Plots
    figure(10);
    xy = 1.5;
    subplot(221); plot(RDEEqualized16QAM.Et(1,2:2:end),'.','markersize',2); axis square; axis([-xy xy -xy xy]);
    subplot(222); plot(RDEEqualized16QAM.Et(2,2:2:end),'.','markersize',2); axis square; axis([-xy xy -xy xy]);
    subplot(223); plot(CarrierRecovered.Et(1,P.SDiscard:end-P.EDiscard),'k.','markersize',2); axis square; grid on; axis([-xy xy -xy xy]);
    subplot(224); plot(CarrierRecovered.Et(2,P.SDiscard:end-P.EDiscard),'k.','markersize',2); axis square; grid on; axis([-xy xy -xy xy]);
    drawnow;
    
    %% Orthonormalise and Rotation
    Orthogonalize = GSOP(temp, P);
    arg1 = angle(sum(Orthogonalize.Et(1,:).^4))/4;
    arg2 = angle(sum(Orthogonalize.Et(2,:).^4))/4;
    Orthogonalize.Et(1,:) = Orthogonalize.Et(1,:).*exp(-1i*(arg1+pi/4));
    Orthogonalize.Et(2,:) = Orthogonalize.Et(2,:).*exp(-1i*(arg2+pi/4));
    temp = Orthogonalize;
    
    %% KMeans Clustering
    KMeans = kmeans_fast(temp,P);
    temp = KMeans;
    
    %% Error Rate Analysis
    [SignalOut, BER] = BER_QAM(temp, P);
    disp(' ')
    disp(['Sequence Delays: ' num2str(BER.Delays)]);
    disp(['Error Vector = ' num2str((mean(BER.Errors(:, P.SDiscard:end-P.EDiscard),2)).')]);
    disp(['Pol X BER = ' num2str(BER.BERX)]);
    disp(['Pol Y BER = ' num2str(BER.BERY)]);
    disp(' ')
    disp(['Overall BER = ' num2str(BER.BER)]);
    disp(' ')
    
    % Copy BER to clipboard
    cstr = sprintf(num2str(BER.BER));
    clipboard('copy', cstr);
    
    toc(TicChannel);
end
toc(TicScript);

%% Save Input As File?
if (isfield(P, 'SaveFile') && P.SaveFile == 1)  % save waveform
    save(FName, 'CoSig', '-v6');
end