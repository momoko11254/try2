function [SignalOut, varargout] = QAM_DDE_4x4_fast(SignalIn, P)
% Blind Equaliser using the Decision Directed Algorithm for updated and
% minimising least mean square. Uses 4x4 real structure. Updated on symbol
% based. Can be used with all M-QAM. 
% 
% [SignalOut, varargout] = QAM_DDE_4x4_fast(SignalIn, P)
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
% Author: Milen Paskov, 2013

SignalOut = SignalIn;

%% Filter Coefficients
if isfield(P,'GaussianWindow')
    mu = P.mu*gausswin(P.FilterLength);
else
    mu = P.mu*ones(1,P.FilterLength);
end

tapcenter=floor((P.FilterLength+1)/2); % index of central tap

if isfield(P,'Taps')
    %     disp('Reusing Taps')
    H11 = P.Taps(1,:);  H12 = P.Taps(2,:); H13 = P.Taps(3,:); H14 = P.Taps(4,:);
    H21 = P.Taps(5,:);  H22 = P.Taps(6,:); H23 = P.Taps(7,:); H24 = P.Taps(8,:);
    H31 = P.Taps(9,:);  H32 = P.Taps(10,:);H33 = P.Taps(11,:);H34 = P.Taps(12,:);
    H41 = P.Taps(13,:); H42 = P.Taps(14,:);H43 = P.Taps(15,:);H44 = P.Taps(16,:);
else
    %     disp('Initialise Taps')
    H11 = zeros(1,P.FilterLength); H11(tapcenter) = 1;          %% initial AFIR tap weights 11
    H12 = zeros(1,P.FilterLength); H12(tapcenter) = 0;          %% initial AFIR tap weights 12
    H13 = zeros(1,P.FilterLength); H13(tapcenter) = 0;          %% initial AFIR tap weights 13
    H14 = zeros(1,P.FilterLength); H14(tapcenter) = 0;          %% initial AFIR tap weights 14
    H21 = zeros(1,P.FilterLength); H21(tapcenter) = 0;          %% initial AFIR tap weights 21
    H22 = zeros(1,P.FilterLength); H22(tapcenter) = 1;          %% initial AFIR tap weights 22
    H23 = zeros(1,P.FilterLength); H23(tapcenter) = 0;          %% initial AFIR tap weights 23
    H24 = zeros(1,P.FilterLength); H24(tapcenter) = 0;          %% initial AFIR tap weights 24
    H31 = zeros(1,P.FilterLength); H31(tapcenter) = 0;          %% initial AFIR tap weights 31
    H32 = zeros(1,P.FilterLength); H32(tapcenter) = 0;          %% initial AFIR tap weights 32
    H33 = zeros(1,P.FilterLength); H33(tapcenter) = 1;          %% initial AFIR tap weights 33
    H34 = zeros(1,P.FilterLength); H34(tapcenter) = 0;          %% initial AFIR tap weights 34
    H41 = zeros(1,P.FilterLength); H41(tapcenter) = 0;          %% initial AFIR tap weights 41
    H42 = zeros(1,P.FilterLength); H42(tapcenter) = 0;          %% initial AFIR tap weights 42
    H43 = zeros(1,P.FilterLength); H43(tapcenter) = 0;          %% initial AFIR tap weights 43
    H44 = zeros(1,P.FilterLength); H44(tapcenter) = 1;          %% initial AFIR tap weights 44
end

%% Levels initialized
if(~isfield(P,'ModFormat'))
    error('Need to specify modulation format in EQ')
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
fout2n1 = real(SignalIn.Et(1,:));
fout2n2 = imag(SignalIn.Et(1,:));
fout2n3 = real(SignalIn.Et(2,:));
fout2n4 = imag(SignalIn.Et(2,:));

[out1,out2,out3,out4,error1,error2,H11,H12,H13,H14,H21,H22,H23,H24,H31,H32,H33,H34,H41,H42,H43,H44] ...
    = dde_qam_4x4_mex(fout2n1,fout2n2,fout2n3,fout2n4,H11,H12,H13,H14,...
    H21,H22,H23,H24,H31,H32,H33,H34,H41,H42,H43,H44,points,mu);

SignalOut.Et(1,:) = out1+1j*out2;
SignalOut.Et(2,:) = out3+1j*out4;

%% Assign outputs
P.ErrorX = error1;
P.ErrorY = error2;

if isfield (P,'PhaseRotation'),
    SignalOut.Et = bsxfun(@times,SignalOut.Et,exp(-1i*(angle(sum(SignalOut.Et.^4,2))/4+pi/4)));
end

P.Taps = [H11;H12;H13;H14; H21;H22;H23;H24; H31;H32;H33;H34; H41;H42;H43;H44];
varargout{1} = P;
end