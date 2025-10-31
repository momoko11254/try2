function Signal = PilotPolarisation(Signal,P)

Pilot.Et = Signal.Et(:, 1:P.PilotSeqLen);


SigPilot = [
    Pilot.Et
    flipud(Pilot.Et)
    ];
TxPilot = [
    P.TrainingSequence
    P.TrainingSequence
    ];


if isfield(Signal,'Ns')&&Signal.Ns==2
    TxPilot = kron(TxPilot,[1,0]);
end

NFFT = 2*P.PilotSeqLen-1;

xc = fftshift(ifft(fft(SigPilot,NFFT,2).*conj(fft(TxPilot,NFFT,2)),NFFT,2),2);
lag = (-(P.PilotSeqLen-1):(P.PilotSeqLen-1));

figure
hold on
for ij = 1:4
   subplot(2,2,ij)
%    plot(lag,20*log10(abs(xc(ij,:))))
    plot(lag,abs(xc(ij,:)))
%    xlim([-15,15]);
   ylim([0,max(max(abs(xc)))])
end

% keyboard
