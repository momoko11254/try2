function [SignalOut, varargout] = QAM_DDE_fast(SignalIn, P)
% Blind Equaliser using the Decision Directed Algorithm for updated and
% minimising least mean square. Updated on symbol based. Can be used with
% all M-QAM. 
% 
% [SignalOut, varargout] = QAM_DDE_fast(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
% P.FilterLength    - full length of adaptive FIR filter
% P.mu              - convergence parameter for LMS algorithm (can be a vector)
% P.ModFormat       - modulation format to be equalised (i.e. target radii)
% 
% Returns:
% SignalOut         - Output signal structure
% P.Taps            - Filter taps
%
% Authors: Milen Paskov, Domanic Lavery, 2012
% Modified: Domanic Lavery, 2015

SignalOut = SignalIn;

%% Init
% Threads
if ~isfield(P,'Threads')
    P.Threads = 1;
end

% Filter Coefficients
if isfield(P,'GaussianWindow')
    shape = gausswin(P.FilterLength);
else
    shape = ones(1,P.FilterLength);
end

tapcenter=floor((P.FilterLength+1)/2); % index of central tap

if isfield(P,'Taps')
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Reusing Taps'), end
    H11 = P.Taps(1,:); % reuse taps from previous run
    H12 = P.Taps(2,:);
    H21 = P.Taps(3,:);
    H22 = P.Taps(4,:);
elseif isfield(P,'RotateEQTaps')
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Initialise Taps (Rotated)'), end
    H11 = zeros(1,P.FilterLength); H11(tapcenter) = 1/sqrt(2);  % initial AFIR tap weights 11
    H12 = zeros(1,P.FilterLength); H12(tapcenter) = -1/sqrt(2); % initial AFIR tap weights 12
    H21 = zeros(1,P.FilterLength); H21(tapcenter) = 1/sqrt(2);  % initial AFIR tap weights 21
    H22 = zeros(1,P.FilterLength); H22(tapcenter) = 1/sqrt(2);  % initial AFIR tap weights 22
else
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Initialise Taps'), end
    H11 = zeros(1,P.FilterLength); H11(tapcenter) = 1;          % initial AFIR tap weights 11
    H12 = zeros(1,P.FilterLength); H12(tapcenter) = 0;          % initial AFIR tap weights 12
    H21 = zeros(1,P.FilterLength); H21(tapcenter) = 0;          % initial AFIR tap weights 21
    H22 = zeros(1,P.FilterLength); H22(tapcenter) = 1;          % initial AFIR tap weights 22
end

%% Levels initialized
if(~isfield(P,'ModFormat'))
    disp('Need to specify modulation format in EQ')
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
            disp('DD equalization not implemented for BPSK')
            return
        case 'QPSK'
            P.M = 4;
            points = [-1 1]/sqrt(2);
        otherwise
            if strcmp(str(end-2:end),'PSK')
                P.M = str2double(str(1:end-3));
                disp('DD equalization not implemented for arbitrary PSK')
            else
                error([str ' not a recognised modulation format'])
            end
    end
end

%% Equalizer (call mex function)
[fout2n1,fout2n2,H11,H12,H21,H22]=interleave(1,SignalIn.Et(1,:),SignalIn.Et(2,:),H11,H12,H21,H22);
for index = 1:length(P.mu)
    mu = P.mu(index).*shape;
    [out1,out2,P.ErrorX,P.ErrorY] = dde_qam_mex(fout2n1,fout2n2,H11,H12,H21,H22,points,mu,P.Threads);
end
[SignalOut.Et(1,:),SignalOut.Et(2,:),H11,H12,H21,H22,P.ErrorX,P.ErrorY]=interleave(-1,out1,out2,H11,H12,H21,H22,P.ErrorX,P.ErrorY);

%% Assign outputs
P.ErrorX = error1;
P.ErrorY = error2;

if isfield (P,'PhaseRotation'),
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

P.Taps = [H11;H12;H21;H22];
varargout{1} = P;
end