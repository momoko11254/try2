function [SNR, MI, GMI, NGMI, BER, GMI_t, varargout] = PilotMI_GMI_SDFEC(RxData, P, Rate)

% This function computes the MI,  GMI, PreFECBER and PostFECBER
%
% Parameters
% BitSym    	: Transmitted bit and symbols, and received symbols
% P.ModFormat	: Modulation format
% Rate:         : Code rate
%
% Alex Alvarado
% December 2014
% Edited by Robert Maher January 2016
% Added pilot handling: Yuta Wakayama (February 2019)

if ~isfield(P,'plot')
    P.plot = 1;
end

%% Align transmitted and received symbols
RxSym.X = RxData.Et(1,:);
RxSym.Y = RxData.Et(2,:);
[BitSym, P] = PilotTXRX_SymAlign(RxSym, P);
P.CWlen = sum(P.IdxData);  % Code word length
% Integer number of code words
P.Len = floor((length(BitSym.Symbols(1,:))*log2(P.M))/P.CWlen);


%% Modulation parameters
M = ReturnModOrder(P.ModFormatData); % Number of constellation points

m = log2(M);                                                                        % bits/symbol
nn = (P.CWlen*P.Len)/log2(M);                                                     % Block length

%% Load transmitted bits, and symbols ('BitSym')
B_labX = BitSym.Bits(1:m, 1:nn, 1);                                                       % Transmitted bits
B_labY = BitSym.Bits(1:m, 1:nn, 2);                                                       % Transmitted bits
XX = BitSym.Symbols(1, :).';                                                         % Complex Transmitted symbols
XY = BitSym.Symbols(2, :).';
YX = BitSym.Symbols(3, :).';                                                        % Complex Received symbols (XPOL)
YY = BitSym.Symbols(4, :).';                                                        % Complex Received symbols (XPOL)
% keyboard
[~,bb] = unique(B_labX.','rows');
C = XX(bb,:);                                                                        % Complex Constellation (synchronoulsy permuted)
% keyboard
L  = 0:M-1;                                                                         % Labeling (NBC)
Lbin = dec2bin(L)-48;                                                               % Labeling in binary

%% Find Subconstellations defined by the labeling (needed to compute LLRs)
Ik0 = zeros(M/2,m);
Ik1 = zeros(M/2,m);
for kk = 1:m
    pntr0 = 1;
    pntr1 = 1;
    for i = 1:M
        if Lbin(i, kk) == 0
            Ik0(pntr0,kk) = i;
            pntr0 = pntr0+1;
        else
            Ik1(pntr1,kk) = i;
            pntr1 = pntr1+1;
        end
    end
end

%% SNR Calculation
V = zeros(M, 2);
CentoidC = zeros(M, 2);
Xx=XX;
Xy=XY;

for i=1:M
    pntX = find(XX==C(i));
    pntY = find(XY==C(i));
    
    CentoidC(i,1) = mean(YX(pntX));
    CentoidC(i,2) = mean(YY(pntY));
    Xx(pntX) = (Xx(pntX)-mean(Xx(pntX)))+CentoidC(i,1);
    Xy(pntY) = (Xy(pntY)-mean(Xy(pntY)))+CentoidC(i,2);
    V(i,1) = var(YX(pntX)-Xx(pntX));                                                  % Noise variance
    V(i,2) = var(YY(pntY)-Xy(pntY));                                                  % Noise variance
end

SNRdB = zeros(2, M);

for i=1:M
    SNRdB(1, i) = 10*log10(var(Xx)/V(i,1));                                         % SNR of the i-th symbol XPOL (dB)
    SNRdB(2, i) = 10*log10(var(Xy)/V(i,2));                                         % SNR of the i-th symbol YPOL (dB)
end

SNRlin = mean(10.^(SNRdB./10), 2);                                                  % Mean SNR (dB)

if ~isfield(P,'SinglePolarisation')||P.SinglePolarisation==0
    SNRmeanlin = (mean([SNRlin(1) SNRlin(2)], 2));                                      % Mean SNR over both polarisations (dB)
else
    SNRmeanlin = max([SNRlin(1) SNRlin(2)]);                                      % max SNR over both polarisations (dB)
end

SNR = 10*log10(SNRlin);
SNRmean = 10*log10(SNRmeanlin);

%% MI Calculation
MI(1) = ComputeLowerBoundMI(Xx,YX);                                                   % MI for XPOL (b/sym)
MI(2) = ComputeLowerBoundMI(Xy,YY);                                                   % MI for YPOL (b/sym)
MItot = MI(1)+MI(2);                                                                       % Mean MI (b/sym)

%% GMI Calculation
LLRx = demapperNew(CentoidC(:,1),Xx,YX,Ik1,Ik0,0);                                  % Demapper (compute Exact LLRs) XPOL
LLRy = demapperNew(CentoidC(:,2),Xy,YY,Ik1,Ik0,0);                                  % Demapper (compute Exact LLRs) YPOL

BX = B_labX(:);                                                                       % Transmitted bits, converted to single column
BY = B_labY(:);
LLRx_vector = LLRx(:);                                                              % Computed XPOL LLRs, converted to single column
LLRy_vector = LLRy(:);                                                              % Computed XPOL LLRs, converted to single column

GMI(1) = 0;                                                                           % Initialise GMIx to zero
GMI(2) = 0;                                                                           % Initialise GMIy to zero

for kk=1:m
    GMI(1) = (1-1/(length(LLRx_vector)/m)*sum(log2(1+exp((-1).^(BX(kk:m:end)).*LLRx_vector(kk:m:end)))))+GMI(1);    % GMI for XPOL (b/sym)
    GMI(2) = (1-1/(length(LLRy_vector)/m)*sum(log2(1+exp((-1).^(BY(kk:m:end)).*LLRy_vector(kk:m:end)))))+GMI(2);    % GMI for YPOL (b/sym)
end

GMI_t = zeros(2,length(LLRx_vector)/m);
for kk=1:m
    GMI_t(1,:) = 1-(log2(1+exp((-1).^(BX(kk:m:end)).*LLRx_vector(kk:m:end)))).'+GMI_t(1,:);    % GMI for XPOL (b/sym)
    GMI_t(2,:) = 1-(log2(1+exp((-1).^(BY(kk:m:end)).*LLRy_vector(kk:m:end)))).'+GMI_t(2,:);    % GMI for YPOL (b/sym)
end


GMItot = GMI(1)+GMI(2);                                                            % Mean GMI (b/sym)
NGMI = mean(GMItot)/(2*log2(M));                                               % Normailsed GMI

%% Pre-FEC BER Calculation
% Using HDs based on LLRs
Hx = 1*(LLRx > 0);                                                          % Make a hard decision on the bits based on LLRs
BER(1) = sum(sum(B_labX ~= Hx))/(m*size(Hx, 2));                               % Estimate BER

Hy = 1*(LLRy > 0);                                                          % Make a hard decision on the bits based on LLRs
BER(2) = sum(sum(B_labY ~= Hy))/(m*size(Hy, 2));                               % Estimate BER

if ~isfield(P,'SinglePolarisation')||P.SinglePolarisation==0
    PreFECBER = mean([BER(1) BER(2)]);                                              % Pre-FEC BER
else
    PreFECBER = min([BER(1) BER(2)]);
end
fprintf('-------------------------------------------------\n');
fprintf('Average SNR XPOL = %2.3f dB\n', SNR(1));
fprintf('Average SNR YPOL = %2.3f dB\n', SNR(2));
fprintf('MI-XPOL = %2.2f bit/symbol\n', MI(1));
fprintf('MI-YPOL = %2.2f bit/symbol\n', MI(2));
fprintf('GMI-XPOL = %2.2f bit/symbol\n', GMI(1));
fprintf('GMI-YPOL = %2.2f bit/symbol\n', GMI(2));
fprintf('BER-XPOL = %2.6f \n', BER(1));
fprintf('BER-YPOL = %2.6f \n', BER(2));
fprintf('-------------------------------------------------\n');
fprintf('SNR = %2.3f dB\n', SNRmean);
fprintf('MI = %2.2f bit/symbol\n', MItot);
fprintf('GMI = %2.2f bit/symbol\n', GMItot);
fprintf('NGMI = %2.2f \n', NGMI);
fprintf('BER with HD based on LLRs =  %2.6f \n', PreFECBER);

%% SD-FEC Encoder/Decoder
if isfield(P, 'SDFEC') && (P.SDFEC==1)
    R = Rate;                                                               % Code Rate
    [H, f_punct, n_pct] = PCM(R);                                           % Parity-check matrix
    p = size(H,1);                                                          % n-k parity bits
    n = size(H,2);                                                          % n coded bits (64800)
    k = n-p;                                                                % k information bits
    hDec = comm.LDPCDecoder(H);                                             % initialize the decoder
    infbits = zeros(k,1);                                                   % All-zero inf. bits
    iterations = 50;                                                        % Number of iterations of SD-FEC decoder
    SDFECBER = zeros(1,iterations);                                         % Pre-allocate post FEC BER
    
    % GMI Calculation based on randomly sampled transmitted bits
    GMIperm = zeros(1,iterations);
    for ii = 1:iterations
        perm_seq = datasample(1:length(B), n);                              % Returns the index of 64000 randomly sampled transmitted bits
        codedbits = B(perm_seq);                                            % Finds coded bits at correponding indices
        LLR_X = (-2*codedbits+1).*LLRx_vector(perm_seq);                    % Finds correspinding XPOL LLRs and performs negation
        LLR_Y = (-2*codedbits+1).*LLRy_vector(perm_seq);                    % Finds correspinding YPOL LLRs and performs negation
        Lpunct_X = LLR_X(:);                                                % LLRs for decodeing
        Lpunct_Y = LLR_Y(:);                                                % LLRs for decodeing
        
        AX=LLRx_vector(perm_seq);                                           %LLRs for GMI calculation
        AY=LLRy_vector(perm_seq);                                           %LLRs for GMI calculation
        
        if f_punct
            rp_X = randperm(p);                                             % Random bits to be punctured. This in principle could be optimzied and saved.
            rp_Y = randperm(p);                                             % Random bits to be punctured. This in principle could be optimzied and saved.
            del_pos_X = rp_X(1:n_pct);                                      % Take some parity bits away
            del_pos_Y = rp_Y(1:n_pct);                                      % Take some parity bits away
            Lpunct_X(k+del_pos_X) = 0;
            Lpunct_Y(k+del_pos_Y) = 0;
            AX(k+del_pos_X) = 0;
            AY(k+del_pos_Y) = 0;
        end
        
        GMIx_perm = 0;                                                      % Initialise GMIx to zero
        GMIy_perm = 0;                                                      % Initialise GMIy to zero
        
        for kk=1:m
            GMIx_perm = (1-1/(length(AX)/m)*sum(log2(1+exp((-1).^(codedbits(kk:m:end)).*AX(kk:m:end)))))+GMIx_perm;     % Compute GMI XPOL
            GMIy_perm = (1-1/(length(AY)/m)*sum(log2(1+exp((-1).^(codedbits(kk:m:end)).*AY(kk:m:end)))))+GMIy_perm;     % Compute GMU YPOL
        end
        
        GMIperm(1,ii) = GMIx_perm+GMIy_perm;                                % Average GMI across both polarisaitons
        
        hat_infbitsX = step(hDec, -Lpunct_X);                               % Decoding XPOL
        hat_infbitsY = step(hDec, -Lpunct_Y);                               % Decoding YPOL
        
        PostFECBER_XPOL = sum(sum(infbits ~= hat_infbitsX))/k;              % Count the number of bit errors XPOL
        PostFECBER_YPOL = sum(sum(infbits ~= hat_infbitsY))/k;              % Count the number of bit errors YPOL
        
        SDFECBER(ii) = mean([PostFECBER_XPOL PostFECBER_YPOL]);             % Calculate average post FEC BER for both polarisations
    end
    
    PostFECBER = mean(SDFECBER);                                            % Calculate average post FEC BER over all iterations for both polarisations
    NGMIperm = mean(GMIperm)/(2*log2(M));
    
    fprintf('Post-FEC BER = %2.6f \n', PostFECBER);
    fprintf('GMI SD-FEC = %2.2f bit/symbol\n', mean(GMIperm));
    fprintf('NGMI SD-FEC = %2.2f \n', NGMIperm);
    varargout{1} = mean(GMIperm);                                           % Output GMI based on randomly sampled bits
    varargout{2} = NGMIperm;                                                % Output NGMI based on randomly sampled bits
    varargout{3} = PostFECBER;                                              % post-FEC BER
end

fprintf('-------------------------------------------------\n');

if P.plot
    figure('Name','GMI vs Time');
    plot(movmean(GMI_t.',2^4-1));
    legend('X-Pol.','Y-Pol.'),xlabel('Data Index'),ylabel('GMI (bits/symbol)');
end
