function fig = PlotPilotPayload(Pilot, Payload)
ConsteA = Pilot.Et(:,P.TapCor+1:2:end-3); ConsteB = SigEq.Et(:,2:end);
pltDataX1 = real(ConsteA(1,:)); pltDataX2 = imag(ConsteA(1,:));
pltDataY1 = real(ConsteA(2,:)); pltDataY2 = imag(ConsteA(2,:));
pltDataX3 = real(ConsteB(1,:)); pltDataX4 = imag(ConsteB(1,:));
pltDataY3 = real(ConsteB(2,:)); pltDataY4 = imag(ConsteB(2,:));
fig(2) = figure('Name','Constellations Monitor','InvertHardcopy','off','Color',[1 1 1],'Position',[scrsz(1)+10 scrsz(4)/2-80 scrsz(3)/2.5 scrsz(4)/2]);
set(gca, 'LooseInset', get(gca,'TightInset'));
subplot(221), plot(pltDataX1, pltDataX2, 'k.','markersize',1);
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('XPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');
subplot(222), plot(pltDataY1, pltDataY2,'k.','markersize',1);
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('YPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');
subplot(223), plot(pltDataX3, pltDataX4, 'k.','markersize',1);
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('XPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');
subplot(224), plot(pltDataY3, pltDataY4,'k.','markersize',1);
axis 'square', axis([-1.5 1.5 -1.5 1.5]), grid on;
title('YPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');
set(gca, 'fontsize', fontsize), drawnow
end