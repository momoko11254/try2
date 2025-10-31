function [FOout, Homodyned] = FO_Removal(SignalIn, P)

%% CMA Equalisation
%mu = [1e-2 5e-3 2e-3 1e-3 5e-4 3e-4 1e-4];

% mu = [5e-3 3e-3];
% 
% mu = [0.005 0.004 0.003 0.001 0.0005 0.0003 0.0003 0.0003 0.0003 0.0003];
mu = [1e-3 5e-4 1e-4];

numAve = length(mu);
for q = 1:numAve
    
    disp(['Simulating EQ ' num2str(q) ' of ' num2str(numAve)]);
    P.mu = mu(q);
    P.ModFormat = 'QPSK';
    
    [equalised, P] = QAM_RDE_fast(SignalIn,P);
    
    % define matix as inverse Jones matrix of polarisation rotation
    if (q==0)
        Hxx = P.Taps(1,:);
        Hxy = P.Taps(2,:);
        Hyx = fliplr(-1*conj((Hxy)));
        Hyy = fliplr(1*conj((Hxx)));
        P.Taps = [Hxx; Hxy; Hyx; Hyy];
    end
end % End EQ Convergence loop

temp = equalised;
temp.FF = MakeTimeFrequencyArray(temp);

%% Frequency Offset Estimation
P.N3dB = 1e9;
P.HetMethod = 'MeanFourier';
Homodyned = Heterodyne(temp, P);

%% Frequency Offset Removal (from original SignalIn)
P.HetMethod = 'Measured';
FOout = Homodyned.FreqOffset;
end