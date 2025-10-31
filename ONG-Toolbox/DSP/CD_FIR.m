function [SignalOut, varargout] = CD_FIR(SignalIn, P)
% Finite impulse response (FIR) implementation of a chromatic dispersion
% compensating filter
%
% Source: "Digital Filters for Coherent Optical Receivers" Savory, Optics
% Express 2008 
% 
% [SignalOut, varargout] = CD_FIR(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
% P.NSpans          - Number of fibre spans
% P.Span            - Length of one span [m]
% P.D               - Dispersion [s/m^2]
%
% Returns:
% SignalOut         - Output signal structure
% P.CDTaps          - Taps used for CD compensation
%
% Author:

%% Create Parameters
c=3e8;
dT = 1/SignalIn.Fs;

SignalOut = SignalIn;         % define output signal

%% Default Parameters
if isfield(P, 'totalFibreSpan')
    FiberLength = P.totalFibreSpan; % For backward compatibility
else
    FiberLength = P.NSpans*P.Span;
end

if isfield(P, 'RefWavelength')
    Wavelength = P.RefWavelength; % For backward compatibility
elseif isfield(P, 'Wavelength')
    Wavelength = P.Wavelength;  % For backward compatibility
else
    Wavelength = c/SignalIn.Fc;
end

%% CD Compensation Filter
if(~FiberLength==0)
    N_tap=abs(2*floor(abs(P.D)*Wavelength^2*FiberLength/(2*c*dT^2))+1); % define filter length
    
    if(isfield(P, 'verbose') && (P.verbose>=1))
        disp(' ');
        disp(['Applying dispersion of ' num2str(P.D*FiberLength*1e3) ' ps/nm']);
        disp(['Dispersion compensation using ' num2str(N_tap) 'Taps']);
    end
    
    k=(-floor(N_tap/2):1:floor(N_tap/2));       % define tap index vector
    
    a=sqrt(1j*c*dT^2/(P.D*Wavelength^2*FiberLength))*exp(-1j*pi*c*dT^2.*k.^2/(P.D*Wavelength^2*FiberLength));
    % define tap weights (note extra T^2 in gain term: not in paper, but correct)
    
    %% Frequency Domain Filtering using Matlab funct fftfilt
    SignalOut.Et = fftfilt(a,SignalIn.Et.').';            % overlap-add filtering
    
    %% Time domain filtering operations using inbuilt function (Very Slow)
    % Ft(1,:) = filter(a,1,SignalIn.Et(1,:));     % filter on x polarisation using time domain function
    % Ft(2,:) = filter(a,1,SignalIn.Et(2,:));     % filter on y polarisation
    
    %% End filtering
    P.CDTaps = a;
end
varargout{1} = P;
end