function [SignalOut, varargout] = DAC(SignalIn, P)
% Behavioural model to emulate a Digital-to-Analog converter
% including quantization, sample&hold and ENOB fitting
%
% Utilizes the following functions:
% - quantizer.m
% - BesselLowPassFilter.m;
%
% Inputs:
% SignalIn.Et       - Analog complex symbol sequence to be DAC interpolated
% P.upsample        - Upsampling factor for simulation BW (digital domain to
%                     analog domain)
% P.DAC.Vsw         - Output voltage swing [V]
% P.DAC..Res        - DAC resolution [bits]
% P.DAC..ENOB       - DAC ENOB (average over signal BW) [bits]
%
% Optional Inputs:
% P.DAC.FullScale   - Max output voltage swing [V]
%
% Returns:
% SignalOut         - Output signal structure
%
% Author: Gabriele Liga, January 2012

%%  Linear quantization and mapping into voltage levels
Po=P;
P.Res=P.DAC.Res;

% Ratio between fullscale voltage and output voltage
if isfield(P.DAC,'FullScale')
    r=P.DAC.FullScale/P.DAC.Vsw;
else
    r=1;
end

P.IntOut=1;
SignalOut=Quantiser(SignalIn,P);
Vsw=P.DAC.Vsw;
LUT=(-Vsw/2:Vsw/(2^P.DAC.Res-1):+Vsw/2);
MapSr=LUT(real(SignalOut.Et)+1);                                                 % Maps digital signal in voltage analog values
MapSi=LUT(imag(SignalOut.Et)+1);
S=MapSr+1i*MapSi;

%% Sample&hold
SignalOut.Et=rectpulse(S.',P.upsample).';
% updating parameters
SignalOut.Ns=P.upsample*P.Ns;
SignalOut.Fs=P.upsample*P.Fs;
Po.Ns=SignalOut.Ns;
Po.Fs=SignalOut.Fs;

%% Noise loading stage for ENOB matching
snr_ideal=6.02*P.DAC.Res+1.76;
snr=6.02*P.DAC.ENOB+1.76-20*log10(r);                                     % Calculates SNR [dB] from specified ENOB (Kester, 2009) assuming DAC nonlinearity negligible

P.BW=P.Fb;
Stemp=SignalOut;
Stemp.Et=[SignalOut.Et(1,:)-mean(SignalOut.Et(1,:)); ...
    SignalOut.Et(2,:)-mean(SignalOut.Et(2,:))];
SigFilt=BesselLowPassFilter(Stemp,P);
SigPow=mean(abs((SigFilt.Et(1,:)).^2));
Qnoise=SigPow/(10^(snr_ideal/10));                                         % Quantization noise Power (ideal case)

Noise_pow=Qnoise*10^((snr_ideal-snr)/10)-Qnoise;                           % Additional noise Power aprt from quantization noise [dB]

Noise_pow=Noise_pow/Po.Fb*Po.Fs;                                           % Additional noise Power over simulation BW
Noise=sqrt(Noise_pow/2)*[(randn(1,length(SignalOut.Et))+1i*randn(1,length(SignalOut.Et)));...
    (randn(1,length(SignalOut.Et))+1i*randn(1,length(SignalOut.Et)))];             % Gaussian noise for both pols signal

% Adding noise
SignalOut.Et=SignalOut.Et+Noise;

varargout{1} = Po;
end