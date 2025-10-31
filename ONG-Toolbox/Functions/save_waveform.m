function save_waveform(head_path,waveform_path,filename,Pinput,tosave,tosaveName)

if ~isunix;filename = strrep(filename,'/','\'); end
[waveform_path1]    = [waveform_path,filename];

if ~exist(waveform_path1,'dir')
    mkdir(waveform_path1)
end

save([waveform_path1,tosaveName],'tosave')

if isunix
    user            = {getenv('USER')};
    pc              = {getenv('HOSTNAME')};
    date            = string(datetime);
else
    user            = {getenv('USERNAME')};
    pc              = {getenv('COMPUTERNAME')};
    date            = string(datetime);
end

Te = struct2table(Pinput);
Tf = table({tosaveName},user,pc,date);
Te = [Te,Tf];

temp_filename = ['waveforms_ledger_',char(user),char(pc),char(date),'.csv'];
temp_filename = strrep(temp_filename,':','_');
temp_filename = strrep(temp_filename,' ','_');

if ~exist(fullfile(head_path,'waveforms_ledger.csv'),'file')
    writetable(Te,fullfile(head_path,'waveforms_ledger.csv'));
else
    writetable(Te,fullfile(head_path,temp_filename),'WriteVariableNames',0);
    if isunix
        system(['cat ',fullfile(head_path,temp_filename),' >> ',fullfile(head_path,'waveforms_ledger.csv')]);
        system(['rm -f ',fullfile(head_path,temp_filename)]);
    else
        system(['copy ',fullfile(head_path,'waveforms_ledger.csv'),' + ',fullfile(head_path,temp_filename),' ',fullfile(head_path,'waveforms_ledger.csv'),' >NUL']);
        system(['del ',fullfile(head_path,temp_filename)]);
    end
end

