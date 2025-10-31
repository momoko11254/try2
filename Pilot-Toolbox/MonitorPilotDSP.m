function [PilotXI, PilotXQ, PilotYI, PilotYQ,...
    PayloadXI, PayloadXQ, PayloadYI, PayloadYQ, varargout] = ...
    MonitorPilotDSP(Pilot, Payload, NewFig)

% X-Pol Pilot
[PilotXI, PilotXQ] = deal(real(Pilot(1,:)), imag(Pilot(1,:)));
% Y-Pol Pilot
[PilotYI, PilotYQ] = deal(real(Pilot(2,:)), imag(Pilot(2,:)));
% X-Pol Payload
[PayloadXI, PayloadXQ] = deal(real(Payload(1,:)), imag(Payload(1,:)));
% Y-Pol Payload
[PayloadYI, PayloadYQ] = deal(real(Payload(2,:)), imag(Payload(2,:)));

if NewFig
    scrsz = get(0,'ScreenSize');
    fig = figure('Name','Constellations Monitor',...
        'InvertHardcopy','off','Color',[1 1 1],'Position',...
        [scrsz(1)+10 scrsz(4)/2-80 scrsz(3)/2.5 scrsz(4)/2]);
    
    subplot(221), plot(PilotXI, PilotXQ, 'k.','markersize',1);
    axis 'square', axis([-2 2 -2 2]), grid on;
    title('XPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');

    subplot(222), plot(PilotYI, PilotYQ,'k.','markersize',1);
    axis 'square', axis([-2 2 -2 2]), grid on;
    title('YPOL Pilot'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');

    subplot(223), plot(PayloadXI, PayloadXQ, 'k.','markersize',1);
    axis 'square', axis([-2 2 -2 2]), grid on;
    title('XPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');

    subplot(224), plot(PayloadYI, PayloadYQ,'k.','markersize',1);
    axis 'square', axis([-2 2 -2 2]), grid on;
    title('YPOL Payload'), xlabel('Re. (A.U.)'), ylabel('Im. (A.U.)');

    linkdata on
    
    varargout{1} = fig;
end

end