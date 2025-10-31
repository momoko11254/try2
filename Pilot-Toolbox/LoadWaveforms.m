function [CoSig, P] = LoadWaveforms(P)
% Modified: Yuta Wakayama, July 2019
% fontsize = 10;
%% Signal Acquisition
if P.ReadfromScope
    switch (P.Scope)
        case 1
            IP = '128.40.39.92';
            P.ScopeRate = 50e9;                                 % Sample rate of scope (S/s)
            P.RecordLength = 2*ceil(P.TakeFirstSamples*(P.ScopeRate/(2*P.Fb)));
            CoSig = PollTekScope_Win(IP, P.RecordLength);
        case 2
            IP = '128.40.39.84';
            P.ScopeRate = 80e9;                                 % Sample rate of scope (S/s)
            P.RecordLength = 2*ceil(P.TakeFirstSamples*(P.ScopeRate/(2*P.Fb)));
            CoSig = getTraceAgilent(IP, P.RecordLength);
        case 3
            IP = '128.40.39.85';
            P.ScopeRate = 80e9;                             	% Sample rate of scope (S/s)
            P.RecordLength = 2*ceil(P.TakeFirstSamples*(P.ScopeRate/(2*P.Fb)));
            CoSig = getTraceAgilent(IP, P.RecordLength);
        case 4
            IP = '128.40.39.86';
            P.ScopeRate = 80e9;                                 % Sample rate of scope (S/s)
            P.RecordLength = 2*ceil(P.TakeFirstSamples*(P.ScopeRate/(2*P.Fb)));
            CoSig = getTraceAgilent(1:4, P.RecordLength, P.Scope-1);
            CoSig.Et = [1 1i 0 0;0 0 1 1i]*CoSig.Waveform;
        case 5
            oldFold = cd('Z:\Users\Public\Documents\Agilent\Infiniium\Apps\MultiScope\');          
            Waveforms = Multiscope('Digitize');
            cd(oldFold);
            chan = 1;
            for j = 1:length(Waveforms)
                if(~isempty(Waveforms{j}))
                    Signal.Waveforms(chan,:) = Waveforms{j}.Data.';
                    if mod(chan,2)==0
                        Signal.Et(ceil(chan/2),:) = Signal.Waveforms(chan,:)+1j*Signal.Waveforms(chan-1,:);
                    end
                    chan = chan + 1;
                end
            end
            Signal.Fs = 160e9;
            Signal.Nt = length(Signal.Et);
            CoSig = Signal;
        case 6 % Multiscope running on Scope
            % IP addres from the leader is set in Keysight_MultiChannel.m
            % channel numbers are set in Keysight_MultiChannel.m (ch = 1:2:7 for RealEdge on both scopes)
            Waveforms = Keysight_MultiChannel();
            Signal.Et = Waveforms.data(:,[1,5]).' + 1i*Waveforms.data(:,[3,7]).';
            Signal.Fs = 1/Waveforms.XInc; % Fs = 1/dt
            Signal.Nt = Waveforms.Points;
            CoSig = Signal;
            
        otherwise
            error('no known scope')
    end
%     CoSig.Fb = P.baudRateGS;
    CoSig.Fb = P.Fb;
    CoSig.Ns = CoSig.Fs/CoSig.Fb;
    CoSig.Et = CoSig.Et(:, 1:round(P.TakeFirstSamples*(CoSig.Ns/2)));
    
    CoSig.Nt = length(CoSig.Et(1,:));
    temp = CoSig;
    
%     figure('Name','Signal Spectrum','InvertHardcopy','off','Color',[1 1 1]);
%     set(gca,'LooseInset',get(gca,'TightInset'));
%     plot(MakeTimeFrequencyArray(CoSig)/1e9, 10*log10(abs(fft(CoSig.Et(1,:))).^2));
%     xlabel('Frequency (GHz)'), ylabel('Magnitude (dB)'), title('Received Signal')
%     axis([-CoSig.Fs/(2*1e9) CoSig.Fs/(2*1e9) 40 130]), grid on

elseif P.ReadfromFile
    if P.Scope == 1
        P.ScopeRate = 50e9;
    elseif P.Scope == 5
        P.ScopeRate = 160e9;
    else
        P.ScopeRate = 80e9;
    end
    
    load(fullfile(P.Path,P.FName));
    disp(['Waveform --> ',P.FName]);
    
    if isfield(EP,'PatternLength'), P.TakeFirstSamples = EP.TakeFirstSamples; end
    if isfield(EP,'PatternLength'), P.PatternLength = EP.PatternLength; end
    if isfield(EP,'ModFormatData'), P.ModFormatData = EP.ModFormatData; end
    if isfield(EP,'ModFormatPilot'), P.ModFormatPilot = EP.ModFormatPilot; end
    if isfield(EP,'baudRateGS'), P.baudRateGS = EP.baudRateGS; end
    if isfield(EP,'FrameLen'), P.FrameLen = EP.FrameLen; end
    if isfield(EP,'PilotBasedDSP'), P.PilotBasedDSP = EP.PilotBasedDSP; end
    if isfield(EP,'PilotSeqLen'), P.PilotSeqLen = EP.PilotSeqLen; end
    if isfield(EP,'PilotRat'), P.PilotRat = EP.PilotRat; end
    if isfield(EP,'OH'), P.OH = EP.OH; end
    if isfield(EP,'OSNR'), P.OSNR = EP.OSNR; end
    if isfield(EP,'TxFrame'), P.TxFrame = EP.TxFrame; end

    CoSig.Et = CoSig.Et(:, 1:(P.TakeFirstSamples*(CoSig.Ns/2)));
    CoSig.Nt = length(CoSig.Et(1,:));
    
%     figure('Name','Signal Spectrum','InvertHardcopy','off','Color',[1 1 1]);
%     set(gca,'LooseInset',get(gca,'TightInset'));
%     plot(MakeTimeFrequencyArray(CoSig)/1e9, 10*log10(abs(fft(CoSig.Et(1,:))).^2));
%     xlabel('Frequency (GHz)'), ylabel('Magnitude (dB)'), title('Received Signal')
%     axis([-CoSig.Fs/(2*1e9) CoSig.Fs/(2*1e9) 40 130]), grid on
    
else
    disp('Load from file or read from scope has not been specified!!')
    return
end
end
