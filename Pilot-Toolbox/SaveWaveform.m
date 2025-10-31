function SaveWaveform(CoSig, P)
if ~isfield('FName',P)
    filename = [num2str((P.Fb/1e7),'%04d') 'GBd_' P.ModFormatData];
    if P.PilotBasedDSP==1, filename = ['Pilot_' filename '_P' num2str(P.PilotSeqLen,'%05d') 'C' num2str(P.PilotRat, '%05d')]; end
    if P.LoadWaveforms==3, filename = ['Sim_' filename]; end
    if P.OSNR>0, filename = [filename,'_OSNR' num2str(floor(P.OSNR*100),'%04d')]; end
    if isfield(P,'Linewidth'), filename = [filename 'LW' num2str(P.Linewidth*1e-3,'%04d')]; end
    if isfield(P,'SNR'), filename = [filename '_SNR' num2str(floor(10*log10((10^(0.1*P.SNR(1))+10^(0.1*P.SNR(2)))/2)*100))]; end
    if isfield(P,'No'), filename = ['No' num2str(P.No,'%04d') '_' filename]; end
    filename = [filename '.mat'];
%     if exist([P.Path '\' filename])
%         keyboard
%     end
    P.FName = filename;
end
EP = P;
save(fullfile(P.Path,P.FName), 'CoSig','EP', '-v6');
disp(['Data saved as ' P.FName]);
