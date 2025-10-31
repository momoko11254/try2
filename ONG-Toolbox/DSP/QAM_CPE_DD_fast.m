function [SignalOut, varargout] = QAM_CPE_DD_fast(SignalIn, P)
% Decision directed carrier phase estimation for M-QAM.
%
% [SignalOut, varargout] = QAM_CPE_DD_fast(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
% P.CPELength       - filter window full length
% P.ModFormat       - modulation format
%
% Returns:
% SignalOut         - Output signal structure
% P.PhaseX          - estimated phase on polarization X [rad]
% P.PhaseY          - estimated phase on polarization Y [rad]
% 
% Authors: Milen Paskov, Domanic Lavery (2012)
% Modified: Domanic Lavery (2014)

SignalOut = SignalIn;

%% Init
% Threads
if ~isfield(P,'Threads')
    P.Threads = 1;
end

%% Radii initialized
if(~isfield(P,'ModFormat'))
    disp('Need to specify modulation format for CPE')
    return
end

str = P.ModFormat;
if strcmp(str(end-2:end),'QAM')
    P.M = str2double(str(1:end-3));
    pointsSum = 4*sum((((1:2:sqrt(P.M)).^2)))/sqrt(P.M);            % mean symbol energy (complete over 1 quadrant)
    points = (-(sqrt(P.M)-1):2:(sqrt(P.M)-1))/sqrt(pointsSum);      % points on x-axis
else
    switch str
        case 'BPSK'
            P.M = 2;
            disp('DD phase estimation not implemented for BPSK')
            return
        case 'QPSK'
            P.M = 4;
            points = [-1 1]/sqrt(2);
        otherwise
            if strcmp(str(end-2:end),'PSK')
                P.M = str2double(str(1:end-3));
                disp('DD phase estimation not implemented for arbitrary PSK')
            else
                error([str ' not a recognised modulation format'])
            end
    end
end

if isfield(P,'Levels')
    points = P.Levels.';
end

P.CPELength = floor(P.CPELength/2);

%% CPE (call mex function)
[EtX,EtY]=interleave(1,SignalIn.Et(1,:),SignalIn.Et(2,:));
[PhiX, PhiY] = cpe_qam_dd_mex(EtX, EtY, points, P.CPELength, P.Threads);

%% Apply phase estimate
SignalOut.Et(1,:) = SignalOut.Et(1,:).*exp(-1j*PhiX); % derotate by phi
SignalOut.Et(2,:) = SignalOut.Et(2,:).*exp(-1j*PhiY);

%% Assign outputs
P.PhaseX = PhiX;
P.PhaseY = PhiY;

if isfield (P,'PhaseRotation')
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

varargout{1} = P;
end