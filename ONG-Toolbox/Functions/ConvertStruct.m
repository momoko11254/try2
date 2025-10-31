function [Signal] = ConvertStruct(Signal, P)
% Converts old saved waveforms to the format
%
% [Signal] = ConvertStruct(Signal, P)
%
% Inputs:
% Signal            - Signal structure
% P.Fb              - Symbol rate [Hz]
% P.Fc              - Center wavelength [m]
%
% Returns:
% Signal            - Modified signal structure
%
% Author: Milen Paskov, December 2013

%% Remove old parameters
if (isfield(Signal, 'dT'))
    Signal = rmfield(Signal, 'dT');
end
if (isfield(Signal, 'Nt'))
    Signal = rmfield(Signal, 'Nt');
end
if (isfield(Signal, 'Ns'))
    Signal = rmfield(Signal, 'Ns');
end
if (isfield(Signal, 'Np'))
    Signal = rmfield(Signal, 'Np');
end
if (isfield(Signal, 'dF'))
    Signal = rmfield(Signal, 'dF');
end
if (isfield(Signal, 'Nb'))
    Signal = rmfield(Signal, 'Nb');
end
if (isfield(Signal, 'TT'))
    Signal = rmfield(Signal, 'TT');
end
if (isfield(Signal, 'FF'))
    Signal = rmfield(Signal, 'FF');
end

%% Add new parameters
Signal.Fb = P.Fb;
Signal.Fs = P.Fs;
Signal.Fc = P.Fc;
Signal.Fchan = P.Fchan;
end