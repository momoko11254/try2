clear;
close all;
addpath('Wenting FDE code','core','Voltera Filter','Waveform');

% [y,m,d] = ymd(datetime);
% [y,m,d] = deal(2019, 4, 9);
% dname = datetime([y m d],'Format','yyMMdd');
% SavePath = fullfile(char(strcat('..\Waveforms\', string(dname))));
% % SavePath = fullfile(char(strcat('..\Waveforms\')));
% SavePath = fullfile(SavePath,'Pilot_1500GBd_Voltera_1024QAMP1024C32/');
% SavePath = fullfile('C:\Users\uceewak\Documents\MATLAB\PilotBasedDSP\Waveforms\190322\Pilot_1500GBd_1024QAM_P256Cx+1dB');
% SavePath = fullfile('Y:\Yuta\Waveforms\190411\Pilot_3000GBd_Voltera_shapedQ1024P1024C32');
% SavePath = fullfile('Y:\Yuta\Waveforms\190330\Pilot_1500GBd_Voltera_1024QAM_P256C256');
%SavePath = '.';% fullfile('Y:\Yuta\Waveforms\Pilot_1500GBd_Voltera_Q64\Final_Pilot_1500GBd_Voltera_64QAMP1024C32_OSNR\Pilot_1500GBd_Voltera_64QAMP1024C32');
SavePath = fullfile('Waveform');
if exist(SavePath,'dir')==0
    mkdir(SavePath)
end

%% Iteration Parameter
% Frame Length
%  28.416e3@5GBd;   56.832e3@10GBd; 113.664e3@20GBd; 170.624e3@30GBd;
% 204.800e3@35GBd; 227.328e3@40GBd; 256.000e3@45GBd; 282.352e3@50GBd;
% 314.368e3@55GBd; 341.248e3@60GBd; 371.712e3@65GBd; 409.600e3@70GBd;
% 430.080e3@75GBd; 454.656e3@80GBd; 481.280e3@85GBd; 512.000e3@90GBd;
I.Iteration = 1;
I.FrameLen = 2^16;
% Pilot_3000GBd_1024QAM
%              CPE RPE
% P00512C00032: 25  63
% P00512C00064: 15  63
% P00512C00128:  9  95
% P00512C00192:  7  95
% P00512C00384:  5 128
% P00512C00886:  3 128
% P00512C01772:  1 191

% Pilot_1500GBd_1024QAM
%              CPE RPE
% P01024C00032:  7  31
% P01024C00064:  5  63
% P01024C00128:  5  63
% P01024C00256:  3  63
% P01024C00512:  1 127
% P01024C01024:  1 127


%% Sweep File
% Best Waveform of 1024QAM with Voltera (P256C256)
% 'Y:\Yuta\Waveforms\190330\Pilot_1500GBd_Voltera_1024QAM_P256C256\Pilot_1500GBd_1024QAM_P00256C00256_OSNR4230VOA36.mat'
% 1024QAM (P256C256)
%  'C:\Users\uceewak\Documents\MATLAB\PilotBasedDSP\Waveforms\190322\Pilot_1500GBd_1024QAM_P256Cx+1dB\Pilot_1500GBd_1024QAM_P00256C00256_OSNR4579.mat'
% listing = dir(fullfile(SavePath, 'Pilot_1500GBd_1024QAM_P00256C00256_OSNR4299_LOOP002VOA40.mat'));
% listing = dir(fullfile(SavePath, 'Pilot_1500GBd_shaped1024QAM_P00256C00256_OSNR4308_LOOP002.mat'));
% listing = dir(fullfile(SavePath, 'Pilot_1500GBd_64QAM_P01024C00032_OSNR1506_LOOP001VOA02.mat'));
% I.PilotSeqLen = 1024*ones(1,length(listing));
% I.PilotRat = 32*ones(1,length(listing));
% for i = 1:length(listing), I.FName(i,:) = listing(i).name; end
% % for i = 1:9, I.FName(i,:) = listing(i).name; end
% I.Sweep = 1:length(listing);
% I.CPElength = 5*ones(1,length(I.Sweep));
% I.RPElength = 11*ones(1,length(I.Sweep));
% SaveFname = fullfile(SavePath, 'sweepseq.csv');
% PreEmph + RLS + RPE + GS

% I.VOA =  2:38;
% for i = 1:length(listing),
%     load([SavePath listing(i).name])
%     filename = [listing(i).name(1,1:end-78) num2str(I.VOA(i)) '.mat'];
%     save(fullfile(SavePath,filename), 'CoSig','EP', '-v6');
%     disp(['Data saved as ' filename]);
% end
%

%% Sweep delay
%I.delay = -2129:10:-2129;
I.delay = 0;

I.PilotSeqLen = 2.^(10:10);
I.PilotRat = 32;
I.PilotRat = I.PilotRat*ones(1,length(I.delay));
I.Sweep = 1:length(I.delay);
I.CPELength = 1*ones(1,length(I.Sweep));
I.RPElength = 11*ones(1,length(I.Sweep));
SaveFname ='SimSweepPilotSeqLen1.csv';

% %% Sweep PilotRat
% I.PilotSeqLen = 1024;
% I.PilotRat = 2.^(5:5);
% tmpRat = 2^5:2:(I.FrameLen-I.PilotSeqLen);
% tmpIdx = mod(I.FrameLen-I.PilotSeqLen,tmpRat) == 0;
% tmpRat = tmpRat(tmpIdx);
% for i = 1:length(I.PilotRat)
%     [~,imin] = min(abs(tmpRat-I.PilotRat(i)));
%     I.Iteration(i) = tmpRat(imin);
% end
% I.PilotRat = I.Iteration;
% I.PilotSeqLen = I.PilotSeqLen.*ones(1,length(I.PilotRat));
% I.CPELength = 1*ones(1,length(I.Iteration));
% I.RPElength = 11*ones(1,length(I.Iteration));
% % SaveFname ='SimSweepPilotRat.csv';

% %% Sweep CPELength
% I.Iteration =  3:4:41;
% I.FName = 'Pilot_1500GBd_1024QAM_P00064C00192_OSNR4563.mat';
% for i = 2:length(I.Iteration), I.FName = [I.FName; I.FName]; end
% I.CPELength = 5*ones(1,length(I.Iteration));
% I.RPElength = I.Iteration;
% I.PilotSeqLen = ones(1,length(I.Iteration));
% I.PilotRat = ones(1,length(I.Iteration));
% SaveFname = ['Sim' I.FName(1,1:end-4) '_SweepRPELength.csv'];

I.LoadIteration = 0;
I.SkipRxDSP = 0;

%% Iteration
for Iteration = 1:I.Iteration
    
    %% Iteration
    for i = 1:length(I.Sweep)
        clear P;
        if exist('fig','var')
            for n=size(fig,2):1,close(fig(1,n)), end
            delete(fig)
        end
        disp(['Iteration: ' num2str(i)]);
        
        %% Measurement Setup
        P.WriteDAC = 1;                             % Write to DAC
        P.LoadWaveforms = 1;                        % 1:Scope, 2:File, 3:Simulation
        P.PilotBasedDSP = 0;                        % Set to 1 when using pilot-based DSP
        P.SaveData = 0;
        P.BackToBack = 1;
        P.SSMF = 0;
        P.FDEQ = 0;     % 1 - one stage FD CDC RRC MIMO   % 2 - three stages
        P.OSNRcalc = 0;
        P.CoRx = 5;                                 % 1: Old Seb CoRx, 2: Integrated U2T_1, 3: Integrated U2T_2, 4: Integrated U2T_3, 5: 65GHz U2T
        P.Scope = P.CoRx;
        P.verbose = 1;
        P.Path  = SavePath;
        P.TakeFirstSamples = 2^18;
        P.VolterraFilter = 0;
        
        %% Rx Skew
        P.DelayXIQ = 0.3;
        %     P.DelayXIQ = 0;
        P.DelayYIQ = -0.1;
        %     P.DelayYIQ = 0;
        P.DelayXY  = -2129;
        %P.DelayXY  = I.delay(i);
        %% Signal Fundamentals
        P.Fb = 22.8*1e9;                              % Symbol rate (Baud rate)
        %P.Fb = 85.5*1e9;                              % Symbol rate (Baud rate)
          %      P.ModFormatData = 'shaped64QAM';                  % Modulation format for payload
        P.ModFormatData = '4QAM';                  % Modulation format for payload
        P.M = str2double(P.ModFormatData(1:end-3));     % Number of constellation points
        %     P.M = 1024;     % Number of constellation points
        P.PatternLength = 16;                       % Patternlength
        P.FrameLen = 2^P.PatternLength;             % Frame Length = Pilot length + Payload lenght
        P.RandData = 1;                             % Set to 1 if using random data instead of PRBS
        %       P.SDiscard = 3e4;                           % Start discard samples
        %       P.EDiscard = 1e5;                           % End discard samples
        
        P.SDiscard = 4e4;                           % Start discard samples
        P.EDiscard = 4e4;                           % End discard samples
        P.RandiDataLength = 16;                     % Random data length
        P.ModFormat = P.ModFormatData;              % Modulation format
        P.ModFormatPilot = P.ModFormatData;         % Modulation format for pilot
        P.PilotSeqLen = 0;                          % Pilot Sequence Lenth
        P.PilotRat = 0;                             % Pilot insertion rate
        P.OH = 0;                                   % Overhead
        P.InvJones = 0;                             % Invert Jones Matrix
        P.Fc = 1550e-9;
        P.baudRateGS = P.Fb;
        P.RefWavelength = 1550e-9;
        %% RDE Options
        P.FilterLength = 21;                        % Equaliser AFIR length
        %     P.FilterLength = I.Iteration(i);
        
        %% CPE options
        P.CPELength = 501;
        
        %    P.CPELength = 7;
        %     P.CPELength = I.Iteration(i);
        P.NTapsFFELength = P.CPELength;             % Half Number of CPE filter taps
        P.PhaseRotation = 1;
        
        %% RRC Options
        P.RRCFilter = 1;                            % Set to 1 when using RRC filter
        P.RollOff = 0.01;                           % RRC rolloff factor
        P.RRCAtt = 30;                              % Stop band attenuation for RRC filter (dB)
        P.RRCType = 'Att';                          % Select RRC implememtaion (Ideal, Taps, Att)
             
        %% Fibre Parameters
        P.Length = 40.13e3;    % in [m]
        P.totalFibreSpan=P.Length;
        P.D = 16.72e-6;    % in [s/m^2]
        P.Att = 4.2597e-05;   % in [Np/m]
        
        %% Pilot Fundamentals
        if isfield(P,'PilotBasedDSP') && P.PilotBasedDSP==1
            PauseSec = 0.1;
            P.FilterLength = 31;
            P.RPElength = I.RPElength(i);
            P.ModFormatPilot = 'QPSK';              % Modulation format for pilot
            P.PatternLength = 19;                   % Patternlength
            P.FrameLen = I.FrameLen;                % Frame Length = Pilot length + Payload lenght
            P.PilotSeqLen = 1024;          % Pilot Sequence Lenth
            P.PilotRat = 32;            % Pilot insertion rate
            P.PilotCPEMethod = 'PilotAided';        % 'DDCPE', 'PilotAided', 'ZeroPadDDCPE'
            P.SDiscard = 1;                         % Start discard samples
            P.EDiscard = 0;                         % End discard samples
            P.OH = (P.PilotSeqLen+(P.FrameLen-P.PilotSeqLen)/P.PilotRat)/P.FrameLen;      % Overhead of pilot symbols
        end
        %% Simulation
        if P.LoadWaveforms==3
            % Rx data frame
            P.NumFrames = 2;
            P.ShiftIdx = 5000; % shift idx between x- and y-pols
            % DAC
            P.DAC.Res = 8;
            P.DAC.Vsw = 1;
            P.DAC.ENOB = 5.0;
            P.Vmin = -7.0;
            P.Vmax =  7.0;
            P.minFs = 86e9;
            P.maxFs = 92e9;
            P.blocksize = 128;
            P.Fs = FindFs(P);
            P.Ns = P.Fs/P.Fb;
            P.upsample = 1;
            % MZM
            P.Vbias = 1.5;
            P.Vpi = 3;
            % ADC
            P.CoRx = 0;
            % LO
            P.FreqOffset = 100e6;
            P.Linewidth = 12.5e3;
            P.commonphase = 1;
            P.OSNR = 43;
            % Manakov
            P.RefWavelength = 1550e-9;
            P.dz = 1000;    % in [m]
            P.PMD = 1e-12/sqrt(1e3);     % in [s/m^0.5]
            
        end
        
        if P.LoadWaveforms==1
            P.ReadfromScope = 1;                        % Write to DAC
            P.ReadfromFile = 1-P.ReadfromScope;         % Save to file
        elseif P.LoadWaveforms==2
            P.WriteDAC = 0;                             % Read from scope
            P.ReadfromScope = 0;                        % Read from scope
            P.ReadfromFile = 1-P.ReadfromScope;         % Save to file
        elseif P.LoadWaveforms==3
            P.WriteDAC = 0;                             % Read from scope
            P.ReadfromScope = 0;                        % Read from scope
            P.ReadfromFile = 0;                         % Save to file
        end
        
        if isfield(I, 'SweepOSNR') && (I.SweepOSNR==1)
            disp(['Set VOA ' num2str(I.VOA(i)) 'dB']);
            WGAttenuator(2,3,I.VOA(i));
        end
        
        %% TxDSP
        if isfield(P, 'WriteDAC') && (P.WriteDAC==1)
            SP = P;
            WritePilotQAM(SP);
        end
        
        LoadFlag = 0;
        if I.LoadIteration == 1
            LoadFlag = 1;
        else
            if i == 1
                LoadFlag = 1;
            end
        end
        
        if LoadFlag==1
            if P.LoadWaveforms==1
                [CoSig, P] = LoadWaveforms(P);
            elseif P.LoadWaveforms==2
                P.FName = '2706_FDEQ_45KHz_SOP_9.120000e+01GBd_64QAM_SNR14.5326dB_BER_0.07458_AIR_8.9357.mat';
                %             P.FName = I.FName(i,:);
                [CoSig, P] = LoadWaveforms(P);
            elseif P.LoadWaveforms==3
                [CoSig, ~] = PilotTxDSP(P);
                
                % DAC (Quantisation noise, ENOB)
                CoSig = DAC(CoSig, P);
                % DP-IQ modulator (Vpi, Vbias)
                SigElecX = CoSig;
                SigElecX.Et = SigElecX.Et(1,:);
                SigElecY = CoSig;
                SigElecY.Et = SigElecY.Et(2,:);
                SigOptX = CoSig;
                SigOptX.Et = SigOptX.Et(1,:);
                SigOptY = CoSig;
                SigOptY.Et = SigOptY.Et(2,:);
                SigOptX = IQModulator(SigElecX, SigOptX, P);
                SigOptY = IQModulator(SigElecY, SigOptY, P);
                CoSig.Et = [SigOptX.Et; SigOptY.Et];
                
                % Frequency offset
                P.HetMethod = 'Measured';
                CoSig = Heterodyne(CoSig, P);
                % Phase noise caused by linewidth
                [CoSig, P] = AddPhaseNoise(CoSig, P);
                % Additive white Gaussian noise
                CoSig = AddNoise(CoSig, P);
                if P.SSMF == 1
                    CoSig = Manakov(CoSig, P);
                end
                % ADC
                P.Res = 8;
                P.Vmin = -1;
                P.Vmax =  1;
                tmpIx = ADC(real(CoSig.Et(1,:)), P);
                tmpQx = ADC(imag(CoSig.Et(1,:)), P);
                tmpIy = ADC(real(CoSig.Et(2,:)), P);
                tmpQy = ADC(imag(CoSig.Et(2,:)), P);
                CoSig.Et = [tmpIx+1j.*tmpQx; tmpIy+1j.*tmpQy];
                
            end
            %% OSNR
            if isfield(P,'OSNRcalc') && P.OSNRcalc==1
                if isfield(P,'OSNR') && P.OSNR~=0
                    OSNR = P.OSNR;
                elseif P.ReadfromFile==0 && P.ReadfromScope==1
                    OSNR = getfield( YokogawaOSA('OSNR'), 'OSNR');
                    P.OSNR = OSNR;
                elseif P.ReadfromFile==1 && P.ReadfromScope==0
                    %                 OSNRstr = extractBetween(P.FName,'OSNR_','_');
                    %                 OSNR = str2double(OSNRstr{1});
                    OSNR = 0;
                end
            else
                OSNR = 0;
            end
        end
        
        %% RxDSP
        if ~I.SkipRxDSP
            disp(P)
            if isfield(P,'PilotBasedDSP') && P.PilotBasedDSP==0
                disp('Simulation for RDE-Based full blind DSP')
             [RxSig, P] = RxDSP(CoSig, P);
             %[RxSig, P] = RxDSP_Wenting_3(CoSig, P);
                
            elseif P.PilotBasedDSP==1
                %             P = SetCPELength(P);
                assert(mod(P.FrameLen-P.PilotSeqLen,P.PilotRat)==0, 'Wrong Pilot Parameters!!')
                [RxSig, P, fig] = PilotRxDSP(CoSig, P, PauseSec);
            end
            %% Calculate the MI and the GMI
            [SNR, MI, GMI, NGMI, BER, GMI_t] = MI_GMI_SDFEC_Pilot(RxSig, P);
            %         fig = [fig figure('Name','GMI vs Time')];
            %         plot(movmean(GMI_t.',2^4-1));
            %         legend('X-Pol.','Y-Pol.'),xlabel('Data Index'),ylabel('GMI (bits/symbol)')
            
        end
        
        
        %% Show Results
        disp(['OSNR = ' num2str(OSNR) ' dB']);
        disp('-------------------------------------------------');
        OSNRn(1,i) = OSNR;
        SNRn(:,i) = SNR;
        MIn(:,i) = MI;
        GMIn(:,i) = GMI;
        AIRn(:,i) = GMIn(:,i)./(1+P.OH);
        NGMIn(i) = NGMI;
        NAIRn(1,i) = NGMI/(1+P.OH);
        BERn(:,i) = BER;
        PilotSeqLen(1,i) = P.PilotSeqLen;
        PilotRat(1,i) = P.PilotRat;
        FrameLen(1,i) = P.FrameLen;
        OH(1,i) = P.OH;
        disp(['AIR = ' num2str(sum(AIRn(:,i))) ' bit/4D-symbol']);
        disp('-------------------------------------------------');
        
        T = table(Iteration, OSNRn(1,i), SNRn(1,i), SNRn(2,i), MIn(1,i), MIn(2,i), GMIn(1,i), GMIn(2,i), AIRn(1,i), AIRn(2,i), NGMIn(1,i), NAIRn(1,i), BERn(1,i), BERn(2,i), PilotSeqLen(1,i), PilotRat(1,i), FrameLen(1,i), OH(1,i));
        T.Properties.VariableNames = {'Iteration','OSNR','SNRx','SNRy','MIx','MIy','GMIx','GMIy','AIRx','AIRy','NGMI','NAIR','BERx','BERy','PilotSeqLen','PilotRat','FrameLen','OH'};
        if i == 1
            scrsz = get(0,'ScreenSize');
            figIte = figure('Name','Iteration','Position',[scrsz(3)/2 scrsz(2) scrsz(3)/2 scrsz(4)]);
        end
        
        if exist(SaveFname,'file')==0
            writetable(T, SaveFname);
        else
            Told = readtable(SaveFname);
            writetable([Told;T], SaveFname);
        end
        
%         xval = (I.Sweep(i));
%         figure(figIte); subplot(411); hold on; grid on; box on;
%         plot(xval, SNRn(1,i), 'b^');
%         plot(xval, SNRn(2,i), 'rv');
%         plot(xval, 10*log10(mean(10.^(0.1*SNRn(:,i)))), 'go');
%         legend('X-Pol.', 'Y-Pol.'), xlabel('Iteration'), ylabel('SNR (dB)');
%         drawnow;
%         
%         figure(figIte); subplot(412); hold on; grid on; box on;
%         plot(xval, GMIn(1,i),'b^');
%         plot(xval, GMIn(2,i),'rv');
%         plot(xval, mean(GMIn(:,i)), 'go');
%         legend('X-Pol.','Y-Pol.'), xlabel('Iteration'), ylabel('GMI (bits/symbol)');
%         drawnow;
%         
%         figure(figIte); subplot(413); hold on; grid on; box on;
%         plot(xval, AIRn(1,i), 'b^');
%         plot(xval, AIRn(2,i), 'rv');
%         plot(xval, mean(AIRn(:,i)), 'go');
%         legend('X-Pol.','Y-Pol.'), xlabel('Iteration'), ylabel('AIR (bits/symbol)');
%         
%         figure(figIte); subplot(414); hold on; grid on; box on;
%         semilogy(xval, BERn(1,i),'b^');
%         semilogy(xval, BERn(2,i),'rv');
%         semilogy(xval, mean(BERn(:,i)), 'go');
%         legend('X-Pol.','Y-Pol.'), xlabel('Iteration'), ylabel('Pre-FEC BER');
%         drawnow;
        
        %% Save Waveform
        if (P.SaveData==1) && (P.ReadfromFile==0)
            if ~exist('OSNR','var'), OSNR = 0; end
            %             if (isfield(P, 'BackToBack') && (P.BackToBack==1) || isfield(P, 'SSMF') && (P.SSMF ==1))
                 filename = ['NewDAC_',num2str((P.baudRateGS/1e9),'%02d') 'GBd_' P.ModFormatData,'_SNR',num2str(10*log10(mean(mean(10.^(0.1*SNRn))))),'dB_BER_',num2str( mean([BER(1) BER(2)]))];
            if P.PilotBasedDSP==1, filename = ['Pilot_',filename]; end
            if P.LoadWaveforms==3, filename = ['Sim_',filename]; end
            
            if isfield(P,'Linewidth'), filename = [filename 'LW' num2str(P.Linewidth*1e-3,'%04d')]; end
            filename = [filename '.mat'];
            %            end
            P.FName = filename;
            EP = P;
            save(fullfile(P.Path,P.FName), 'CoSig','EP', '-v6');
            disp(['Data saved as ' P.FName]);
        end
    end
end





% if ~I.SkipRxDSP
%     %% Save
%     disp(['MeanMax SNR = ' num2str(10*log10(max(mean(10.^(0.1*SNRn))))) ' dB']);
%     disp(['MeanMean SNR = ' num2str(10*log10(mean(mean(10.^(0.1*SNRn))))) ' dB']);
%     disp(['MeanMax GMI = ' num2str(max(mean(GMIn))) ' bits/symbol']);
%     disp(['MeanMean GMI = ' num2str(mean(mean(GMIn))) ' bits/symbol']);
%     disp(['MeanMax AIR = ' num2str(max(mean(AIRn))) ' bits/symbol']);
%     disp(['MeanMean AIR = ' num2str(mean(mean(AIRn))) ' bits/symbol']);
%     disp('-------------------------------------------------');
%     
%     %     OutCome = [I.Iteration; OSNRn; SNRn; MIn; GMIn; AIRn; NGMIn; BERn; PilotSeqLen; PilotRat];
%     
%     saveas(figIte, [SaveFname(1,1:end-4) '.png'])
%     
%     %     csvwrite(SaveFname, OutCome.');
% end
% for i =1:length(listing)
%     osnr(i) = str2num(listing(i).name(1,end-12:end-9))/100;
%     voa(i) = str2num(listing(i).name(1,end-5:end-4));
% end

% SNRm = 10*log10(mean(10.^(0.1*SNRn)));
% pltSNRvsOSNR(P.Fb, OSNRn, SNRm);
% GMIm = sum(GMIn);
% pltGMIvsOSNR(P.Fb, OSNRn, GMIm);
% pltGMIvsSNR(P.Fb, OSNRn, GMIm);
