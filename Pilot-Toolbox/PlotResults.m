function PlotResults(figIte, T)
xval = T.No;
figure(figIte); subplot(411); hold on; grid on; box on;
plot(xval, T.SNRx, 'b^');
plot(xval, T.SNRy, 'rv');
plot(xval, 10*log10(mean(10.^(0.1*[T.SNRx,T.SNRy]))), 'go');
legend('X-Pol.', 'Y-Pol.'), xlabel('Index'), ylabel('SNR (dB)');
drawnow;

figure(figIte); subplot(412); hold on; grid on; box on;
plot(xval, T.GMIx,'b^');
plot(xval, T.GMIy,'rv');
plot(xval, mean([T.GMIx,T.GMIy]), 'go');
legend('X-Pol.','Y-Pol.'), xlabel('Index'), ylabel('GMI (bits/symbol)');
drawnow;

figure(figIte); subplot(413); hold on; grid on; box on;
plot(xval, T.AIRx, 'b^');
plot(xval, T.AIRy, 'rv');
plot(xval, mean([T.AIRx,T.AIRy]), 'go');
legend('X-Pol.','Y-Pol.'), xlabel('Index'), ylabel('AIR (bits/symbol)');

figure(figIte); subplot(414); hold on; grid on; box on;
semilogy(xval, T.BERx,'b^');
semilogy(xval, T.BERy,'rv');
semilogy(xval, mean([T.BERx,T.BERy]), 'go');
legend('X-Pol.','Y-Pol.'), xlabel('Index'), ylabel('Pre-FEC BER');
drawnow;
end