function [RxData, P, fig] = PilotRxDSP(CoSig, P, PauseSec)
% Author: Yuta Wakayama, February 2019
% Modified: Yuta Wakayama, June 2019

if ~isfield(P,'plot')
    P.plot = 1;
end

scrsz = get(0,'ScreenSize'); fontsize = 10;

%% Tx Frame
TxFrame.Et = P.TxFrame;
P.TrainingSequence = TxFrame.Et(:, 1:P.PilotSeqLen);
P.TrainingCPE = TxFrame.Et(:, P.IdxPilotCPE);
if isfield(P,'ShiftCPEIdxY') && P.ShiftCPEIdxY~=0
    P.TrainingCPE(2,:) = [TxFrame.Et(2,P.PilotSeqLen+P.ShiftCPEIdxY:P.PilotRat:end) TxFrame.Et(2,end)];
    P.IdxPilotCPEY = zeros(1,P.FrameLen,'logical');
    P.IdxPilotCPEY(1,P.PilotSeqLen+P.ShiftCPEIdxY:P.PilotRat:end) = true;
    P.IdxDataY = ~P.IdxPilotCPEY;
    P.IdxDataY(1,1:P.PilotSeqLen) = false;
end

%% Rx Signal
temp = CoSig;

if P.plot
    fig(1) = figure('Name','Signal Spectrum','InvertHardcopy','off','Color',[1 1 1]);
    subplot(311), set(gca,'LooseInset',get(gca,'TightInset'));
    plot(MakeTimeFrequencyArray(temp)/1e9, 10*log10(abs(fft(temp.Et(1,:))).^2));
    xlabel('Frequency (GHz)'), ylabel('Magnitude (dB)'), title('Received Signal'),axis([-80 80 -50 150]);
    grid on
    drawnow
end

%% Normalise
CompensatedSig = Orthonormalise(temp);
temp = CompensatedSig;

%% GSOP
temp = GSOP(temp);

%% Resampling
P.sample_ratio = temp.Ns/2;
ReSampSig = Resampler(temp, P);
temp = ReSampSig;

%% Normalise
CompensatedSig = Orthonormalise(temp);
temp = CompensatedSig;

if P.plot
    figure(fig(1)), subplot(312);
    set(gca,'LooseInset',get(gca,'TightInset'));
    plot(fftshift(MakeTimeFrequencyArray(temp))/1e9, 10*log10(abs(fftshift(fft(temp.Et(1,:)))).^2));
    xlabel('Frequency (GHz)'), ylabel('Magnitude (dB)'), title('After Resampling'), ylim([-50 100]);
    grid on
    drawnow
end

%% Deskew
[Deskewed, ~] = DelayCompensate(temp, P);
temp = Deskewed;

%% Chromatic Dispersion Compensation 
if (isfield(P, 'BackToBack') && (P.BackToBack == 0))
    P.Return = 'dual pol';
    temp.Fc = 3e8/P.RefWavelength; % Central channel freq (Hz)
    disp('Running Dispersion Compensation...')
%     DComp = dispCompOAS(temp ,P);
    DComp = CDC_overlapadd(temp ,P);
    temp = DComp;
end

%% FOE
disp('Equalise Frequency Offset')
% %% FOE for whole symbols
% [Fout, ~] = FO_Removal(temp, P);
% FP.HetMethod = 'Measured';
% FP.FreqOffset = Fout;
% temp = Heterodyne(temp,FP);

%% FOE for Pilot Sequence only
% Sync frame and extract pilot sequence
P.ModFormat = P.ModFormatPilot;
if isfield(P, 'Taps'), P = rmfield(P,'Taps'); end  % Remove Tap coefficients to initiate it
[P, RxPilot.Et, ~] = PilotSyncFrame(temp, P);
RxPilot.Fs = temp.Fs;
RxPilot.Fb = temp.Fb;

% Estimate freq offset with FFT
P.HetMethod = 'MeanFourier';
Fout = getfield(Heterodyne(RxPilot, P), 'FreqOffset');
FP.HetMethod = 'Measured';
FP.FreqOffset = Fout;

% Remove freq offset
temp = Heterodyne(temp, FP);

% RxPilot.Fs = temp.Fs/2;
% RxPilot.Et = RxPilot.Et(:,2:2:end);
% RxPilot = Orthonormalise(RxPilot);
% % TxPilot = RxPilot;
% % TxPilot.Et = P.TrainingSequence;
% % 
% % figure, plot(RxPilot.Et(1,:),'.')
% % hold on, plot(TxPilot.Et(1,:),'.')
% % 
% % xp = RxPilot.Et.*conj(TxPilot.Et);
% % figure, plot(xp(1,:),'.')
% % hold on, plot(xp(2,:),'.')
% % 
% % df = unwrap(angle(xp),[],2);
% % figure, plot(df(1,:))
% % hold on, plot(df(2,:))
% % 
% % fo = polyfit([1;1]*(1:1:length(df)), df, 1);
% 
% % TP = P;
% % TP.VolterraFilter = 0;
% % TxSig = PilotTxDSP(TP);
% % %% Resampling
% % TP.sample_ratio = TxSig.Ns/2;
% % ReSampTxSig = Resampler(TxSig, TP);
% % TxPilot.Et = ReSampTxSig.Et(:, 2:P.PilotSeqLen*2+1);
% % TxPilot.Et(P.SwapIQ,:) = 1i*conj(TxPilot.Et(P.SwapIQ,:));
% 
% 
% % %0.016667
% xp = RxPilot.Et(1,:).*conj(TxPilot.Et(1,:));
% xp = conj(TxPilot.Et).*RxPilot.Et;
% df = unwrap(angle(xp),[],2);
% fo = polyfit([1;1]*(1:1:length(df)), df, 1);
% lin_phase = (1:length(temp.Et))*fo(1);
% temp.Et = temp.Et.*([1;1]*exp(-1j*lin_phase));
% 
% xp = RxPilot.Et.*conj(TxPilot.Et);
% df = unwrap(angle(xp),[],2);
% 
% % xp = conj(Pilot.Et(:,2:2:end)).*(P.TrainingSequence);
% % 
% % df = angle(sum(xp(1,2:end).*conj(xp(1,1:end-1))));
% % df = Pilot.Fs/(2*pi)*angle(sum(xp(2,2:end).*conj(xp(2,1:end-1))));
% % df = Pilot.Fs/(2*pi)*angle((xp(1,2:end)*conj(xp(1,1:end-1)).'));
% % df = Pilot.Fs/(2*pi)*angle((xp(2,2:end)*conj(xp(2,1:end-1)).'));
% % 
% % xx = kron(P.TrainingSequence, [0,1]);
% % yy = Pilot.Et;
% % ss = yy.*conj(xx);
% % fo = Pilot.Fs/(2*pi)*angle( ss(1,2:2:end)*conj(ss(1,1:2:end-1).' ) );
% % 
% % xx = P.TrainingSequence;
% % yy = Pilot.Et(:,2:2:end);
% % ss = yy.*conj(xx);
% % fo = Pilot.Fs/(2*pi)*angle( ss(1,end:-1:2)*conj(ss(1,end-1:-1:1).' ) );
% 
% % dfx = 1/(2*pi)*angle((Pilot.Et(1,2:2:end)))./angle(TxPilot.Et(1,2:2:end));
% % dfy = 1/(2*pi)*angle((Pilot.Et(2,2:2:end)))./angle(TxPilot.Et(2,2:2:end));
% % 
% % dfx = Pilot.Fs/(2*pi)*angle((Pilot.Et(1,2:2:end))./1i./conj(TxPilot.Et(1,2:2:end)));
% % dfy = Pilot.Fs/(2*pi)*angle((Pilot.Et(2,2:2:end))./1i./conj(TxPilot.Et(2,2:2:end)));
% % df = mean([dfx; dfy],2);
% % df = mean([dfx, dfy]);
% % % xp = Pilot.Et.*conj(TxPilot.Et);
% % % % df = Pilot.Fs/(2*pi)*angle(sum(sum(xp(:,2:end).*conj(xp(:,1:end-1)))));
% % % % df = Pilot.Fs/(2*pi)*angle(sum(xp(1,2:end).*conj(xp(1,1:end-1))));
% % % df = Pilot.Fs/(2*pi)*angle(sum(xp(2,2:end).*conj(xp(2,1:end-1))));
% % % %-0.084229 GHz
% % FP.FreqOffset = df;
% % FP.HetMethod = 'Measured';
% % temp = Heterodyne(temp, FP);

% % [Fout, ~] = FO_Removal(temp, P);
% % FP.HetMethod = 'Measured';
% % FP.FreqOffset = Fout;
% % temp = Heterodyne(temp,FP);

%% RRC
if (isfield(P, 'RRCFilter') && (P.RRCFilter == 1))
    disp('Apply RRC Filter')
    RRCFiltered = RRCFilter(temp, P);
    temp = RRCFiltered;
end

%% Normalise
CompensatedSig = Orthonormalise(temp);
temp = CompensatedSig;

if P.plot
    figure(fig(1)); subplot(313);
    set(gca,'LooseInset',get(gca,'TightInset'));
    plot(fftshift(MakeTimeFrequencyArray(temp))/1e9, 10*log10(abs(fftshift(fft(temp.Et(1,:)))).^2));
    xlabel('Frequency (GHz)'), ylabel('Magnitude (dB)'), title('After FOE and RRC'), ylim([-50 100]);
    grid on
    drawnow
end

%% Sync
P.ModFormat = P.ModFormatPilot;
if isfield(P, 'Taps'), P = rmfield(P,'Taps'); end  % Remove Tap coefficients to initiate it
P = PilotSyncFrame(temp, P);

P.SyncIdx(1) = P.PilotDelay;
P.SyncIdx(2) = P.PilotDelay;

disp('Equalisation for Pilot Sequence')              
[RxPilot, SigEq, P] = PilotExtraction(temp,P);

% Monitor
if PauseSec ~= -2
MonitoredPilot = RxPilot.Et(:,P.TapCor+1:2:end-3);
MonitoredPayload = SigEq.Et(:,2:2:end);
if P.plot
    [PilotXI, PilotXQ, PilotYI, PilotYQ,...
        PayloadXI, PayloadXQ, PayloadYI, PayloadYQ, fig(2)] = ...
        MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 1);
    if PauseSec < 0, keyboard, else, refreshdata(fig(2),'caller'),drawnow, pause(PauseSec), end
end
end

%% RLS & DAE Equalisation for Pilot Sequence
% Remove Tap coefficients to initiate it
if isfield(P, 'Taps'), P = rmfield(P,'Taps'); end

P.Normalised = true; % use input normalisation for lms
mu = P.FilterLength*2*[100e-4 100e-4 50e-4 40e-4 30e-4 20e-4 10e-4 10e-4 5e-4 1e-4 1e-4 1e-4 1e-5 1e-5];
mu = [ones(1,6),mu];

Training.Et = [zeros(2,P.FilterLength-1) kron(P.TrainingSequence,[0,1])];
[~,P] = QAM_RLS(RxPilot,Training,P);

for q = 1:length(mu)
    % Equalise Pilot Sequence
    disp(['EQ ' num2str(q) ' of ' num2str(length(mu)) ', mu = ' num2str(mu(q))]);
    P.mu = mu(q);

    [PilotEq,P] = QAM_DAE_fast(RxPilot,Training,P);

    % Monitor
    if PauseSec ~= -2
    MonitoredPilot = PilotEq.Et(:,P.TapCor+1:2:end-3);
    MonitoredPayload = SigEq.Et(:,2:2:end);
    if P.plot
        [PilotXI, PilotXQ, PilotYI, PilotYQ,...
            PayloadXI, PayloadXQ, PayloadYI, PayloadYQ] = ...
            MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 0);
        if PauseSec < 0, keyboard, else, refreshdata(fig(2),'caller'),drawnow, pause(PauseSec), end
    end
    end
end

%% Apply calculated tap coefficients for the whole rx data
disp('Apply calculated tap coefficients for the whole rx data');

P.ExIdxRDEupdate = zeros(1,size(temp.Et,2));
P.ModFormat = P.ModFormatPilot;
if P.ShiftCPEIdxY~=0
    P.mu = 0;
    P.ExIdxRDEupdate(P.ExIdxCPEblocksX) = 0;
    P.ExIdxRDEupdate(P.ExIdxCPEblocksY) = 0;
%     P.ModFormat = P.ModFormatData;
else
    P.mu = [0.5,0.25]*5e-2;
    P.ExIdxRDEupdate(P.ExIdxCPEblocksX) = 1;
    P.ExIdxRDEupdate(P.ExIdxCPEblocksY) = 1;
%     P.ModFormat = P.ModFormatPilot;
end
[equalised, P] = QAM_RDE_fast(temp, P);

temp = equalised;
TapsPilotSeq = P.Taps;

[PilotEq,SigEq,P] = PilotExtraction(temp,P);

% Monitor
if PauseSec ~= -2
MonitoredPilot = PilotEq.Et(:,P.TapCor+1:2:end);
MonitoredPayload = SigEq.Et(:,2:2:end);
if P.plot
    [PilotXI, PilotXQ, PilotYI, PilotYQ,...
        PayloadXI, PayloadXQ, PayloadYI, PayloadYQ] = ...
        MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 0);
    drawnow
    if PauseSec < 0, keyboard; else, refreshdata(fig(2),'caller'),pause(PauseSec); end
end
end

%% Frequency Offset Removal
disp('Frequency Offset Removal')
%% FOE for whole symbols
% P.HetMethod = 'MeanFourier';
% Homodyned = Heterodyne(temp, P);
% temp = Homodyned;

%% FOE for Pilot Sequence only
P.HetMethod = 'MeanFourier';
RxPilot = PilotEq;
RxPilot.Et = PilotEq.Et(:,P.TapCor:end);
Fout = getfield(Heterodyne(RxPilot, P), 'FreqOffset');
FP.HetMethod = 'Measured';
FP.FreqOffset = Fout;
temp = Heterodyne(temp, FP);

%% Orthogonalisation
disp('Orthogonalisation')
temp = Orthonormalise(temp);

%% Remove transitions
disp('Remove Transisions')                
temp.Nt = length(temp.Et(1,:));
temp.dT = 1/temp.Fs;
temp.TT = (0:temp.Nt).*temp.dT;
temp.Fs = temp.Fs/2;
temp.Np = 2;
Extracted = ExtractSymbolsFixed(temp);
temp = Extracted;

%% Extract a data frame
disp('Extract a data frame')
temp.Et = temp.Et(:, P.PilotDelay+1:P.PilotDelay+P.FrameLen);
temp.Nt = length(temp.Et(1,:));
temp.dT = 1/temp.Fs;
temp.TT = (0:temp.Nt).*temp.dT;
temp.Fs = temp.Fs/2;
temp.Np = 2;
% Monitor
PilotEq.Et = temp.Et(:,P.IdxPilotCPE);
SigEq.Et = temp.Et(:,P.IdxData);
if isfield(P,'ShiftCPEIdxY') && P.ShiftCPEIdxY~=0
    PilotEq.Et(2,:) = [temp.Et(2,P.IdxPilotCPEY) 0];
    SigEq.Et(2,:) = temp.Et(2,P.IdxDataY);
end
if PauseSec ~= -2
MonitoredPilot = PilotEq.Et;
MonitoredPayload = SigEq.Et;
if P.plot
    [PilotXI, PilotXQ, PilotYI, PilotYQ,...
        PayloadXI, PayloadXQ, PayloadYI, PayloadYQ] = ...
        MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 0);
    drawnow
    if PauseSec < 0, keyboard; else, refreshdata(fig(2),'caller'),pause(PauseSec); end
end
end

%% Orthonormalisation
temp = Orthonormalise(temp);
temp = GSOP(temp);
% for plotting
PilotSeqEq.Et = temp.Et(:, 1:P.PilotSeqLen);

%% Pilot-Based CPE
disp('Pilot-Based CPE');
RxFrame = temp;
[CarrierPhaseRecoveredSig, Phase, P] = PilotCPE(RxFrame, P);
temp = CarrierPhaseRecoveredSig;
temp = PilotRPE(temp,P);

% Monitor
PilotEq.Et = temp.Et(:,P.IdxPilotCPE);
SigEq.Et = temp.Et(:,P.IdxData);
if isfield(P,'ShiftCPEIdxY') && P.ShiftCPEIdxY~=0
    PilotEq.Et(2,:) = [temp.Et(2,P.PilotSeqLen+P.ShiftCPEIdxY:P.PilotRat:end) 0];
    SigEq.Et(2,:) = temp.Et(2,P.IdxDataY);
end
if PauseSec ~= -2
MonitoredPilot = PilotEq.Et;
MonitoredPayload = SigEq.Et;
if P.plot
    [PilotXI, PilotXQ, PilotYI, PilotYQ,...
        PayloadXI, PayloadXQ, PayloadYI, PayloadYQ] = ...
        MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 0);
    drawnow
    if PauseSec < 0, keyboard, else, refreshdata(fig(2),'caller'), drawnow, pause(PauseSec), end
end
end
%% Orthogonalisation and Rotation
% temp.Et = SigEq.Et;
temp.Et = temp.Et;
temp.Nt = length(temp.Et(1,:));
temp.dT = 1/temp.Fs;
temp.TT = (0:temp.Nt-1).*temp.dT;
temp.Fs = temp.Fs/2;
temp.Np = 2;
temp = GSOP(temp);

arg1 = angle(sum(temp.Et(1,:).^4))/4;
arg2 = angle(sum(temp.Et(2,:).^4))/4;
temp.Et(1,:) = temp.Et(1,:).*exp(-1i*(arg1+pi/4));
temp.Et(2,:) = temp.Et(2,:).*exp(-1i*(arg2+pi/4));

%% Normalise (for QAM Demod)
NormalisedDemod = Orthonormalise(temp);

if P.plot
    % Monitor
    if PauseSec ~= -2
    MonitoredPayload = NormalisedDemod.Et(:,P.IdxData);
    [PilotXI, PilotXQ, PilotYI, PilotYQ,...
        PayloadXI, PayloadXQ, PayloadYI, PayloadYQ] = ...
        MonitorPilotDSP(MonitoredPilot, MonitoredPayload, 0);
    drawnow
    if PauseSec < 0, keyboard, else, refreshdata(fig(2),'caller'),drawnow, pause(PauseSec), end
    end
end

%% Output
RxData = NormalisedDemod;

%% Plot
if P.plot
    fig(3) = figure('Name','FIR Tap Coefficients'); hold on;
    for i = 1:4, plot(abs(TapsPilotSeq(i,:)).^2); end
    title('Impulse Response');
    xlabel('Tap Number'), ylabel('|Tap Coefficient|^2');
    grid;

    fig(4) = figure('Name','Data Sequence');
    title('Pilot Locations')
    pilotdelay= [P.PilotDelay P.PilotDelay+P.FrameLen];
    plot(abs(Extracted.Et(1,:)),'.'); hold all;
    plot(pilotdelay,abs(Extracted.Et(1,pilotdelay)),'ro'); grid;

    fig(5) = figure('Name','Carrier Phase');
    plot(Phase(1,:), '-'); hold on; plot(Phase(2,:), '-'); grid;

    fig(6) = figure('Name','Constellations','InvertHardcopy','off','Color',[1 1 1],'Position',[scrsz(3)/2 scrsz(4)/2-80 scrsz(3)/2.5 scrsz(4)/2]);
    set(gca, 'LooseInset', get(gca,'TightInset'));
    subplot(321), plot(PilotSeqEq.Et(1,:), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('XPOL Pilot Sequence'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    subplot(322), plot(PilotSeqEq.Et(2,:),'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('YPOL Pilot Sequence'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    subplot(323), plot(PilotEq.Et(1,:), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('XPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    subplot(324), plot(PilotEq.Et(2,:),'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('YPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    subplot(325), plot(SigEq.Et(1,:), 'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('XPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    subplot(326), plot(SigEq.Et(2,:),'k.','markersize',1)
    axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
    title('YPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
    set(gca, 'fontsize', fontsize), drawnow
else
    fig = [];
end
end
