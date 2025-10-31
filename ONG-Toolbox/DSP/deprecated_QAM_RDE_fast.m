function [SignalOut, varargout] = QAM_RDE_fast(SignalIn, P)
% Blind Equaliser using the Radially Directed Algorithm for updated and
% minimising least mean square. Updated on symbol based. Can be used with
% all M-QAM. 
% 
% [SignalOut, varargout] = QAM_RDE_fast(SignalIn, P)
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
% Modified: Domanic Lavery, 2014

SignalOut = SignalIn;

%% Init
% Threadss
if ~isfield(P,'Threads')
    P.Threads = 1;
end

% window shape used for learning parameter
if isfield(P,'GaussianWindow')
    shape = gausswin(P.FilterLength);
elseif isfield(P,'ChebWin')
    shape = chebwin(P.FilterLength);
else
    shape = ones(1,P.FilterLength);
end

tapcenter=floor((P.FilterLength+1)/2); % index of central tap

if isfield(P,'Taps')
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Reusing Taps'), end
    % reuse taps from previous run
    H11 = P.Taps(1,:);    H12 = P.Taps(2,:);
    H21 = P.Taps(3,:);    H22 = P.Taps(4,:);
elseif isfield(P,'RotateEQTaps')
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Initialise Taps (Rotated)'), end
    % initial AFIR tap weights
    H11=zeros(1,P.FilterLength); H11(tapcenter)=1/sqrt(2);
    H12=zeros(1,P.FilterLength); H12(tapcenter)=-1/sqrt(2);
    H21=zeros(1,P.FilterLength); H21(tapcenter)=1/sqrt(2);
    H22=zeros(1,P.FilterLength); H22(tapcenter)=1/sqrt(2);
else
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Initialise Taps'), end
    % initial AFIR tap weights
    H11=zeros(1,P.FilterLength); H11(tapcenter)=1;
    H12=zeros(1,P.FilterLength); H12(tapcenter)=0;
    H21=zeros(1,P.FilterLength); H21(tapcenter)=0;
    H22=zeros(1,P.FilterLength); H22(tapcenter)=1;
end

%% Radii initialised
if(~isfield(P,'ModFormat'))
    error('Need to specify modulation format in EQ')
end

str = P.ModFormat;
if strcmp(str(end-2:end),'QAM')
    P.M = str2double(str(1:end-3));
    pointvec = (1:2:sqrt(P.M)).^2;
    pointsSum = 4*sum(pointvec)/sqrt(P.M);                                                  % mean symbol energy (complete over 1 quadrant)
    radii = sqrt(unique(sort([(sum(nchoosek(pointvec,2),2))'  2*pointvec]))/pointsSum);     % Vector of radii
else
    switch str
        case 'BPSK'
            radii = 1/sqrt(2);
        case 'QPSK'
            radii = 1;
        otherwise
            if strcmp(str(end-2:end),'PSK') % arbitrary PSK
                P.M = str2double(str(1:end-3));
                radii = 1/sqrt(2);
            else
                error('unknown modulation format in P.ModFormat')
            end
    end
end

%% Equalizer (call mex function)
% N.B the interleave blocks simplify the interface with C++
[fout2n1,fout2n2,H11,H12,H21,H22]=interleave(1,SignalIn.Et(1,:),SignalIn.Et(2,:),H11,H12,H21,H22);
for index = 1:length(P.mu)
    if (length(P.mu)>1&&isfield(P,'verbose')&&P.verbose>=1), fprintf('.'); end
    
    mu = P.mu(index).*shape;
    [out1,out2,P.ErrorX,P.ErrorY] = rde_qam_mex(fout2n1,fout2n2,H11,H12,H21,H22,radii,mu,P.Threads);
end
[SignalOut.Et(1,:),SignalOut.Et(2,:),H11,H12,H21,H22]=interleave(-1,out1,out2,H11,H12,H21,H22);

if isfield (P,'PhaseRotation'),
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

P.Taps = [H11;H12;H21;H22];
varargout{1} = P;
end