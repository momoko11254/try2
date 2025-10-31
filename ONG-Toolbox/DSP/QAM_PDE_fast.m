function [SignalOut, varargout] = QAM_PDE_fast(SignalIn, P)
% Blind Equaliser using the Radially Directed Algorithm for updated and
% minimising least mean square. It is also interleaved with the Decision
% Directed Phase Estimator. Updated on symbol based. Can be used with all M-QAM. 
% 
% [SignalOut, varargout] = QAM_PDE_fast(SignalIn, P)
%
% Inputs:
% SignalIn          - Signal structure
% P.FilterLength    - full length of adaptive FIR filter
% P.mu              - convergence parameter for LMS algorithm (scalar)
% P.ModFormat       - modulation format to be equalised (i.e. target levels)
% P.CPELength       - filter lenght of phase estimator
% 
% Returns:
% SignalOut         - Output signal structure
% P.Taps            - Filter taps
%
% Author: Milen Paskov, 2013

SignalOut = SignalIn;

%% Filter Coefficients
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

%% Radii initialized
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
            disp('PDE equalization not implemented for BPSK')
            return
        case 'QPSK'
            P.M = 4;
            points = [-1 1]/sqrt(2);
        otherwise
            if strcmp(str(end-2:end),'PSK')
                P.M = str2double(str(1:end-3));
                disp('PDE equalization not implemented for arbitrary PSK')
            else
                error([str ' not a recognised modulation format'])
            end
    end
end

%% Equalizer (call mex function)
fout2n1 = SignalIn.Et(1,:);
fout2n2 = SignalIn.Et(2,:);

H11 = complex(real(H11),imag(H11)); % Force taps complexity
H12 = complex(real(H12),imag(H12));
H21 = complex(real(H21),imag(H21));
H22 = complex(real(H22),imag(H22));

cpewindow = P.CPELength;
for index = 1:length(P.mu)
    mu = P.mu(index).*shape;
    [out1,out2,error1,error2,H11,H12,H21,H22,phase1,phase2] = pde_qam_mex(fout2n1,fout2n2,H11,H12,H21,H22,points,cpewindow,mu);
end

%% Apply phase estimate
SignalOut.Et(1,:) = out1.*exp(-1j*phase1); % derotate by phase1
SignalOut.Et(2,:) = out2.*exp(-1j*phase2); % derotate by phase2

%% Assign outputs
P.ErrorX = error1;
P.ErrorY = error2;

P.PhaseX = phase1;
P.PhaseY = phase2;

if isfield (P,'PhaseRotation'),
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

P.Taps = [H11;H12;H21;H22];
varargout{1} = P;
end