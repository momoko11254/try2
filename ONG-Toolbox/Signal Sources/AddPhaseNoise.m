function [SignalOut, varargout] = AddPhaseNoise(SignalIn, P)
% Adds phase noise to a signal
%
% Signal=AddPhaseNoise(Signal,P)
%
% Inputs:
% Signal        - optical input signal structure containing fields
% P.Linewidth   - linewidth in Hz
% P.commonphase - same phase noise for X and Y pols
%
% Returns:
% Signal        - output signal structure
%
% Author: Domanic Lavery, 2010
% Modified: Milen Paskov, December 2013

%% Create Parameters
Nt = size(SignalIn.Et,2);
[~, TT] = MakeTimeFrequencyArray(SignalIn);
dT = TT(2);

SignalOut = SignalIn;

%%
if (~isfield(P, 'PNoiseX') || ~isfield(P, 'PNoiseY'))
    NoiseVariance = 2*pi*dT*P.Linewidth;
    sdev = sqrt(NoiseVariance);                             % Standard Deviation
    
    P.PNoiseX = sdev*cumsum(randn(1,Nt));
    
    if (isfield(P,'commonphase'))
        P.PNoiseY = P.PNoiseX;
    else
        P.PNoiseY = sdev*cumsum(randn(1,Nt));
    end
end

SignalOut.Et(1,:) = SignalIn.Et(1,:).*exp(1j*P.PNoiseX);
SignalOut.Et(2,:) = SignalIn.Et(2,:).*exp(1j*P.PNoiseY);

varargout{1} = P;
%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=2))
    disp(['Adding Linewidth of ' num2str(P.Linewidth/1e3) 'kHz']);
end
end