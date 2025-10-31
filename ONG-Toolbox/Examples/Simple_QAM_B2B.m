% Creates an M-ary square QAM test signal at 1 sample per symbol
% and receives the test signal using a balanced coherent receiver.
clear all
close all

% Parameters
P.verbose = 0;
P.PatternLength = 15; % PRBS pattern length

% Receiver Parameters
Rx.Rxtype = 'OpticalHybridDifferential';
Rx.LOpower = 20; % LOpower (dBm)
Rx.LOoffset = 0e9; % LO Frequency offset (Hz)

%% Generate pseudorandom binary sequence for modulation
% Sequence = prbs_mex(2^(P.PatternLength)-1,P.PatternLength,1); % Generate binary pseudorandom sequence (using mex)
Sequence = PRBS(2^(P.PatternLength)-1,P.PatternLength); % Generate binary pseudorandom sequence

%% Create QAM Signal in Np polarisations
ModParams.M=4;   % number of constellation points
ModParams.Np=2;  % number of polarisations
ModParams.ModFormat = 'QPSK';
ModParams.PatternLength = 15;

ModulatedSignal = QAM_Generator(ModParams,Sequence);
temp = ModulatedSignal;

%% Set Signal Parameters
temp.Fb = 3.125e9; % symbol rate (Hz)
temp.Fs = temp.Fb; % simulation sampling rate (Hz)
temp.Fc = 3e8/1550e-9; % central wavelength (signal) frequency (Hz)

%% Noise Loading
P.OSNR=100; % OSNR (dB)
Noised=AddNoise(temp,P);
temp = Noised;

%% Set Tx Power
P.PdBm = -54.7; % (dBm)
TxSignal = SetPower(temp,P);
disp(['Power is: ' num2str(round(1e9*PowerMeter(TxSignal))/1e9) ' dBm']);
temp = TxSignal;

%% Rx Preamplification
RxAmpParams.GdB = P.PdBm;
RxAmpParams.NFdB = 3; % EDFA noise figure (dB)
Amplified = EDFA(temp,RxAmpParams);
temp = Amplified;

%% Receiver
CoRxSignal = CoherentRx(temp, Rx);
temp = CoRxSignal;

%% Orthonormalisation (for variation in photodiode responsivity)
Normalised = Orthonormalise(temp);
temp = Normalised;

%% BER Counting
[SignalBER, PBER]= BER_QAM(temp,ModParams,Sequence);
disp(['BER = ' num2str(PBER.BER)])

%% Plot Output
plot(SignalBER.Et(1,:),'.'); hold on; plot(ModulatedSignal.Et(1,:),'ro','markerfacecolor','k')
