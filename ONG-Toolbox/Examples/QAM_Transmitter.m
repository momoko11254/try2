function [SignalOut, varargout] = QAM_Transmitter(P)
% Ideal Multichannel QAM Transmitter.
% RRC, Low Pass filtering included. Decorrelation between channels
% implemented. Phase noise the same on all channels.
%
% [SignalOut, varargout] = QAM_Transmitter(P)
%
% Inputs:
% P.Fb                      - Channel symbol rate [Hz]
% P.Fs                      - Sample rate [Hz]
% P.Fc                      - Center frequency [Hz]
% P.ModFormat               - Modulation format (needs to be square)
% P.PatternLength           - PRBS length
% P.Symbols                 - Number of symbols (default 2^(P.PatternLength)-1)
% P.Channels                - Number of channels (default 1)
%
% Returns:
% SignalOut                 - Output signal structure
% P                         - Parameter structure
%
% Author: Milen Paskov, December 2013

%% Paramaters
if isfield(P, 'Tx')
    Tx = P.Tx;
else
    Tx = P;
    %%% Tx Electrical Filters
    Tx.n = 5;
    Tx.BW = Tx.Fb*0.7;
    
    %%% Tx Linewidth
    Tx.Linewidth = 10e3;          % Linewidth [Hz]
end

%% Generate pseudorandom binary sequence for modulation
if ~isfield(Tx, 'Symbols')
    Tx.Symbols = 2^(P.PatternLength)-1;
end
SequenceInit = prbs_mex(Tx.Symbols, P.PatternLength, 1); % Generate binary pseudorandom sequence (using mex)

%% Sample rate needs to be atleast 2*'Channel' Banwidth
Tx.Fs = max(Tx.Fs, 2*((Tx.Channels-1)*Tx.Spacing + Tx.Fb));

%%
if ~isfield(Tx, 'Channels')
    Tx.Channels = 1;
end
for Channel = 1:Tx.Channels
    %% Decorelate Sequence
    Sequence = circshift(SequenceInit,[0 -floor((Channel-1)*(2^P.PatternLength-1)/Tx.Channels)]);
    
    %% Create QAM Signal in Np polarisations
    ModulatedSignal = QAM_Generator(Tx,Sequence);
    temp = ModulatedSignal;
    
    %% Upsample and Root Raised Cosine Filtering (RRC)
    Tx.Ns = ceil(Tx.Fs/temp.Fb);
    if (isfield(Tx, 'RRCFilter') && (Tx.RRCFilter == 1))
        UpSampled = ZeroPad(temp, Tx);
        MFilter = RRCFilter(UpSampled, Tx);
        temp = MFilter;
    else
        UpSampled = SampleAndHold(temp, Tx);
        temp = UpSampled;
    end
    
    %% Transmitter Bessel Low Pass Filter
    TxFilter = BesselLowPassFilter(temp, Tx);
    temp = TxFilter;
    
    %% Add phase noise
    if isfield(Tx, 'Linewidth');
        % If PNoiseX/PNoiseY exist might want to change here
        PNLoaded = AddPhaseNoise(temp, Tx);
        temp = PNLoaded;
    end
    
    %% Set launch power
    if isfield(Tx, 'PdBm');
        LaunchPower = SetPower(temp, Tx);
        temp = LaunchPower;
    end
    
    %% Frequency Shift
    if Tx.Channels > 1
        Tx.FreqOffset = Tx.Fchan(Channel)-Tx.Fc;
        ShiftedSignal = FrequencyShifter(temp, Tx);
        temp = ShiftedSignal;
    end
    
    %% Add channel to SignalOut
    if Channel == 1
        SignalOut = temp;
        SignalOut.Fchan = temp.Fc;
    else
        SignalOut.Et = SignalOut.Et+temp.Et;
        SignalOut.Fchan(Channel) = temp.Fc;
    end
end
SignalOut.Fc = Tx.Fc;
varargout{1} = Tx;
end