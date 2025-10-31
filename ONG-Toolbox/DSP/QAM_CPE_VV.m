function [SignalOut, varargout] = QAM_CPE_VV(SignalIn, P)
% VITERBICPE_QAM Viterbi Carrier Phase Estimation on QAM Signals
%
% Source: "Nonlinear estimation of PSK-modulated carrier phase with
% application to burst digital transmission", Viterbi and Viterbi, IEEE
% Transactions of Information Theory (1983).
%
% Notes: Uses MATLAB built-in function 'cumsum' to rapidly compute means
%        over Viterbi window.  Assumes transitions are removed from Et.
% 
% [SignalOut, varargout] = QAM_CPE_VV(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
% P.CPELength       - filter window full length (actuall length P.CPELength+1)
% P.ModFormat       - modulation format
%
% Returns:
% SignalOut         - output signal structure
% P.PhaseX          - estimated phase on polarization X [rad]
% P.PhaseY          - estimated phase on polarization Y [rad]
%
% Author: David Millar
% Optimised: Domanic Lavery, September 2010
% Generalized: Milen Paskov, October 2012

SignalOut = SignalIn;

% Pre-allocate arrays %
phi1 = zeros(1,length(SignalIn.Et(1,:)));
phi2 = phi1; p1 = phi1;  p2 = p1;

% adjust viterbi window size for compatibility
% with previous implementations
P.CPELength = floor(P.CPELength/2);

%% Radii initialized
if(~isfield(P,'ModFormat'))
    error('Need to specify modulation format in CPE')
end

switch P.ModFormat
    case 'QPSK'
        SigNL = SignalIn.Et;
    case '16QAM'
        pointsSum = sum([2 2*10 18])/4;
        radii = sqrt([2 10 18]/pointsSum);
        Thr = (radii(2:end)+radii(1:end-1))/2;
        Thr1 = Thr(1);
        Thr2 = Thr(2);
        
        Decisions = (abs(SignalIn.Et)<Thr1)|(abs(SignalIn.Et)>Thr2); % discard inner ring
        SigNL = SignalIn.Et.*Decisions;
    case '64QAM'
        pointsSum = sum([2 2*10 18 2*26 2*34 3*50 2*58 2*74 98])/16;
        radii = sqrt([2 10 18 26 34 50 58 74 98]/pointsSum);
        Thr = (radii(2:end)+radii(1:end-1))/2;
        Thr1 = Thr(1);
        Thr2 = radii(8); % Seems to give better performance than Thr(end)
        
        Decisions = (abs(SignalIn.Et)<Thr1)|(abs(SignalIn.Et)>Thr2); % discard inner rings
        SigNL = SignalIn.Et.*Decisions;
    otherwise
        disp('unknown modulation format in P.ModFormat, assuming QPSK and using all symbols')
        SigNL = SignalIn.Et;
end

%% CPE
% Remove QPSK modulation from signal
SigNL = (SigNL.*exp(1i*pi/4)).^4;

if ~isfield(P, 'CommonPhase')
    temp = cumsum(SigNL(1,:));
    phi1(P.CPELength+2:end-P.CPELength) = temp((2*P.CPELength)+2:end)-temp(1:end-2*P.CPELength-1);
    temp = cumsum(SigNL(2,:));
    phi2(P.CPELength+2:end-P.CPELength) = temp((2*P.CPELength)+2:end)-temp(1:end-2*P.CPELength-1);
    phi1=angle(phi1)/4; % mean feedforward phase estimate on ch 1
    phi2=angle(phi2)/4; % mean feedforward phase estimate on ch 2
else
    disp('Averaging polarisation phase in Viterbi CPE')
    
    if ~isfield(P, 'XPCorr')
        P.XPCorr=1;
    end
    
    temp = cumsum(SigNL(1,:));
    phi1(P.CPELength+2:end-P.CPELength) = temp((2*P.CPELength)+2:end)-temp(1:end-2*P.CPELength-1);
    temp = cumsum(SigNL(2,:));
    phi2(P.CPELength+2:end-P.CPELength) = temp((2*P.CPELength)+2:end)-temp(1:end-2*P.CPELength-1);
    temp = phi1;
    
    phi1 = phi1+P.XPCorr*phi2;
    phi2 = P.XPCorr*temp+phi2;
    phi1=angle(phi1)/4; % mean feedforward phase estimate on ch 1
    phi2=angle(phi2)/4; % mean feedforward phase estimate on ch 2
end

p1(2:end)=floor(0.5+(phi1(1:end-1)-phi1(2:end))*2/pi);  % constants for phase unwrapping in estimates
p2(2:end)=floor(0.5+(phi2(1:end-1)-phi2(2:end))*2/pi);  % comparing with previous symbol

phiun1=phi1+cumsum(p1)*pi/2;    % unwrapped phase estimates
phiun2=phi2+cumsum(p2)*pi/2;

% Alternative phase unwrap method
% phiun1 = unwrap(4*phi1);
% phiun2 = unwrap(4*phi2);

%% Apply phase estimate
SignalOut.Et(1,:)=SignalIn.Et(1,:).*exp(-1i*(phiun1));  % compensate estimated phase error
SignalOut.Et(2,:)=SignalIn.Et(2,:).*exp(-1i*(phiun2));

%% Assign outputs
P.PhaseX = phiun1;
P.PhaseY = phiun2;

if isfield (P,'PhaseRotation')
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

varargout{1} = P;
end