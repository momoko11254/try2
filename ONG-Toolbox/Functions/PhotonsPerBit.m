function [photons] = PhotonsPerBit(Power, wavelength, bitrate)
%PHOTONS photons per bit calculation
%
% photons = Photons( Power, wavelength, bitrate, coderate )
%
% Power [dBm]
% wavelength [m]
% bitrate [bits/s]
%
% e.g. tx bitrate 112, lambda 1554 nm, Pwr -30dBm
% Photons(-30, 1554e-9, 112e9)

hc = (6.626068e-34)*(2.99792458e8); % J*m

photons = (10.^((Power/10)-3))/(hc/wavelength); % photons per second (Hz)

photons = photons/(bitrate); % photons per bit

end

