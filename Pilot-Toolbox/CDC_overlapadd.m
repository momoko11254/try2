function SignalOut = CDC_overlapadd(SignalIn, P)
%% overlap/add chromatic dispersion compensation
%
% Input parameters in SI units:
%     totalFibreSpan
%     D
%     RefWavelength
%
%
% E. Sillekens and W. Yi, March 2019
% 
% Calculate nfft from other parameters [ref: dispCompOAS.m].
% Use exact value for the speed of light.
% Modified: Y. Wakayama June 2019

SignalOut = SignalIn;
c = physconst('LightSpeed');

%% fibre description
dz = P.totalFibreSpan;

% signal paramenters
dT = 1/SignalIn.Fs;

B2 = -P.D*P.RefWavelength.^2/(2*pi*c);
K  = B2/2/(dT.^2)*dz;

%% prepare filter

% nfft = P.FFTsize;
Ne = ceil(abs(1.1*c*P.totalFibreSpan*P.D*SignalIn.Fb*SignalIn.Fs/(SignalIn.Fc^2))); % Number of samples to overlap
Nc = 2^(nextpow2(Ne*4)); % length of FFT/IFFT for overlap and save
if (Nc<4096)
    Nc = 4096;
end
nfft = Nc;

Et = SignalIn.Et.'; % columns are polarisations

M = 2*ceil(abs(2*pi*sqrt(0.5.^2+K.^2))+1); %pulse broadening

if nfft < M
    new_nfft = 2^nextpow2(M);
    warning('FFTsize (%d) should be larger than pulse broadening (%d).\nSetting FFTsize to %d',nfft,M,new_nfft);
    nfft = new_nfft;
end

wT = 2*pi*[0:floor(nfft/2)-1,floor(-nfft/2):-1].'/nfft;  % normalized frequency

L = nfft-M;  % length of the signal blocks
H = exp(-1j*(K*wT.^2 + M/2*wT)); % dispersion and delay
[Nt,Np] = size(Et);

% output with pulse broadening
Ny = Nt + M;
y = zeros(Ny,Np);

%% apply filter
istart = 1;
while istart < Nt
    iend = min(istart + L-1,Nt);
    X = fft(Et(istart:iend,:),nfft);
    Y = ifft(X.*H);
    yend = min(Ny,istart + nfft-1);
    y(istart:yend,:) = y(istart:yend,:) + Y(1:(yend-istart+1),:);
    istart = istart + L;
end

%% output signal
if isfield(P,'mode')&&strcmpi(P.mode,'full')
    SignalOut.Et =  y.';
elseif isfield(P,'mode')&&strcmpi(P.mode,'valid')
    SignalOut.Et = y(M+1:end-M,:).';
elseif isfield(P,'mode')&&strcmpi(P.mode,'circular')
    SignalOut.Et = y(M/2+1:end-M/2,:).';
    SignalOut.Et(:,1:M/2) = SignalOut.Et(:,1:M/2) + y(end-M/2+1:end,:).';
    SignalOut.Et(:,end-M/2+1:end) = SignalOut.Et(:,end-M/2+1:end) + y(1:M/2,:).';
else
    % mode = 'same'
    SignalOut.Et = y(M/2+1:end-M/2,:).';
end
end
