function [TxSig, P, varargout] = PilotTxDSP(P)
% Transmitter-side DSP
% Generate a data frame and apply a DSP chain for loading data to DAC
%
% Input:
%   P: Struct of Parameters
%       class   | struct
% Output:
%   TxFrame: Data Frame
%       class   | double
%       size    | (2, :)
%   TxSig: Data for DAC
%       class   | complex<double>
%       size    | (2, :)
%   P: Struct of Parameters
%       P.TxData    | Transmitted symbols of payload
% Output (optional):
%   varargout{1}: Figure Object
%
% Author: Y. Wakayama June 2019

temp.Et = P.TxFrame;

if ~isfield(P,'plot')
    P.plot = 1;
end

%% Digital Pre-Distortion Based on Volterra Filtering
if isfield(P,'VolterraFilter') && P.VolterraFilter == 1
    if isfield(P,'VolterraTaps')
        VoltEqX.Taps = P.VolterraTaps;
        RealSig = Complex2Real(temp.Et);
        
        % impuslse length of 1st to 5th order volterra kernals
        if ~isfield(P,'L')
            P.L = ([256, 8, 3, 0, 0]*1)*2 + 1;
        end
        DPD.L = P.L;

        for m = 1:size(RealSig,1)
            DPD.w = VoltEqX.Taps(m,:);
            disp(['The tributary is: ' num2str(m)]);
            mu = zeros(sum(DPD.L.^(1:length(DPD.L))),1);
            for n = 1:size(mu,2)
                disp(['The mu is: ' num2str(mean(mu(:,n)))]);
                DPD.mu = mu(:,n);
                DPD.Et = RealSig(m,:).';
                [RealSig(m,:),EQ] = modulatorDPD(RealSig(m,:).',DPD);
                DPD.w = EQ.w;
            end
        end
        PreDistorted = temp;
        PreDistorted.Et = Real2Complex(RealSig);
        temp = PreDistorted;
    end
end

%% Upsample and Apply an RRC Filter
[Down,Up] = rat(1/P.Ns,1e-7);
if isfield(P, 'RRCFilter') && (P.RRCFilter == 1)
    disp('Zero-Padding')
    ZeroPadded = KronUpsampler(temp, [1 zeros(1, Up-1)]);
    temp.Et = ZeroPadded.Et;
    
    disp('Using precomputed filter tap weights')
    RRCF.Numerator = rcosdesign(P.RollOff,510,Up,'sqrt')/1.732; % the 1.732 matches the normalisation in fdesign.pulseshaping
    RRCF.order = length(RRCF.Numerator)-1;
    
    disp('Applying RRC filter')
    RealSig = Complex2Real(temp.Et);
    for i = 1:size(RealSig, 1)
        RealSig(i,:) = cconv(RRCF.Numerator, RealSig(i,:), size(RealSig,2));
    end
    temp.Et = Real2Complex(RealSig);
else
    disp('Upsampling')
    UpSampled = KronUpsampler(temp, [1 ones(1, Up-1)]);
    temp = UpSampled;
end
TxSig = temp;
TxSig.Fs = P.Fb*Up;

%% Downsample
TxSig.Et = TxSig.Et(:, 1:Down:end);
TxSig.Fs = TxSig.Fs/Down;
TxSig.Ns = TxSig.Fs/P.Fb;
TxSig.Fb = P.Fb;
TxSig.Nt = size(TxSig.Et, 2);
temp = TxSig;

%%
% %% NLC (Predistortion)
% P.NLC = 0;
% % Sig.Et(1,:) = complex(0,0);
% SigLin = Sig;
% % Sig.Et(2,:) = Sig.Et(1,:);
% if isfield(P, 'NLC') && (P.NLC == 1)
%     %     Lengths = [50.24 50.296 50.36]; % [km]
%     %     Disps = -1*[16.3 15.0 15.0977]*1e-6; % [s/m/m]  -[16.3 15.5 15.0977]*1e-6
%     %     Attenuations=[0.160 0.161 0.1688]; % [dB/km]
%     
%     Lengths = [30]; % [km]
%     Disps = -0*[16.3]*1e-6; % [s/m/m]  -[16.3 15.5 15.0977]*1e-6
%     Attenuations=[0.2]; % [dB/km]
%     
%     LaunchPower = 12;
%     LaunchPowers = [LaunchPower LaunchPower-cumsum(Attenuations(1:end-1).*Lengths(1:end-1))]; % [dBm]
%     LaunchPowers = 10.^((LaunchPowers-30)/10); % Convert to power in [W]
%     %     P.sample_ratio = 0.5;
%     %     Sig.Ns = 1;
%     %     Sig = Resampler(Sig,P);
%     
%     for index = 1:1
%         fprintf('applying DBP at the transmitter (span %d)\n',index)
%         P.Length = Lengths(index)*1e3; % distance in [m]
%         P.D =Disps(index); % s/m/m
%         P.Att = Attenuations(index); % [dB/km]
%         P.Att = (P.Att/4.343)/1e3;
%         
%         P.GammaBP = -0.8/1e3; % [/W/m]
%         P.RefWavelength = 1550e-9; % [m]
%         P.NSpans = 1;
%         P.NSteps_NLC = 64;
%         P.GPU = 0;
%         
%         %         P.LaunchPower = 13.0-1; % [ dBm ]
%         P.LaunchPower = LaunchPowers(index); % [ dBm ]
%         P.WH_Split=0.5;
%         tic
%         temp = DBP(Sig,P);
%         toc
%         plot(MakeTimeFrequencyArray(temp),10*log10(abs(fft(temp.Et(2,:)))))
%         TI = real(temp.Et(2,:));
%         % TR = imag(temp.Et(2,:));
%         % temp.Et(2,:) = TR+1i*TI;
%         Sig=temp;
%         
%     end
%     
%     % P.sample_ratio = 2;
%     % Sig = Resampler(Sig,P);
%     % PBrick.BW = 50e9;
%     % temp = BrickwallOpticalFilter(temp,PBrick);
%     
%     %%
%     close all
%     plot(MakeTimeFrequencyArray(Sig)/1e9,10*log10(abs(fft(Sig.Et(1,:))))); hold all ; plot(MakeTimeFrequencyArray(Sig)/1e9,10*log10(abs(fft(SigLin.Et(1,:)))));
%     xlabel('Freq [GHz]')
%     ylabel('Rel. pwr [dB]')
%     %%
%     Sig = temp;
%     
%     % Sig.Et(2,:) = conj(Sig.Et(2,:));
%     % Sig.Et(1,:) = -(Sig.Et(1,:));
% end
% 
% 
% %% Check that number of samples is multiple of 128
% Fb = (Fs/P.Ns);                                     % Symbol rate (Baud)
% disp(['Number of blocks of 128 samples: ' num2str((2^16*(Fs/Fb))/128)])
% % figure('Name','RRC Filtered Opitcal Spectrum');
% % OSA(Sig), title('RRC Filtered Opitcal Spectrum', 'fontsize', Fsize), set(gca, 'fontsize', Fsize), axis([-50 50 -150 -20])
% 
% %% SweptSine
% if P.SweptSine
%     P.Nt=2^19;
%     P.Fs = 92e9;
%     P.dT=1/P.Fs;
%     P.f1 = 30e3; % Minimum swept sine frequnecy
%     P.f2 = 46e9; % Maximum swept sine frequnecy
%     P.T = P.Nt*P.dT;
%     P.Twin=0.01*P.T;
%     P.Amplitude=1;
%     
%     [Signal,Window] = ExpSweptSine(P);
%     
%     Sig = Signal;
%     Sig.Et(2,:) = Sig.Et(1,:);
%     Sig.Et(1,:) = real(Sig.Et(1,:))+1i*real(Sig.Et(1,:)); % map sine wave to all quadratures
%     Sig.Et(2,:) = real(Sig.Et(2,:))+1i*real(Sig.Et(2,:));
%     Sig.Fs=P.Fs;
%     Sig.Fb = 30e9; % hack
%     
%     IFilx = real(Sig.Et(1,:));
%     QFilx = imag(Sig.Et(1,:));
%     IFily = real(Sig.Et(2,:));
%     QFily = imag(Sig.Et(2,:));
% end
% 
% %% Signal Pre-emphasis
% if isfield(P, 'PreEmp') && (P.PreEmp == 1)
%     close all
%     temp = Sig;
%     NumMods = 2;
%     Path = PathPreEmphasis;
%     
%     N_taps= 2^15;
%     IFil = zeros(NumMods, length(Sig.Et(1,:)));
%     QFil = zeros(NumMods, length(Sig.Et(1,:)));
%     
%     for nn = 1:NumMods  % for each MZM
%         PreEmpFil = zeros(2, N_taps+1);
%         for n = 1:2 % For loop for I and Q
%             TF = getfield(load([Path 'DPIQ-' num2str(7-2*nn-n) 'port_Filter.mat']),'TF');
%             fprintf('Preemp DAC #%d\n',2*nn+n-2)
%             disp('System TF characterised using EXP swept sine wave loaded')
%             
%             TF.H = TF.H./max(abs(TF.H));
%             HF = TF.H;
%             ff = TF.F;
%             %            HF(1, abs(ff)>P.PreEmp_Fmax)= 1; % DL: Frequencies not to be compensated
%             
%             FiltH = HF(1:end/2+1);                              % transfer function of the system
%             %            FiltF = [ff(1:end/2), abs(ff(end/2+1))];            % frequency array
%             FiltF = ff(1:end/2+1);            % frequency array
%             %            P.PreEmp_Fmax = 29e9;
%             FiltF(end)=FiltF(end-1)+FiltF(2);
%             
%             FiltH(1, abs(FiltF)>P.PreEmp_Fmax)= 0; % DL: Frequencies not to be compensated
%             FiltH = FiltH./max(abs(FiltH));
%             FiltH(1, abs(FiltF)>P.PreEmp_Fmax)= 10*FiltH(1); % DL: Frequencies not to be compensated
%             
%             assert(FiltF(end)>=Sig.Fs/2,'Maximum frequency of the transfer function should be larger than half the sample rate')
%             [~,SampleRateInd] = find(FiltF<=Sig.Fs/2,1,'last');
%             
%             endloc = find(abs(FiltF)>P.PreEmp_Fmax,1);
%             
%             FiltF = FiltF(1:SampleRateInd)/FiltF(SampleRateInd);
%             FiltH = 1./abs(FiltH(1:SampleRateInd));
%             FiltH(endloc:end) = 0;
%             
%             %            FiddleFactors = [0.82 0.82 0.82 0.82];
%             FiddleFactors = 0.9*[1 1 1 1];
%             %            FiddleFactors = 1.2*[1 1 1 1];
%             FiddleFactor = FiddleFactors(2*nn+n-2);
%             FiltH(length(FiltH)/2:end)=FiltH(length(FiltH)/2:end).^FiddleFactor;
%             
%             PreEmpFil(n,:) = (fir2(N_taps,FiltF,FiltH));
%             hold all;
%             PredT = 1/Sig.Fs;
%             PredF = 1/PredT/N_taps;
%             PreFF = [0:floor(N_taps/2)-1,floor(-N_taps/2):-1] * PredF;
%             plot([PreFF 0],10*log10((abs(fft(PreEmpFil(n,:))))))
%             drawnow;
%         end
%         
%         IFil(nn,:) = cconv(PreEmpFil(1,:),real(temp.Et(nn,:)),length(Sig.Et(1,:)));
%         IFil(nn,:) = circshift(IFil(nn,:),[0 -ceil(N_taps/2)]);
%         QFil(nn,:) = cconv(PreEmpFil(2,:), imag(temp.Et(nn,:)),length(Sig.Et(1,:)));
%         QFil(nn,:) = circshift(QFil(nn,:),[0 -ceil(N_taps/2)]);
%         
%     end
%     IFilx = IFil(1,:);
%     QFilx = QFil(1,:);
%     IFily = IFil(2,:);
%     QFily = QFil(2,:);
% end

% figure('Name','After Histogram of In-Phase Component');
% hist(IFilx, 2^6), title('After Histogram of In-Phase Component', 'fontsize', Fsize), %axis([0 63 0 2500])
% xlabel('Bin Number', 'fontsize', Fsize), ylabel('Bin Count', 'fontsize', Fsize), set(gca, 'fontsize', Fsize)

%% Normalise Signals for full DAC range
Normalised = Normalise(temp.Et);

%% Deskew
scale = 1e-12;
skewX1 = 0*scale;                          % XI
skewX2 = P.TxDelayXIQ*scale;               % XQ - delay between XI and XQ
skewY1 = P.TxDelayXY*scale;                % YI - delay between XY
skewY2 = (P.TxDelayXY+P.TxDelayYIQ)*scale; % YQ - delay between YI and YQ
SkewValues = [skewX1, skewX2, skewY1, skewY2];
Deskewed = iqxydelay(Normalised, P.Fs, SkewValues);

%% Output
TxSig.Et = Real2Complex(Deskewed);

%% Plot
if P.plot
    fig = figure('Name','Generated Tx Signal','InvertHardcopy','off','Color',[1 1 1]);

    subplot(221), plot(P.TxFrame(1, :), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('Tx Frame XPOL'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')

    subplot(222), plot(P.TxFrame(2, :), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('Tx Frame YPOL'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')

    subplot(223), plot(TxSig.Et(1, Up:Up:end), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('Tx Signal XPOL'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')

    subplot(224), plot(TxSig.Et(1, Up:Up:end), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('Tx Signal YPOL'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')

    drawnow
else
    fig = [];
end

if nargout>2
    varargout{1} = fig;
end


end
