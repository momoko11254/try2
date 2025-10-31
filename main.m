close all;
clear;

P.Path = fullfile(pwd, 'Waveforms_SingleCh_100km_PxC00032_shaped1024QAM');
%P.Path = fullfile(pwd, 'Waveforms_SingleCh_100km_PxC00032_1024QAM'); %
%when sweeping the pilot sequence (sweep 2x)
%P.Path = fullfile(pwd, 'Waveforms_SingleCh_100km_P01024Cx_1024QAM'); %
%when sweeping the CPE length (sweep 2x)
% P.Path = fullfile(pwd, 'test');
SaveFname = fullfile(P.Path, 'results.csv');
if ~exist(P.Path,'dir')
    mkdir(P.Path)
end
%% Iteration Parameter
I.SweepField = 'Iteration';
% I.SweepField = 'VOA_Sig';
% I.SweepField = 'VOA_ASE';
% I.SweepField = 'FilterLength';
% I.SweepField = 'CPElength'; %% This ON to sweep CPE
% I.SweepField = 'RPElength';
% I.SweepField = 'PilotSeqLen'; %% This ON to sweet pilot sequence lenght
% I.SweepField = 'PilotRat';
% I.SweepField = 'RxDelayXIQ';
% I.SweepField = 'RxDelayYIQ';
% I.SweepField = 'RxDelayXY';
% I.SweepField = 'FName';
if isfield(I,'SweepField') && strcmp(I.SweepField, 'FName')
    listing = dir(fullfile(P.Path, '*.mat'));
    Nsweep = length(listing);
    for i = 1:Nsweep, I.SweepValue(i,:) = listing(i).name; end
elseif isfield(I,'SweepField') && strcmp(I.SweepField, 'PilotRat')
    Nf = 2^16; % FramLen
    Ms = 2^10; % PilotSeqLen (Set the same number into P.PilotSeqLen)
    Mc = 2.^(1:14); % PilotRat (tmp)
    Sw = ceil((Nf-Ms)./ceil((Nf-Ms)./Mc)); % PilotRat
    I.SweepValue = Sw;
    Nsweep = length(I.SweepValue);
else
    %% if doing transmission sweep pilot sequence length
%     I.SweepValue = 2.^(5:14); % sweep values for pilot sequence length
%     I.SweepValue = 40:-1:2; % VOA_ASE
%     I.SweepValue = 30:-1:10; % VOA_LaunchPower
    I.SweepValue = 1:1;
    Nsweep = length(I.SweepValue);
end
I.LoadIteration = 1;  % 0: Load Waveforms at only the first loop
I.SkipRxDSP = 0;
I.VolterraGen = 0;

%% Measurement Setup
P.WriteDAC = 1;         % Write to DAC
P.ABC = 0;              % stop after write signal to DAC
P.VolterraFilter = 0;   % Apply Volterra filter
P.DACcard = 5;          % 3:bottom, 4:middle, 5:top
P.DACamp = 0.8*[1 1];   % [V] - I (Ch1 or Ch3) and Q (Ch2 or Ch4)
P.Marker = 0;           % 0:Off, 1:On
P.DACcardMarker = 4;    % 3:bottom, 4:middle, 5:top
P.DACMarkerCh = 4;
if isfield(I,'SweepField')
    if strcmp(I.SweepField, 'PilotSeqLen') || strcmp(I.SweepField, 'PilotRat')
        P.WriteDAC = 1;
        P.ABC = 0;
    end
end

P.LoadWaveforms = 3;    % 1:Scope, 2:File, 3:Simulation
if P.LoadWaveforms == 2
    I.SkipRxDSP = 0;
    P.FName = 'No0001_Pilot_1500GBd_shaped2048QAM_P01024C00032_SNR-1470.mat';
end
P.SaveData = 1;

P.PilotBasedDSP = 1;    % 0:Blind, 1:Pilot
P.RandPilot = 0;        % 0:File, 1:Random, 2:PRBS
P.RandData = 0;         % 0:File, 1:Random, 2:PRBS

P.CoRx = 5;
P.Scope = P.CoRx;
P.TakeFirstSamples = 2^18;

% P.VOA_Sig_Address = 2;
P.VOA_Sig_Address = 19;
P.VOA_Sig_Slot = 1;
P.VOA_ASE_Address = 2;
P.VOA_ASE_Slot = 3;

P.BackToBack =1;
P.OSNRcalc = 0;

%% CDC Options
P.RefWavelength = 1550e-9; % Central Wavelength [m]
P.Length      = 101.39e3; % Length of SSMF (m)
P.NSpans      = 1; 
P.D           = 20.18e-6; % [s/m^2] SSMF reel # 1
P.totalFibreSpan = P.NSpans*P.Length; % Total tranmission distance [m]

%% TxSkew + Volterra
if P.DACcard == 5
    % % Top DAC + Mid IQM
    % 22 July 2019
    P.TxDelayXIQ = 24.5;
    P.TxDelayYIQ = 0.8;
    P.TxDelayXY  = 28.5;
    if P.VolterraFilter == 1
%         PreEmp = load('Y:\Yuta\LabCode\ECOC19Yuta\VolterraFilters\TopDACBotIQM_15GBd_0.8V(4).mat');
%         P.VolterraTaps = PreEmp.PreEmpCoeff(3).Taps;
        PreEmp = load('.\VolterraFilters\TopDACBotIQM_15GBd_0.8V_shaped2048QAM(1).mat');
        P.VolterraTaps = PreEmp.PreEmpCoeff(1).Taps;
    end
elseif P.DACcard == 4
    % Mid DAC + TOP IQM
    % 22 July 2019
    P.TxDelayXIQ = 23.5;
    P.TxDelayYIQ = -6.6;
    P.TxDelayXY  = 29.5;
    if P.VolterraFilter == 1
        PreEmp = load('.\VolterraFilters\MidDACTopIQM_15GBd_0.8V(4).mat');
        P.VolterraTaps = PreEmp.PreEmpCoeff(1).Taps;
    end
elseif P.DACcard == 3
    % Bottom DAC + Table IQM
    % 31 July 2019
    P.TxDelayXIQ = 25.5;
    P.TxDelayYIQ = -0.8;
    P.TxDelayXY  = 27.3;
    if P.VolterraFilter == 1
        PreEmp = load('.\VolterraFilters\BotDACTabIQM_15GBd_1.0V(1).mat');
        P.VolterraTaps = PreEmp.PreEmpCoeff(1).Taps;
    end
end
% PreEmp = load('./Waveforms/VolterraTaps.mat');
% P.VolterraTaps = PreEmp.EqPE.Taps;

if P.LoadWaveforms==3
    P.TxDelayXIQ = 0;
    P.TxDelayYIQ = 0;
    P.TxDelayXY  = 0;
end

%% RxSkew
P.RxDelayXIQ = 0.9;
P.RxDelayYIQ = -1.6;
P.RxDelayXY  = -1115;
if P.LoadWaveforms==3
    P.RxDelayXIQ = 0;
    P.RxDelayYIQ = 0;
    P.RxDelayXY  = 0;
end

%% Signal Fundamentals
P.Fb = 15e9;                           % Symbol rate (Baud rate)
P.ModFormatData = '64QAM';     % Modulation format for payload
P.M = ReturnModOrder(P.ModFormatData); % Number of constellation points
P.PatternLength = 16;                  % Patternlength
P.FrameLen = 2^P.PatternLength;        % Frame Length
P.SDiscard = 3e4;                      % Start discard samples
P.EDiscard = 1e5;                      % End discard samples
P.RandiDataLength = 16;                % Random data length
P.ModFormat = P.ModFormatData;         % Modulation format
P.ModFormatPilot = P.ModFormatData;    % Modulation format for pilot
P.PilotSeqLen = 0;                     % Pilot Sequence Lenth
P.PilotRat = 0;                        % Pilot insertion rate
P.OH = 0;                              % Overhead
P.InvJones = 0;                        % Invert Jones Matrix
P.Fc = 1550e-9;                        % Centre wavelength

%% RRC Options
P.RRCFilter = 1;                       % 1: RRC filter
P.RollOff = 0.01;                      % RRC rolloff factor
P.RRCAtt = 30;                         % Stop band attenuation for RRC filter (dB)
P.RRCType = 'Att';                     % Select RRC implememtaion (Ideal, Taps, Att)

%% DAC
P.minFs = 86e9;
P.maxFs = 92e9;
P.blocksize = 128;
P.Fs = FindFs(P);
P.Ns = P.Fs/P.Fb;

%% RDE Options for DSP w/o Pilot
P.FilterLength = 31;                   % Equaliser AFIR length

%% CPE options for DSP w/o Pilot
P.CPELength = 31;
P.NTapsFFELength = P.CPELength;        % Half Number of CPE filter taps
P.PhaseRotation = 1;

%% Pilot Fundamentals
if isfield(P,'PilotBasedDSP') && P.PilotBasedDSP==1
    PauseSec = 0.1;
    P.FilterLength = 31;
    P.CPELength = 3;
    P.RPElength = 31;
    P.ModFormatPilot = 'QPSK';         % Modulation format for pilot
    P.PatternLength = 19;              % Patternlength
    P.FrameLen = 2^16;                 % Frame Length = Pilot length + Payload lenght
    P.PilotSeqLen = 2^10;              % Pilot Sequence Lenth
    P.PilotRat = 2^5;                   % Pilot insertion rate
    P.SDiscard = 1;                    % Start discard samples
    P.EDiscard = 0;                    % End discard samples
    P.ShiftCPEIdxY = 0*P.PilotRat/2;     % Shift the CPE pilot position of Y-Pol.
    if P.ShiftCPEIdxY==0
        P.PilotCPEMethod = 'PilotAided';   % 'DDCPE', 'PilotAided', 'ZeroPadDDCPE'
    else
        P.PilotCPEMethod = 'PilotAided2';  % 'DDCPE', 'PilotAided', 'ZeroPadDDCPE'
    end
%     P.OH = PilotOH(P);                 % Overhead of pilot symbols
end

%% Set other parameters
if P.LoadWaveforms==1
    P.ReadfromScope = 1;                % Write to DAC
    P.ReadfromFile = 1-P.ReadfromScope; % Save to file
elseif P.LoadWaveforms==2
    P.WriteDAC = 0;                     % Read from scope
    P.ReadfromScope = 0;                % Read from scope
    P.ReadfromFile = 1-P.ReadfromScope; % Save to file
elseif P.LoadWaveforms==3
    P.WriteDAC = 0;                     % Read from scope
    P.ReadfromScope = 0;                % Read from scope
    P.ReadfromFile = 0;                 % Save to file
    % Rx data frame
    P.NumFrames = 2;
    P.ShiftIdx = 5000;                 % shift idx between x and y
    % DAC
    P.DAC.Res = 8;
    P.DAC.ENOB = 4.5;
    P.DAC.Vsw = 1.0;
    P.Vmin = -1.2;
    P.Vmax =  1.2;
    P.minFs = 86e9;
    P.maxFs = 92e9;
    P.blocksize = 128;
    P.Fs = FindFs(P);
    P.Ns = P.Fs/P.Fb;
    P.upsample = 2;
    P.BW = 15e9;
    % MZM
%     P.ERdB = 0;
%     P.ParER = 0;
    P.Vbias = 1.0;
    P.Vpi   = 3.0;
    % ADC
    P.ADC.Res = 8;
    P.ADC.Vmin = -1;
    P.ADC.Vmax =  1;
    % Noise
    P.FreqOffset = 100e6/P.Ns;
    P.Linewidth  = 100e3;
    P.OSNR = 43;
    P.commonphase = 1;
    % Manakov
    P.dz = P.Length/1000;
%     P.PMD = 1e-12;
%     P.NSpans      = 1; 
%     P.D           = 16.72e-6;        % [s/m^2] SSMF reel # 1
%     P.Att         = 0.19;            % Atenuation coefficient of SMF (dB/km)
%     P.totalFibreSpan = P.NSpans*P.Length;                           % Total tranmission distance [m]
end

P0 = P;

%% Iteration
for i = 1:Nsweep
    P = P0;
    P.No = i;
    if exist('fig','var')
        for n=size(fig,2):1,close(fig(1,n)), end
        delete(fig)
    end
    disp('************************************************************');
    disp(['No: ' num2str(i)]);

    %% Set sweeping params
    if isfield(I, 'SweepField')
        if strcmp(I.SweepField, 'FName')
            P.(I.SweepField) = I.SweepValue(i,:);
        else
            P.(I.SweepField) = I.SweepValue(i);
        end
        %% Set VOA for Sigal befor Rx
        if strcmp(I.SweepField, 'VOA_Sig')
            disp(['Set VOA for Signal ' num2str(P.VOA_Sig) ' [dB]']);
            WGAttenuator(P.VOA_Sig_Address,P.VOA_Sig_Slot,P.VOA_Sig);
        end
        %% Set VOA for ASE
        if strcmp(I.SweepField, 'VOA_ASE')
            disp(['Set VOA for ASE ' num2str(P.VOA_ASE) ' [dB]']);
            WGAttenuator(P.VOA_ASE_Address,P.VOA_ASE_Slot,P.VOA_ASE);
        end
    end

    %% TxDSP
    disp('------------------------------------------------------------');
    disp('TxDSP');
    disp('------------------------------------------------------------');
    %% Generate Complex Signal
%     P = PilotFrame(P);
%     gnsig = [[1, 1i]*randn(2,P.FrameLen); [1, 1i]*randn(2,P.FrameLen)];
%     gnsig = gnsig./rms(gnsig);
%     P.TxFrame(:,P.IdxData) =  gnsig(:,P.IdxData);
    

%     % Swap I/Q channels
%     TxSig.Et(1,:) = 1i*conj(TxSig.Et(1,:));
%     TxSig.Et(2,:) = 1i*conj(TxSig.Et(2,:));
    
%     if P.ABC==1
%         % save ModFormatData, RRCFilter and VolterraFilter
%         tempModFormatData = P.ModFormatData;
%         tempRRCFilter = P.RRCFilter;
%         tempVolterraFilter = P.VolterraFilter;
%         % Since ABC is suitable for QPSK w/o RRC filtering, change
%         % ModFormatData, RRCFilter and VolterraFilter
%         P.ModFormatData = 'QPSK';
%         P.RRCFilter = 0;
%         P.VolterraFilter = 0;
%         P = PilotFrame(P);
%         [TxSig, P, fig] = PilotTxDSP(P);
%         WriteDAC(TxSig, P);
%         disp('Run ABC!!')
%         keyboard
%         % restore ModFormatData, RRCFilter and VolterraFilter
%         P.ModFormatData = tempModFormatData;
%         P.RRCFilter = tempRRCFilter;
%         P.VolterraFilter = tempVolterraFilter;
%     end
% 
    P.OH = PilotOH(P); % Overhead of pilot symbols
    P = PilotFrame(P);
    if P.WriteDAC==1
        [TxSig, P, fig] = PilotTxDSP(P);
        if P.LoadWaveforms==1
            WriteDAC(TxSig, P);
            if P.ABC==1
                disp('Check BIAS manually.')
                keyboard
            end
        end
    end
    

    % Flag for loading waveforms
    LoadFlag = 0;
    if I.LoadIteration==1
        LoadFlag = 1;
    else
        if i == 1
            LoadFlag = 1;
        end
    end

    if LoadFlag==1
        if P.LoadWaveforms==1
            % Captur a new waveform
            [CoSig, P] = LoadWaveforms(P);
        elseif P.LoadWaveforms==2
            % Load a new waveform
            [CoSig, P] = LoadWaveforms(P);
        elseif P.LoadWaveforms==3
            % Generate a new waveform in simulation
            [TxSig, P, fig] = PilotTxDSP(P);
            CoSig = TxSig;
            [CoSig, P] = SimRxSig(CoSig, P);
        end

        % OSNR
        if isfield(P,'OSNRcalc') && P.OSNRcalc==1
            P.OSNR = MeasureOSNR(P);
        else
            P.OSNR = 0;
        end
    end

    %% RxDSP
    if ~I.SkipRxDSP
        disp('------------------------------------------------------------');
        disp('RxDSP');
        disp('------------------------------------------------------------');
        if isfield(P,'PilotBasedDSP') && P.PilotBasedDSP==0
            disp('Simulation for RDE-Based full blind DSP')
            [RxFrame, P] = RxDSP(CoSig, P);
            RxData = RxFrame;
        elseif P.PilotBasedDSP==1
            assert(mod(P.FrameLen-P.PilotSeqLen,P.PilotRat)==0, 'Wrong Pilot Parameters!!')
            [RxFrame, P, fig] = PilotRxDSP(CoSig, P, PauseSec);
            RxData.Et = RxFrame.Et(:,P.IdxData);
        end
        %% Calculate the MI and the GMI
        [P.SNR, P.MI, P.GMI, P.NGMI, P.BER, GMI_t] = PilotMI_GMI_SDFEC(RxData, P);

        T = table(P.No, P.OSNR, P.SNR(1), P.SNR(2), P.MI(1), P.MI(2), P.GMI(1), P.GMI(2), P.GMI(1)./(1+P.OH), P.GMI(2)./(1+P.OH), P.NGMI, P.NGMI/(1+P.OH), P.BER(1), P.BER(2), P.PilotSeqLen, P.PilotRat, P.FrameLen, P.OH);
        T.Properties.VariableNames = {'No','OSNR','SNRx','SNRy','MIx','MIy','GMIx','GMIy','AIRx','AIRy','NGMI','NAIR','BERx','BERy','PilotSeqLen','PilotRat','FrameLen','OH'};
        disp(['OSNR = ' num2str(T.OSNR) ' dB']);
        disp(['AIR = ' num2str(T.AIRx+T.AIRy) ' bit/4D-symbol']);
        if exist(SaveFname,'file')==0
            writetable(T, SaveFname);
        else
            Told = readtable(SaveFname);
            writetable([Told;T], SaveFname);
        end

        if i == 1
            scrsz = get(0,'ScreenSize');
            figIte = figure('Name','Iteration','Position',[scrsz(3)*(1/2-1/10) scrsz(4)*(1-9/10) scrsz(3)/2 scrsz(4)*(1-1/4)]);
        end
        PlotResults(figIte, T);
        if strcmp(I.SweepField(1:5), 'RxDel')
            if i == 1
                figTap = figure('Name','figTap');
            end
            figure(figTap);
            subplot(Nsweep,1,i)
            plot(abs(P.Taps.').^2)
            grid;
            drawnow;
        end
        
    end
    
    % Save Waveform
    if (P.SaveData==1) && (P.ReadfromFile==0)
        SaveWaveform(CoSig, P)
    end
    
    if I.VolterraGen
        disp('------------------------------------------------------------');
        disp('Volterra');
        disp('------------------------------------------------------------');
        P.K = 2^15;
        P.NViterbi = 1;
        P.sps = 1;
        P.L = ([256,8,3,0,0]*P.sps)*2+1;
%         TxFrame.Et(P.SwapIQ, :) = 1i*conj(TxFrame.Et(P.SwapIQ, :));
        VoltSignal.Et = RxFrame.Et(:,P.PilotSeqLen+1:end);
        
%         VoltSignal.Et = [zeros(size(RxFrame.Et,1),P.NViterbi*2*P.sps),RxFrame.Et];
        [AlignedSeq, VoltSignal] = alignSignalComplex(VoltSignal, P.TxFrame(:,P.PilotSeqLen+1:end));
        EqPE = LSVolterra(AlignedSeq, VoltSignal, P);
        P0.VolterraTaps = EqPE.Taps;
        save(fullfile(P.Path,'VolterraTaps.mat'), 'EqPE');
    end
    
end

% if ~I.SkipRxDSP
%     %% Save
%     disp('-------------------------------------------------');
%     disp(['MeanMax SNR = ' num2str(10*log10(max(mean(10.^(0.1*SNR))))) ' dB']);
%     disp(['MeanMean SNR = ' num2str(10*log10(mean(mean(10.^(0.1*SNR))))) ' dB']);
%     disp(['MeanMax GMI = ' num2str(max(mean(GMI))) ' bit/symbol']);
%     disp(['MeanMean GMI = ' num2str(mean(mean(GMI))) ' bit/symbol']);
%     disp(['MeanMax AIR = ' num2str(max(mean(GMI./(1+P.OH)))) ' bit/symbol']);
%     disp(['MeanMean AIR = ' num2str(mean(mean(GMI./(1+P.OH)))) ' bit/symbol']);
% end
