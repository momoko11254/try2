function P = WienerCoefficients(P)
% WIENERCOEFFICIENTS
% returns the Wiener filter coefficients
% generated according to [1] Ip & Kahn JLT (2007) '25' 9 "Feedforward Carrier."
%
% constellation penalties from [2] Ip & Kahn JLT (2005) '23' 12 "Carrier Sync."
%
% Author: Carsten Behrens
% Modified: Domanic Lavery
% Modified: Eric Sillekens, Wentin Yi, Hubert Dzieciol, March 2019

if ~isfield(P,'ModFormat')
    P.ModFormat = 'QPSK';
end

str = P.ModFormat;

if strcmp(str,'8QAM')
    eta=1.5/2;     % 8-QAM
elseif strcmp(str(end-2:end),'QAM')
    M = str2double(str(1:end-3));
    eta = mean(abs(qammod(0:M-1,M)).^2)*mean(1./abs(qammod(0:M-1,M)).^2)/2; % Eq (20) from [2]
elseif max(strcmp(str,{'BPSK' 'QPSK' '8PSK'}))
    eta=1.0/2;     % PSK Formats
else
    disp('Warning: Constellation in P.ModFormat not recognised');
    return
end

Fb = P.Fb;

Bref = 12.5e9;
gamma = 2*(Bref/Fb)*10^((P.OSNR)/10);   % vary SNR per symbol (gamma) to find minimum error

% combined_linewidth = sqrt((P.Linewidth.^2)*2);  % assum the same linewidth at Tx and Rx
combined_linewidth = P.Linewidth;
BeatLinewidth = combined_linewidth*1/Fb;   % combined beat-linewidth of Tx- and LO-laser

varN = eta/gamma;           % variance of phase estimation noise

varP = 2*pi*BeatLinewidth;  % variance of laser phase noise

if ~isfield(P,'CPELength')
    f=0.05;     % factor for truncating filter coefficients
    r=varP/varN;
    alpha = (1+r/2)-sqrt(((1+r/2).^2)-1); % z1 pole of filter
    L=ceil(log(f)/log(alpha));    % number of taps
    P.CPELength=L;
else
    disp('Using pre-specified half filter length of Wiener filter')
    L = P.CPELength;
end

L = 2*L + 1; % convert to full filter length

disp(['Wiener filter length: ' num2str(L)]);

if ~isfield(P,'Lambda')
    P.Lambda=floor((L-1)/2);        % filter delay
end

Kp=zeros(L,L);                      % preallocate matrix

for n=1:P.Lambda
    Kp(1:P.Lambda+1-n,1:P.Lambda+1-n)=n*ones(P.Lambda+1-n,P.Lambda+1-n);
end

for n=1:L-P.Lambda-1
    Kp(P.Lambda+1+n:L,P.Lambda+1+n:L)=n*ones(L-P.Lambda-n,L-P.Lambda-n);
end
KpNorm=varP.*Kp;
KnNorm=varN.*eye(L);
P.K=KpNorm+KnNorm;

Kinv = P.K\eye(size(P.K));
onevec = ones(length(P.K),1);
P.KFIR = ((Kinv*onevec)/(onevec'*Kinv*onevec));

%figure; plot(P.KFIR,'o')
%grid on

end