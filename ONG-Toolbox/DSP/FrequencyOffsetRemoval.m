function [SignalOut, varargout] = FrequencyOffsetRemoval(SignalIn, P)
% FrequqnecyOffsetRemoval is a function to recover frequency offset between
% Signal and LO in ph & pol.
% 
% [SignalOut, varargout] = FrequqnecyOffsetRemoval(SignalIn, P)
% 
% Inputs:
% SignalIn          - Signal structure
% 
% Optional Inputs:
% P.FOMethod        - Estimation method ('Fourier', 'BWA', 'AutoCorr', 'Measured')
%                     Default: Fourier
% 
% Returns:
% SignalOut         - Output signal structure
% P.FreqOffset      - Estimated and removed frequency offset [Hz]
% 
% Author: David Millar

SignalOut = SignalIn;

%% Create Parameters
FF = MakeTimeFrequencyArray(SignalIn);

numVec = (1:length(SignalIn.Et(1,:)));  % Sample number Vector

if ~isfield(P, 'FOMethod')
    P.FOMethod = 'Fourier';        % Fail-Safe Case
end

switch P.FOMethod
    case 'Fourier'
        %% Fourier Method Heterodyning
        FDpower1 = abs(fft((SignalIn.Et(1,2:2:end).^4)));
        [~, locX] = max(FDpower1);        % find maximum
        
        FDpower2 = abs(fft((SignalIn.Et(2,2:2:end).^4)));
        [~, locY] = max(FDpower2);        % find maximum
        
        FLengthNew = length(FF)/2;
        FArrayNew = [FF(1:floor(FLengthNew/2)) FF(end-floor(FLengthNew/2)+1:end)]/4;
        
        festX = FArrayNew(locX);     % Frequency offset estimate in GHz
        festY = FArrayNew(locY);     % Frequency offset estimate in GHz
        [~, locMean] = max(mean([FDpower1; FDpower2]));        % find maximum
        fest = FArrayNew(locMean);
        
        est = fest/(SignalIn.Fb/2/pi);      % estimate of rads/baud offset
        phaseVec = exp(-1j*est/2*numVec);   % vector of amount of phase per sample to be corrected
        
        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;    % compensate
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;    % compensate
        
        if(isfield(P, 'verbose') && (P.verbose>=1))
            disp(['Frequency Offset X Estimated: ' num2str(festX/1e9) 'GHz']);
            disp(['Frequency Offset Y Estimated: ' num2str(festY/1e9) 'GHz']);
            disp(['Frequency Offset Mean Estimated: ' num2str(fest/1e9) 'GHz']);
        end
    case 'BWA'
        %% Block Window Accumulator Method
        slength = length(SignalIn.Et(1,:));
        diff1 = zeros(1,slength);
        diff2 = diff1;
        avePh = diff2;
        tot1 = avePh;
        tot2 = avePh;
        numVec = (1:slength);               % Sample number Vector
        
        if (isfield(P, 'N3dB'))             % if exponential decay window
            expFac = 0.5^(1/P.N3dB);        % exponential Gliding Window decay constant
        else
            expFac = 1;                     % else Block Window Accumulator
        end
        
        for s = 3:length(SignalIn.Et(1,:))  % BWA frequency estimation loop
            if(~mod(s,2))                   % if symbol
                tot1(s)=expFac*tot1(s-2)+(SignalIn.Et(1,s).*conj(SignalIn.Et(1,s-2)))^4;
                tot2(s)=expFac*tot2(s-2)+(SignalIn.Et(2,s).*conj(SignalIn.Et(2,s-2)))^4;
                avePh(s)=imag(log(tot1(s)+tot2(s)))/4;               % estimated phase per symbol offset
            else
                avePh(s) = avePh(s-1);      % carry previous estimate in transitions
            end
            SignalOut.Et(:,s) = SignalIn.Et(:,s)*exp(-1i*numVec(s)*avePh(s)/2);     % Rotate Output Symbols
        end
        fest = avePh(end)*SignalIn.Fb/2/pi;
        if(isfield(P, 'verbose') && (P.verbose>=1))
            disp(['Frequency Offset Estimated: ' num2str(fest) 'GHz']);
        end
        
    case 'AutoCorr'
        %%
        d1 = (SignalIn.Et(1,4:2:end).*conj(SignalIn.Et(1,2:2:end-2))).^4;
        d2 = (SignalIn.Et(2,4:2:end).*conj(SignalIn.Et(2,2:2:end-2))).^4;
        s1 = sum(d1);
        s2 = sum(d2);
        est = imag(log(s1+s2))/4;
        
        phaseVec = exp(-1j*est/2*numVec);           % vector of amount of phase per sample to be corrected
        
        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;
        fest = est*SignalIn.Fb/2/pi;
        if(isfield(P, 'verbose') && (P.verbose>=1))
            disp(['Frequency Offset Estimated: ' num2str(fest) 'GHz']);
        end
    case 'Measured'
        %%
        fest = P.FreqOffset;
        est = fest/(SignalIn.Fb/2/pi);     % estimate of rads/baud offset
        phaseVec = exp(-1j*est/2*numVec);  % vector of amount of phase per sample to be corrected
        
        SignalOut.Et(1,:) = SignalIn.Et(1,:).*phaseVec;
        SignalOut.Et(2,:) = SignalIn.Et(2,:).*phaseVec;
        
        if(isfield(P, 'verbose') && (P.verbose>=1))
            disp(['Frequency Offset Compensated: ' num2str(fest/1e9) 'GHz']);
        end
end

%% Post Rotation of Constellation to Optimum Position
if isfield (P,'PhaseRotation')
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

P.FreqOffset = fest;
varargout{1} = P;
end