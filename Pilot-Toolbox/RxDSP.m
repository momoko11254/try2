function [RxData, P] = RxDSP(CoSig, P)
% Source: Lidia's Lab code
% Modified: Yuta Wakayama (February 2019)

scrsz = get(0,'ScreenSize'); fontsize = 10;
position = [800 scrsz(4)/2 scrsz(3)/2.5 scrsz(4)];

%% Rx Signal
temp = CoSig;

%% Normalise
CompensatedSig = Orthonormalise(temp);
temp = CompensatedSig;

%% GSOP
temp = GSOP(temp);

%% Resampling
P.sample_ratio = temp.Ns/2;
ReSampSig = Resampler(temp, P);
temp = ReSampSig;

%% Deskew
if P.LoadWaveforms~=3
    [Comp, ~] = DelayCompensate(temp, P);
    temp = Comp;
end

%% Root Raised Cosine Filtering (RRC)
if (isfield(P, 'RRCFilter') && (P.RRCFilter == 1))
    [FOut, ~] = FO_Removal(temp, P);
    FP.HetMethod = 'Measured';
    FP.FreqOffset=FOut;
    temp = Heterodyne(temp,FP);
    RRCFiltered = RRCFilter(temp, P);
    temp = RRCFiltered;
end

%% Normalise
CompensatedSig = Orthonormalise(temp);
temp = CompensatedSig;

%% Make long preEQ
PreEQ = temp;
NEQ = 2^18;
PreEQ_Long = PreEQ;
PreEQ.Et = PreEQ.Et(:,1:NEQ);

% CMA Equalisation
if ~isfield(P, 'P.M')
    str = P.ModFormat;
    if strcmp(str(end-2:end),'QAM')
        P.P.M = str2double(str(1:end-3));
    else
        switch str
            case 'QPSK'
                P.P.M = 4;
            otherwise
                error([str ' not a recognised modulation format'])
        end
    end
end
mu = [1e-2 0.005 0.004 0.003 0.001 0.0005 0.0003 0.0003 0.0003 0.0003 0.0003 1e-4 1e-5];
EP.CMAmu = mu;
numAve = length(mu);
for q = 1:numAve
    disp(['Simulating EQ ' num2str(q) ' of ' num2str(numAve)]);
    P.mu = mu(q);
    P.ModFormat = 'QPSK';

    if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
        [equalised, P]= QAM_RDE_4x4_fast(PreEQ,P);
    elseif (P.M > 4)
        [equalised, P] = QAM_RDE_fast(PreEQ_Long,P);
    else
        [equalised, P] = QAM_RDE_fast(PreEQ_Long,P);
    end

    if q==1 && P.InvJones~=0                         % Define matix as inverse Jones matrix of polarisation rotation
        if P.InvJones==1
            Hxx = P.Taps(1,:);
            Hxy = P.Taps(2,:);
            Hyx = fliplr(-1*conj((Hxy)));
            Hyy = fliplr(1*conj((Hxx)));
        elseif P.InvJones==2
            Hyx = P.Taps(3,:);
            Hyy = P.Taps(4,:);
            Hxx = fliplr(1*conj((Hyy)));
            Hxy = fliplr(-1*conj((Hyx)));
        elseif P.InvJones==3
            Hyx = P.Taps(3,:);
            Hyy = P.Taps(4,:);
            Hxx = (1*conj((Hyy)));
            Hxy =(-1*conj((Hyx)));
        end
        P.Taps = [Hxx; Hxy; Hyx; Hyy];
    end
end
temp = equalised;

if isfield(P,'RealEQ')&&(~P.RealEQ)
    vs = sum(reshape(sum(abs(P.Taps).^2, 2),2,2));
    logvs = 10*log10(vs(1)/vs(2));
    fprintf(2,'Estimated PDL after CMA: %.2f dB\n', logvs);
end

% QAM4 CMA LMS Equalisation
if P.M==4
    P.ModFormat = 'QPSK';
    temp = equalised;
end

% QAM16 Multiple Ring CMA LMS Equalisation
if P.M==16
    P.ModFormat = '16QAM';
    P.mu = 1e-5;
    EP.RDEmu1 = P.mu;
    disp('Simulating RDE 16QAM');

    if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
        [~, P] = QAM_RDE_4x4_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised16, P] = QAM_RDE_4x4_fast(PreEQ_Long,P);
    else
        [~, P] = QAM_RDE_fast(PreEQ,P);

        P.mu = [1e-5];
        EP.RDEmu2 = P.mu;
        [RDEequalised16, P] = QAM_RDE_fast(PreEQ_Long,P);
    end

    temp = RDEequalised16;
end

% QAM64 Multiple Ring RDE LMS Equalisation
if P.M==64
    P.ModFormat = '64QAM';
    P.mu = [1e-4 1e-4 1e-5];
    EP.RDEmu1 = P.mu;
    disp('Simulating RDE 64QAM');

    if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
        [~, P] = QAM_RDE_4x4_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised64, P] = QAM_RDE_4x4_fast(PreEQ_Long,P);
    else
        [~, P] = QAM_RDE_fast(PreEQ,P);
        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised64, P] = QAM_RDE_fast(PreEQ_Long,P);
    end
    temp = RDEequalised64;
end

% QAM256 Multiple Ring RDE LMS Equalisation
if P.M==256
    P.ModFormat = '256QAM';
    P.mu = [1e-4 1e-4 1e-4];
        P.mu = 1e-5;
    EP.RDEmu1 = P.mu;
    disp('Simulating RDE 256QAM');

    if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
        [~, P] = QAM_RDE_4x4_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised256, P] = QAM_RDE_4x4_fast(PreEQ_Long,P);
    else
        [~, P] = QAM_RDE_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised256, P] = QAM_RDE_fast(PreEQ_Long,P);
    end
    temp = RDEequalised256;
end

% QAM1024 Multiple Ring RDE LMS Equalisation
if P.M==1024
    P.ModFormat = '1024QAM';
    P.mu = [1e-4 1e-4 1e-4];
        P.mu = 1e-5;
    EP.RDEmu1 = P.mu;
    disp('Simulating RDE 1024QAM');

    if (isfield(P, 'RealEQ') && (P.RealEQ == 1))
        [~, P] = QAM_RDE_4x4_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised1024, P] = QAM_RDE_4x4_fast(PreEQ_Long,P);
    else
        [~, P] = QAM_RDE_fast(PreEQ,P);

        P.mu = 1e-5;
        EP.RDEmu2 = P.mu;
        [RDEequalised1024, P] = QAM_RDE_fast(PreEQ_Long,P);
    end
    temp = RDEequalised1024;
end

temp = Orthonormalise(temp);

%% Frequency Offset Removal
P.HetMethod = 'Fourier';
Homodyned = Heterodyne(temp, P);
temp = Homodyned;

%% Remove transitions
temp.Nt = length(temp.Et(1,:));
temp.dT = 1/temp.Fs;
temp.TT = (0:temp.Nt).*temp.dT;
temp.Fs = temp.Fs/2;
temp.Np = 2;
Extracted = ExtractSymbolsFixed(temp);
temp = Extracted;

%% Carrier Phase Recovery
temp = Orthonormalise(temp);

if ismac()
    P.Threads =1;
end

% CarrierRecovered = QAM_DD_CPE_fast_SingleThread(temp,P);
CarrierRecovered = QAM_DD_CPE_fast(temp,P);
temp = CarrierRecovered;
figure('Name','Constellations','InvertHardcopy','off','Color',[1 1 1]);
set(gca,'LooseInset',get(gca,'TightInset'));
subplot(221), plot(CarrierRecovered.Et(1, P.SDiscard:end-P.SDiscard), 'k.','markersize',1)
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('XPOL after CPE'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
subplot(222), plot(CarrierRecovered.Et(2, P.SDiscard:end-P.SDiscard), 'k.','markersize',1)%%%
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('YPOL after CPE'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
set(gca, 'fontsize',fontsize), drawnow


%% Orthogonalisation and Rotation
temp = GSOP(temp);

arg1 = angle(sum(temp.Et(1,:).^4))/4;
arg2 = angle(sum(temp.Et(2,:).^4))/4;
temp.Et(1,:) = temp.Et(1,:).*exp(-1i*(arg1+pi/4));
temp.Et(2,:) = temp.Et(2,:).*exp(-1i*(arg2+pi/4));

%% Normalise (for QAM Demod)
Normalised_Demod = Orthonormalise(temp);

temp = Normalised_Demod;

subplot(223), plot(temp.Et(1, P.SDiscard:end-P.SDiscard), '.','markersize',1)
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('XPOL after GSOP'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')
subplot(224), plot(temp.Et(2, P.SDiscard:end-P.SDiscard), '.','markersize',1)
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('YPOL after GSOP'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)')

RxData = Normalised_Demod;
end
