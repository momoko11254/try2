function SignalOut = Heterodyne(SignalIn, P)
% Function to recover frequency offset between Signal and LO in ph & pol
% diverse coherent detection: Option of fourier method, BWA, exponential
% GWA, or mean BWA (4th power auto-correlation)
% P.HetMethod = 'Fourier'  => fourier method: no further args needed
% P.HetMethod = 'BWA'      => Possible further argument P.N3dB - length of exponential tail
% P.HetMethod = 'AutoCorr' => Auto-Correlation method: no further args needed

SignalOut = SignalIn;
SignalOut.FF = MakeTimeFrequencyArray(SignalIn);

slength = length(SignalIn.Et(1,:));
numVec = (1:slength);               % Sample number Vector

if ~isfield(P, 'HetMethod')
    P.HetMethod = 'MeanFourier';        % Fail-Safe Case
end

switch (P.HetMethod)
    case 'MeanFourier'
        NFFT = 2^20;
        FArrayNew = P.Fb/4*[0:ceil(NFFT/2)-1,ceil(-NFFT/2):-1]/NFFT;
        % mean field estimate across 2 polarisations
        FDpower1 = abs(fft((SignalIn.Et(1,2:2:end).^4),NFFT));
        FDpower2 = abs(fft((SignalIn.Et(2,2:2:end).^4),NFFT));
        
        FDpower = FDpower1 + FDpower2;
        
        [mx, loc] = max(FDpower);        % find maximum

%         FLengthNew = length(SignalOut.FF)/2;
%         FArrayNew = [SignalOut.FF(1:FLengthNew/2) SignalOut.FF(end-FLengthNew/2+1:end)]/4;

        fest = FArrayNew(loc);     % Frequency offset estimate in GHz
        est = fest/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        phaseVec = exp(-1j*est/2*numVec);  % vector of amount of phase per sample to be corrected

        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;    % compensate
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;    % compensate

        SignalOut.FPower = mx;              % Power of signal on clock tone -- use for EQ performance without BER
        
        disp(['Frequency Offset Compensated: ' num2str(fest/1e9) ' GHz']);
        fest2 = fest;
    case 'Fourier'
        %% Fourier Method Heterodyning
        FDpower1 = abs(fft((SignalIn.Et(1,2:2:end).^4)));
        [mx1, loc1] = max(FDpower1);        % find maximum

        FDpower2 = abs(fft((SignalIn.Et(2,2:2:end).^4)));
        [~, loc2] = max(FDpower2);          % find maximum

        FLengthNew = length(SignalOut.FF)/2;
        FArrayNew = [SignalOut.FF(1:FLengthNew/2) SignalOut.FF(end-FLengthNew/2+1:end)]/4;

        fest1 = FArrayNew(loc1);     % Frequency offset estimate in GHz
        fest2 = FArrayNew(loc2);     % Frequency offset estimate in GHz
              
        est1 = fest1/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        est2 = fest2/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        phaseVec1 = exp(-1j*est1/2*numVec);  % vector of amount of phase per sample to be corrected
        phaseVec2 = exp(-1j*est2/2*numVec);  % vector of amount of phase per sample to be corrected

        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec1;    % compensate
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec2;    % compensate

        SignalOut.FPower = mx1;              % Power of signal on clock tone -- use for EQ performance without BER

        disp(['Frequency Offset 1 Estimated: ' num2str(fest1/1e9) ' GHz']);
        disp(['Frequency Offset 2 Estimated: ' num2str(fest2/1e9) ' GHz']);
        disp(['Frequency Offset Compensated: ' num2str(fest1/1e9) ' GHz']);
    case 'MeanFourierPilot'
        NFFT = 2^18;
        FArrayNew = [0:ceil(NFFT/2)-1,ceil(-NFFT/2):-1]/NFFT*P.Fb/2;
        PilotRemoved = SignalIn.Et(:,2:2:end).'.*(P.TrainingSequence');
        
        FPilotRemoved = fft(PilotRemoved.^2,NFFT);
        [mx,loc] = max(sum(abs(FPilotRemoved),2));
        figure,semilogy(FArrayNew/1e9,abs(FPilotRemoved),FArrayNew(loc)/1e9,mx,'o')

        fest = FArrayNew(loc);             % Frequency offset estimate in GHz
        est = fest/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        phaseVec = exp(-1j*est/2*numVec);  % vector of amount of phase per sample to be corrected

        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;    % compensate
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;    % compensate

        SignalOut.FPower = mx;              % Power of signal on clock tone -- use for EQ performance without BER
        
        disp(['Frequency Offset Compensated: ' num2str(fest/1e9) ' GHz']);
        fest2 = fest;
    case 'BWA'
        %% Block Window Accumulator Method
        slength = length(SignalIn.Et(1,:));
        diff1 = zeros(1,slength);
        diff2 = diff1;
        avePh = diff2;
        tot1 = avePh;
        tot2 = avePh;
        numVec = (1:slength);       %% Sample number Vector

        if (isfield(P, 'N3dB'))       %% if exponential decay window
            expFac = 0.5^(1/P.N3dB);    %% exponential Gliding Window decay constant
        else
            expFac = 1;                 %% else Block Window Accumulator
        end

        for s = 3:length(SignalIn.Et(1,:))     %% BWA frequency estimation loop
               if(~mod(s,2))      %% if symbol
                  tot1(s)=expFac*tot1(s-2)+(SignalIn.Et(1,s).*conj(SignalIn.Et(1,s-2)))^4;
                  tot2(s)=expFac*tot2(s-2)+(SignalIn.Et(2,s).*conj(SignalIn.Et(2,s-2)))^4;
                  avePh(s)=imag(log(tot1(s)+tot2(s)))/4;               %% estimated phase per symbol offset
               else
                   avePh(s) = avePh(s-1);           %% carry previous estimate in transitions
               end
               SignalOut.Et(:,s) = SignalIn.Et(:,s)*exp(-1i*numVec(s)*avePh(s)/2);     %% Rotate Output Symbols
        end
        fest = avePh(end)*SignalIn.Fb/2/pi;
        disp(['Frequency Offset Estimated: ' num2str(fest) ' GHz']);

    case 'AutoCorr'
        %%
        d1 = (SignalIn.Et(1,4:2:end).*conj(SignalIn.Et(1,2:2:end-2))).^4;
        d2 = (SignalIn.Et(2,4:2:end).*conj(SignalIn.Et(2,2:2:end-2))).^4;
        s1 = sum(d1);
        s2 = sum(d2);
        est1 = imag(log(s1+s2))/4;

        phaseVec = exp(-1j*est1/2*numVec);           %% vector of amount of phase per sample to be corrected

        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;
        fest = est1*SignalIn.Fb/2/pi;
        disp(['Frequency Offset Estimated: ' num2str(fest) ' GHz']);
        fest2 = fest;

    case 'Measured'
        %%
        fest = P.FreqOffset;
        est1 = fest/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        phaseVec = exp(-1j*est1/2*numVec);  % vector of amount of phase per sample to be corrected

        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;

%         SignalOut.FPower = mx;              % Power of signal on clock tone -- use for EQ performance without BER

        disp(['Frequency Offset Compensated: ' num2str(fest/1e9) ' GHz']);
        fest2 = fest;
end

%% Post Rotation of Constellation to Optimum Position
SignalOut.FreqOffset = fest2;

% arg1=angle(sum(SignalOut.Et(1,P.Sdiscard:2:end-P.Ediscard).^4))/4;
% arg2=angle(sum(SignalOut.Et(2,P.Sdiscard:2:end-P.Ediscard).^4))/4;
% 
% SignalOut.Et(1,:)=SignalOut.Et(1,:)*exp(-1i*(arg1+pi/4));
% SignalOut.Et(2,:)=SignalOut.Et(2,:)*exp(-1i*(arg2+pi/4));

