function WritePilotQAM(SP)
% clear;
% close all
% Fsize = 20;

P.ExpDescription = '_DACSlot5CH1_SHF807_MZM2RF1';

%set(0,'DefaultFigureWindowStyle','Docked')

%% Flags
P.WriteDAC = SP.WriteDAC;
P.VolterraFilter = SP.VolterraFilter;                       % Set 1 to use Volterra series Equalisation
P.RRC = 1;                                  % Set to 1 to apply RRC filter
P.PreEmp = 0;                               % Set to 1 to apply pre-emphasis
P.SweptSine = 0;                            % Set to 1 to overwrite EVERYTHING and just generate a swept sine
P.Clip = 0;                                 % Set to 1 to apply clipping
P.Marker = 0;                               % Write freq reference for DCA
P.SequenceTrigger = 0;                      % write sequence trigger to dac

%% DAC parameters
P.DACcard = 5;                              % 4-ch card slot [bottom DAC =3, middle = 4, top = 5]
P.DACcardMarker = 4;   %4                   % 4-ch card slot for the marker [bottom DAC =3, middle = 4, top = 5]
P.DACcardTrigger = 4;                       % 4-ch card slot for the sequence trigger [bottom DAC =3, middle = 4, top = 5]
% P.DACCh = 3;                                % DAC channel to be used as signal
P.DACMarkerCh = 4;     %4                   % DAC channel to be used as marker
P.DACTriggerCh = 2;                         % DAC channer to be used for the sequence trigger

P.DACamp = 0.8*[1 1];                       % [V] - set DAC amplitude for I (Ch1 or Ch3) and Q (Ch2 or Ch4)

% Middle DAC optimised for O-band
% XYSkew = 26.5; 
% P.skewX1  = 0*1e-12;                        % +/- Relative phase (time delay) difference btw Ch1 versus Ch2 )
% P.skewX2  = 25.5*1e-12;                     % +/- Relative phase (time delay) difference btw Ch1 versus Ch2 )
% P.skewY1  = (0.8+XYSkew)*1e-12;             % +/- Relative phase (time delay) difference btw Ch3 versus Ch4 )
% P.skewY2  = (4+XYSkew)*1e-12;               % +/- Relative phase (time delay) difference btw Ch3 versus Ch4 )

% Top DAC
XYSkew    = 25.5; %23.5;
P.skewX1  = 0*1e-12;                      % +/- Relative phase (time delay) difference btw Ch1 versus Ch2 )
P.skewX2  = 22.5*1e-12;                   % +/- Relative phase (time delay) difference btw Ch1 versus Ch2 )
P.skewY1  = (7.8+XYSkew)*1e-12;           % +/- Relative phase (time delay) difference btw Ch3 versus Ch4 )
P.skewY2  = (XYSkew)*1e-12;               % +/- Relative phase (time delay) difference btw Ch3 versus Ch4 )
P.halfRangeDAC = 0;                         % Uses only the half range of the DAC
P.fullRangeDAC = 1-P.halfRangeDAC;          % Uses full range of the DAC

%% Parameters
P.ModFormatPilot = SP.ModFormatPilot;                  % Modulation format
P.ModFormatData = SP.ModFormatData;                  % Modulation format
Sig.Fb = SP.baudRateGS;                            % Symbol rate (Baud rate)
P.RandData = 1;
P.PatternLength = SP.PatternLength;                       % Patternlength
P.FrameLen = SP.FrameLen;             % Frame Length = Pilot length + Payload lenght
P.PilotSeqLen = SP.PilotSeqLen;                       % Pilot Sequence Lenth
P.PilotRat = SP.PilotRat;                            % Pilot insertion rate

%% Adjust KeySight sampling rate for the desired baud rate)
if ~P.SweptSine
    P.Fb = Sig.Fb;
    
    % DAC properties
    P.minFs =86e9; P.maxFs = 92e9; P.blocksize = 128;
    
    Fs = FindFs(P);

    P.Ns = Fs/Sig.Fb;
    fprintf('Set DAC rate: %d GSa/s\n',Fs/1e9)
else
    Fs = 92e9;                              % Default Sampling Rate
    P.Ns=2;
    fprintf('Generating swept sine at %d GSa/s\n',Fs/1e9)
end

%% Filter
P.Shape = 'Square Root Raised Cosine';      % Filter shape 'Square Root Raised Cosine', 'Raised Cosine'
P.Rolloff = 0.01;                         	% Rolloff factor
P.Ast = 30;                                 % Stop Band attenuation

%% Pre-Emphasis
P.PreEmphType = 'ExpSweptSine';             % Type of pre-emphasis ('LinearSlope' or 'ExpSweptSine')
% P.PreEmp_Fmax = 20e9;                     % Maximum frequency to apply pre-emphasis (Hz)
P.PreEmp_Fmax = Sig.Fb/2*(1+P.Rolloff);     % Maximum frequency to apply pre-emphasis (Hz)
PathPreEmphasis = 'Y:\Lidia_Work\Transmitter Characterisation 22May2017\FilterPreemphase\DPIQ-mod 6M0C7400\Filter\';
% P.PreEmp_TFFilename = 'SampleRate90GSs_DACcard3_DACch4_DAC_VSuhner_807Amp_TF.mat';
% P.NyGain = 4;                             % Pre-Emphasis Gain needed at Nyquist point [dB]
P.ClipRatdB = 10;                           % DAC resolution, used for clipping (3bit ~ 4.5dB, 6bit ~ 7.0dB)
% NOB = 8;                                  % Physical resolution of DAC (bits)

% %% Generate Complex Pilot
% P.ModFormat = P.ModFormatPilot;
% str = P.ModFormat;
% if strcmp(str(end-2:end),'QAM')
%     P.M = str2double(str(1:end-3));
% else
%     switch str
%         case 'QPSK'
%             P.M = 4;
%         otherwise
%             error([str ' not a recognised modulation format'])
%     end
% end
% load(['sequence' num2str(P.PatternLength) '.mat']);
% [Pilot, SeqPilot] = QAM_Generator(P, Sequence);
% 
% %% Generate Complex Signal
% P.ModFormat = P.ModFormatData;
% str = P.ModFormat;
% if strcmp(str(end-2:end),'QAM')
%     P.M = str2double(str(1:end-3));
% else
%     switch str
%         case 'QPSK'
%             P.M = 4;
%         otherwise
%             error([str ' not a recognised modulation format'])
%     end
% end
% [Signal, Seq] = QAM_Generator(P, Sequence);
% 
% %% Calculate frame indeces & compose a data frame with pilots
% [~, P.IdxData, P.IdxPilot] = PilotFrameIdx(P.FrameLen, P.PilotSeqLen, P.PilotRat);
% Signal.Et(:,P.IdxPilot) = Pilot.Et(:,P.IdxPilot);
% 
P.PilotBasedDSP = SP.PilotBasedDSP;
[Signal, P] = PilotFrame(P);

    
% figure('Name','Constellation');
% plot(Signal.Et(1,P.IdxData),'.','markerfacecolor','b','markersize',10); axis square, axis([-1.2 1.2 -1.2 1.2]); hold on;
% plot(Signal.Et(1,P.IdxPilot),'.','markerfacecolor','r','markersize',10); axis square, axis([-1.2 1.2 -1.2 1.2]);
% xlabel('Re', 'fontsize', Fsize), ylabel('Im', 'fontsize', Fsize)

Ix = real(Signal.Et(1,:));
Qx = imag(Signal.Et(1,:));
Iy = real(Signal.Et(2,:));
Qy = imag(Signal.Et(2,:));

%% Pre Distortion Compensation
%% Voltera dual pol Lidia
%L = [513,17,7,1,1];           % impuslse length of 1st to 5th order volterra kernals
L = ([256,8,3,0,0]*1)*2+1;    
Nm = 2*size( Signal.Et,1);
rxSig = dualPoltoParallel(Signal.Et,1);
PPE.L = L;
if P.VolterraFilter == 1
    fprintf('Volttera Pre EQ for Xpol\n');
%     VoltEqX = getfield(load('R:\Lidia_Work\DAC characterisation March 2019\Nonlinear Pre-Emphasis\TopDAC\TopDAC_15GBd_1V.mat'),'PreEmpCoeff');
    VoltEqX = getfield(load('TopDAC_15GBd_1V.mat'),'PreEmpCoeff');
%     VoltEqX = getfield(load('TopDAC_30GBd_1V.mat'),'PreEmpCoeff');
%     VoltEqX = getfield(load('TopDAC_66GBd_0.8V.mat'),'PreEmpCoeff');
    
    for m = 1:Nm
        PPE.w = VoltEqX(3).Taps(m,:);
        fprintf('The tributary is: %f \n',m);
        mu = zeros(sum(L.^(1:length(L))),1);                   % no adpative fitlering
        for n = 1:size(mu,2)
            fprintf('The mu is: %f \n',mean(mu(:,n)));
            PPE.mu = mu(:,n);
            PPE.Et = rxSig(m,:).';
            [rxSig(m,:),EQ] = modulatorDPD(rxSig(m,:).',PPE);
            PPE.w = EQ.w;
        end
    end
    txSigPDC = Signal;
    txSigPDC.Et = dualPoltoParallel(rxSig,0);
    temp = txSigPDC;
    
    Ix = rxSig(1,:);
    Qx = rxSig(2,:);
    Iy = rxSig(3,:);
    Qy = rxSig(4,:);
    
end

%% RRC Cosine Filter
[Down,Up] = rat(1/P.Ns,1e-7);

if isfield(P, 'RRC') && (P.RRC == 1)
    % Upsample
    ImResp = [1 zeros(1, Up-1)];                        % Impulse for upsampling with kronecker delta product
    Ix = kron(Ix, ImResp);                              % Upsample I
    Qx = kron(Qx, ImResp);                              % Upsample Q
    Iy = kron(Iy, ImResp);                              % Upsample I
    Qy = kron(Qy, ImResp);                              % Upsample Q
    
    if (P.Rolloff==0.01)&&(P.Ast==30)
        disp('Using precomputed filter tap weights')
        RRCFilter.Numerator=rcosdesign(P.Rolloff,510,Up,'sqrt')/1.732; % the 1.732 matches the normalisation in fdesign.pulseshaping
        RRCFilter.order = length(RRCFilter.Numerator)-1;
    else
        disp('Using fdesign.pulshaping to make an RRC filter')
        RRCSpec = fdesign.pulseshaping(Up, 'Square Root Raised Cosine', 'Ast,Beta', P.Ast, P.Rolloff);
        RRCFilter = design(RRCSpec);                    % Design filter
        FilterDelay = RRCFilter.order;
    end
    
    disp('Applying RRC filter')
    IFilx = cconv(RRCFilter.Numerator, Ix, length(Ix));	% Apply filter
    QFilx = cconv(RRCFilter.Numerator, Qx, length(Qx));	% Apply filter
    IFily = cconv(RRCFilter.Numerator, Iy, length(Iy));	% Apply filter
    QFily = cconv(RRCFilter.Numerator, Qy, length(Qy));	% Apply filter
else
    ImResp = [1 ones(1, Up-1)];                         % Impulse for upsampling with kronecker delta product
    IFilx = kron(Ix, ImResp);                           % Upsample I
    QFilx = kron(Qx, ImResp);                           % Upsample Q
    IFily = kron(Iy, ImResp);                           % Upsample I
    QFily = kron(Qy, ImResp);                           % Upsample Q
end

Sig.Et(1, :) = IFilx + 1i.*QFilx;
Sig.Et(2, :) = IFily + 1i.*QFily;
Sig.Fs = Sig.Fb*Up;

%Downsample
disp('Resampling to DAC rate')
% Sig.Et = [resample(Sig.Et(1,:),1,Down,10);...
%                 resample(Sig.Et(2,:),1,Down,10)];

Sig.Et = Sig.Et(:, 1:Down:end);
Sig.Fs = Sig.Fs/Down;
P.Ns = Sig.Fs/Sig.Fb;
% figure('Name','RRC Filtered Opitcal Spectrum');
% OSA(Sig), title('RRC Filtered Opitcal Spectrum', 'fontsize', Fsize), set(gca, 'fontsize', Fsize), axis([-50 50 -120 0])

IFilx = real(Sig.Et(1,:));
QFilx = imag(Sig.Et(1,:));

IFily = real(Sig.Et(2,:));
QFily = imag(Sig.Et(2,:));

% figure('Name','Before Histogram of In-Phase Component');
% hist(IFilx, 2^6), title('Before Histogram of In-Phase Component', 'fontsize', Fsize)%, axis([0 63 0 2500])
% xlabel('Bin Number', 'fontsize', Fsize), ylabel('Bin Count', 'fontsize', Fsize), set(gca, 'fontsize', Fsize)
% hold on

%% NLC (Predistortion)
P.NLC = 0;
% Sig.Et(1,:) = complex(0,0);
SigLin = Sig;
% Sig.Et(2,:) = Sig.Et(1,:);
if isfield(P, 'NLC') && (P.NLC == 1)
%     Lengths = [50.24 50.296 50.36]; % [km]
%     Disps = -1*[16.3 15.0 15.0977]*1e-6; % [s/m/m]  -[16.3 15.5 15.0977]*1e-6
%     Attenuations=[0.160 0.161 0.1688]; % [dB/km]

    Lengths = [30]; % [km]
    Disps = -0*[16.3]*1e-6; % [s/m/m]  -[16.3 15.5 15.0977]*1e-6
    Attenuations=[0.2]; % [dB/km]

    LaunchPower = 12;
    LaunchPowers = [LaunchPower LaunchPower-cumsum(Attenuations(1:end-1).*Lengths(1:end-1))]; % [dBm]
    LaunchPowers = 10.^((LaunchPowers-30)/10); % Convert to power in [W]
%     P.sample_ratio = 0.5;
%     Sig.Ns = 1;
%     Sig = Resampler(Sig,P);
    
    for index = 1:1
        fprintf('applying DBP at the transmitter (span %d)\n',index)
        P.Length = Lengths(index)*1e3; % distance in [m]
        P.D =Disps(index); % s/m/m
        P.Att = Attenuations(index); % [dB/km]
        P.Att = (P.Att/4.343)/1e3;
        
        P.GammaBP = -0.8/1e3; % [/W/m]
        P.RefWavelength = 1550e-9; % [m]
        P.NSpans = 1;
        P.NSteps_NLC = 64;
        P.GPU = 0;
        
%         P.LaunchPower = 13.0-1; % [ dBm ]
        P.LaunchPower = LaunchPowers(index); % [ dBm ]
        P.WH_Split=0.5;
        tic
        temp = DBP(Sig,P);
        toc
        plot(MakeTimeFrequencyArray(temp),10*log10(abs(fft(temp.Et(2,:)))))
 TI = real(temp.Et(2,:));        
% TR = imag(temp.Et(2,:));        
% temp.Et(2,:) = TR+1i*TI;
Sig=temp;
        
    end

% P.sample_ratio = 2;
% Sig = Resampler(Sig,P);
% PBrick.BW = 50e9; 
% temp = BrickwallOpticalFilter(temp,PBrick);

%%
close all
plot(MakeTimeFrequencyArray(Sig)/1e9,10*log10(abs(fft(Sig.Et(1,:))))); hold all ; plot(MakeTimeFrequencyArray(Sig)/1e9,10*log10(abs(fft(SigLin.Et(1,:)))));
xlabel('Freq [GHz]')
ylabel('Rel. pwr [dB]')
%%
Sig = temp;

% Sig.Et(2,:) = conj(Sig.Et(2,:));
% Sig.Et(1,:) = -(Sig.Et(1,:));
end

%% Check that number of samples is multiple of 128
Fb = (Fs/P.Ns);                                     % Symbol rate (Baud)
disp(['Number of blocks of 128 samples: ' num2str((2^16*(Fs/Fb))/128)])
% figure('Name','RRC Filtered Opitcal Spectrum');
% OSA(Sig), title('RRC Filtered Opitcal Spectrum', 'fontsize', Fsize), set(gca, 'fontsize', Fsize), axis([-50 50 -150 -20])

%% SweptSine
if P.SweptSine
    P.Nt=2^19;
    P.Fs = 92e9;
    P.dT=1/P.Fs;
    P.f1 = 30e3; % Minimum swept sine frequnecy
    P.f2 = 46e9; % Maximum swept sine frequnecy
    P.T = P.Nt*P.dT;
    P.Twin=0.01*P.T;
    P.Amplitude=1;
    
    [Signal,Window] = ExpSweptSine(P);
    
    Sig = Signal;
    Sig.Et(2,:) = Sig.Et(1,:);
    Sig.Et(1,:) = real(Sig.Et(1,:))+1i*real(Sig.Et(1,:)); % map sine wave to all quadratures
    Sig.Et(2,:) = real(Sig.Et(2,:))+1i*real(Sig.Et(2,:));
    Sig.Fs=P.Fs;
    Sig.Fb = 30e9; % hack
    
    IFilx = real(Sig.Et(1,:));
    QFilx = imag(Sig.Et(1,:));
    IFily = real(Sig.Et(2,:));
    QFily = imag(Sig.Et(2,:));
end

%% Signal Pre-emphasis
if isfield(P, 'PreEmp') && (P.PreEmp == 1)
    close all
    temp = Sig;
    NumMods = 2;
    Path = PathPreEmphasis;

    N_taps= 2^15;
    IFil = zeros(NumMods, length(Sig.Et(1,:)));
    QFil = zeros(NumMods, length(Sig.Et(1,:)));
         
    for nn = 1:NumMods  % for each MZM
        PreEmpFil = zeros(2, N_taps+1);
        for n = 1:2 % For loop for I and Q
            TF = getfield(load([Path 'DPIQ-' num2str(7-2*nn-n) 'port_Filter.mat']),'TF');
            fprintf('Preemp DAC #%d\n',2*nn+n-2)
            disp('System TF characterised using EXP swept sine wave loaded')
            
            TF.H = TF.H./max(abs(TF.H));
            HF = TF.H;
            ff = TF.F;
%            HF(1, abs(ff)>P.PreEmp_Fmax)= 1; % DL: Frequencies not to be compensated
            
            FiltH = HF(1:end/2+1);                              % transfer function of the system
%            FiltF = [ff(1:end/2), abs(ff(end/2+1))];            % frequency array
            FiltF = ff(1:end/2+1);            % frequency array
%            P.PreEmp_Fmax = 29e9;
            FiltF(end)=FiltF(end-1)+FiltF(2);
            
            FiltH(1, abs(FiltF)>P.PreEmp_Fmax)= 0; % DL: Frequencies not to be compensated
            FiltH = FiltH./max(abs(FiltH));
            FiltH(1, abs(FiltF)>P.PreEmp_Fmax)= 10*FiltH(1); % DL: Frequencies not to be compensated

            assert(FiltF(end)>=Sig.Fs/2,'Maximum frequency of the transfer function should be larger than half the sample rate')
            [~,SampleRateInd] = find(FiltF<=Sig.Fs/2,1,'last');
            
            endloc = find(abs(FiltF)>P.PreEmp_Fmax,1);

            FiltF = FiltF(1:SampleRateInd)/FiltF(SampleRateInd);
            FiltH = 1./abs(FiltH(1:SampleRateInd));
            FiltH(endloc:end) = 0;
            
%            FiddleFactors = [0.82 0.82 0.82 0.82];
            FiddleFactors = 0.9*[1 1 1 1];
%            FiddleFactors = 1.2*[1 1 1 1];
            FiddleFactor = FiddleFactors(2*nn+n-2);
            FiltH(length(FiltH)/2:end)=FiltH(length(FiltH)/2:end).^FiddleFactor;
            
            PreEmpFil(n,:) = (fir2(N_taps,FiltF,FiltH));
            hold all;
            PredT = 1/Sig.Fs;
            PredF = 1/PredT/N_taps;
            PreFF = [0:floor(N_taps/2)-1,floor(-N_taps/2):-1] * PredF;
            plot([PreFF 0],10*log10((abs(fft(PreEmpFil(n,:))))))
            drawnow;
        end

        IFil(nn,:) = cconv(PreEmpFil(1,:),real(temp.Et(nn,:)),length(Sig.Et(1,:)));
        IFil(nn,:) = circshift(IFil(nn,:),[0 -ceil(N_taps/2)]);
        QFil(nn,:) = cconv(PreEmpFil(2,:), imag(temp.Et(nn,:)),length(Sig.Et(1,:)));
        QFil(nn,:) = circshift(QFil(nn,:),[0 -ceil(N_taps/2)]);

    end
    IFilx = IFil(1,:);
    QFilx = QFil(1,:);
    IFily = IFil(2,:);
    QFily = QFil(2,:);
end

% figure('Name','After Histogram of In-Phase Component');
% hist(IFilx, 2^6), title('After Histogram of In-Phase Component', 'fontsize', Fsize), %axis([0 63 0 2500])
% xlabel('Bin Number', 'fontsize', Fsize), ylabel('Bin Count', 'fontsize', Fsize), set(gca, 'fontsize', Fsize)

%% Normalise Signals for full DAC range
IFilx = IFilx - mean(IFilx); % Remove DC
QFilx = QFilx - mean(QFilx); % Remove DC
IFily = IFily - mean(IFily); % Remove DC
QFily = QFily - mean(QFily); % Remove DC
IFilx = IFilx./max(abs(IFilx)); % Normalise between -1 and 1
QFilx = QFilx./max(abs(QFilx)); % Normalise between -1 and 1
IFily = IFily./max(abs(IFily)); % Normalise between -1 and 1
QFily = QFily./max(abs(QFily)); % Normalise between -1 and 1

% figure('Name', 'Histogram of In-Phase Component');
% hist(IFilx, 2^6), title('Histogram of In-Phase Component', 'fontsize', Fsize), axis([-1 1 0 50000])
% xlabel('Bin Number', 'fontsize', Fsize), ylabel('Bin Count', 'fontsize', Fsize), set(gca, 'fontsize', Fsize)
% 
%% Write waveforms to DAC
if isfield(P, 'WriteDAC') && (P.WriteDAC==1)
    [data] = iqxydelay([IFilx;QFilx;IFily;QFily], Fs, [P.skewX1,P.skewX2,P.skewY1,P.skewY2]);
    
    iqdataX = data(1,:)+1i*data(2,:);                  % construct ch1 and ch2 data data for the KeySight DAC
    iqdataY = data(3,:)+1i*data(4,:);                  % construct ch3 and ch4 data for the KeySight DAC
    
     KeySightLoadWaveform(P.DACcard, iqdataX, 'x', Fs, P.DACamp) % Turns on Ch 1 & 2
    KeySightLoadWaveform(P.DACcard, iqdataY, 'y', Fs, P.DACamp) % Turns on Ch 3 & 4
   
    SignalOut.Fb = Sig.Fb;
    SignalOut.Et(1,:) = iqdataX;
    SignalOut.Et(2,:) = iqdataY;
    SignalOut.Fs = Sig.Fs;
    
    % Write marker for the signal
    if P.Marker
        [~,TT] = MakeTimeFrequencyArray(Sig);
        
        % reduce the marker clock rate for the DCA to see signal eye diagram
        if Sig.Fb>=40e9
            markerSig.Fb = Sig.Fb/2;
            if markerSig.Fb>40e9
                markerSig.Fb = markerSig.Fb/2;
            end
        else
            markerSig.Fb = Sig.Fb;
        end
        
        markerSig.Et = cos(2*pi*markerSig.Fb.*TT);
        
        DACamp    = [0.5 0.5]; % [V]
        iqdata = markerSig.Et + 1j*markerSig.Et;
        KeySightLoadWaveform(P.DACcardMarker , iqdata, ['onlyCh',num2str(P.DACMarkerCh)], Fs, DACamp )
    end
    if P.SequenceTrigger
        TriggerSig.Et = -1*ones(1,length(Sig.Et));
        TriggerSig.Et(1:1000) = 1; 
        
        DACamp    = [0.5 0.5]; % [V]
        iqdata = TriggerSig.Et + 1j*TriggerSig.Et;
        KeySightLoadWaveform(P.DACcardTrigger , iqdata, ['onlyCh',num2str(P.DACTriggerCh)], Fs, DACamp )
    end
end
