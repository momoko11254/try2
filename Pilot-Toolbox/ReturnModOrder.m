function M = ReturnModOrder(str)
%% Return number of constellation points
switch str
    case 'shaped24dB1024QAM'
        M = 1024;
    case 'shaped1024QAM'
        M = 1024;
    case 'shaped2048QAM'
        M = 2048;
    case 'QPSK'
        M = 4;
    otherwise
        if strcmp(str(end-2:end),'QAM')
            M = str2double(str(1:end-3));
        else
            error([str ' not a recognised modulation format'])
        end
        if isnan(M)
            error([str 'is not a recognised modulation format'])
        end
end
end