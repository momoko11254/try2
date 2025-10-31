function [tosave,test] = load_waveform(waveform_path,filename,tosaveName)

if ~isunix;filename = strrep(filename,'/','\'); end
[waveform_path1]    = [waveform_path,filename];

if ~exist(waveform_path1,'dir')
    mkdir(waveform_path1)
end

try
    tosave = load([waveform_path1,tosaveName]);
    tosave = getfield(tosave,'tosave');
    test   = 1;
catch
    test = 0;
    tosave = [];
end