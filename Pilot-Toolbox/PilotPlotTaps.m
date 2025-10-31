function PilotPlotTaps(Taps)

NFFT = 2*size(Taps,2)-1;

xc = fftshift(ifft(fft(Taps,NFFT,2).*conj(fft(Taps([1,2,4,3],:),NFFT,2))),2);
lag = -(size(Taps,2)-1):(size(Taps,2)-1);

figure
for ii = 1:4
    subplot(2,2,ii)
%     plot(lag,abs(xc(ii,:)))
    hold on,plot(real(Taps(ii,:))),plot(imag(Taps(ii,:)))
end