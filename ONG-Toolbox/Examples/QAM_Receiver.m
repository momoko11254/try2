function [SignalOut, varargout] = QAM_Receiver(SignalIn, P)
% Coherent Receiver wrapper.
% Sets Signal and LO powers, applies the receiver, low pass filteres the
% signal. Quantisation and then normalization.
%
% [SignalOut, varargout] = QAM_Receiver(P)
%
% Inputs:
% SignalIn                  - Input signal structure
%
% Optional Inputs:
% Note: All or none of the paramaters need to to supplies.
% P.Rx                      - Receiver paramaters
% Rx.Rxtype                 - Coherent receiver type (default 'OpticalHybridDifferential')
% Rx.LOPower                - LO power [dBm] (default 12dBm)
% Rx.SigPower               - Signal power [dBm] (default 23dBm lower than LO). Right now implemented as total signal power.
% Rx.LOOffset               - LO frequency offset [Hz] (default 0Hz)
% Rx.Linewidth              - LO linewidth [Hz] (default 100e3Hz)
% Rx.n                      - Low pass filter order (default 5th)
% Rx.BW                     - Low pass filter bandwidth (default 0.7*P.Fb)
% Rx.Res                    - Quantisation resolution [bits] (default 5.5)
%
% Returns:
% SignalOut                 - Output signal structure
% P                         - Parameter structure
%
% Author: Milen Paskov, December 2013

%% Paramaters
if isfield(P, 'Rx')
    Rx = P.Rx;
else
    Rx = P;
    
    %%% Coherent Receiver Parameters
    Rx.RxType = 'OpticalHybridDifferential';
    Rx.LOPower = 12;
    Rx.SigPower = Rx.LOPower-23;
    Rx.LOOffset = 0.2e9;
    Rx.Linewidth = 10e3;
    
    %%% Rx Electrical Filters
    Rx.n = 5;
    Rx.BW = Rx.Fb*0.7;
    
    %%% Quantisation
    Rx.Res = 6;
end

temp = SignalIn;

%% Rx signal power
% Note: Ideal amplification or attenuation. This is total power.
Rx.GdB = Rx.SigPower-PowerMeter(temp);
Amplified = Gain(temp,Rx);
temp = Amplified;

%% Receiver
CoRxSignal = CoherentRx(temp, Rx);
temp = CoRxSignal;

%% Receiver Bessel Low Pass Filter
RxFilter = BesselLowPassFilter(temp, Rx);
temp = RxFilter;

%% Quantisation
Quantised = Quantiser(temp, Rx);
temp = Quantised;

%% Orthonormalisation (for variation in photodiode responsivity)
Normalised = Orthonormalise(temp);
temp = Normalised;

SignalOut = temp;
varargout{1} = Rx;
end