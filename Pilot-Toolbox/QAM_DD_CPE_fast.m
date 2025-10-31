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



% function SignalOut = QAM_DD_CPE_fast(SignalIn,P)
% % Decision directed carrier phase estimation for M-QAM.
% %
% %   SignalOut = QAM_DD_CPE_fast(SignalIn,P)
% %
% %   where:
% %   P.NTapsFFELength = filter window half length
% %   P.XPCorr = cross polarisation correlation in phase
% %
% %   Authors: Milen Paskov, Domanic Lavery (2012)
% %
% 
% %% Init
% if ~isfield(P,'Threads')    
%     P.Threads = 1;
% end
% 
% if(~isfield(P,'ModFormat'))
%     disp('Need to specify modulation format for k-means clustering')
%     return
% end
% 
% switch P.ModFormat
%     case 'BPSK'
%         disp('DD phase estimation not implemented for BPSK')
%         return
%         %     case '8PSK'
%         %     case '16QAM'
%     case 'QPSK'
%         points = [-1 1]/sqrt(2);
%     case '16QAM'
%         pointsSum = sum([2 2*10 18])/4;               % mean symbol energy (complete over 1 quadrant)
%         points = [-3 -1 1 3]/sqrt(pointsSum)/sqrt(2); % points on x-axis
%     case '64QAM'
% %         pointsSum = sum([2 2*10 18 2*26 2*34 3*50 2*58 2*74 98])/16;    %% mean symbol energy (complete over 1 quadrant)
% %         P.QAM64_Radii = sqrt([2 10 18 26 34 50 58 74 98]/pointsSum)/sqrt(2);    %% Vector of radii
% %         OuterQuad = 1/sqrt(2)*P.QAM64_Radii(9);     %% Halfwidth of constellation
% %         DiffQuad = OuterQuad/7;
% %         points = DiffQuad*(-7:2:7);
%         
%         % Division by sqrt(2) only if you apply HybridComp after EQ
% %         points = points/sqrt(2);
%         pointsSum = sum([2 2*10 18 2*26 2*34 3*50 2*58 2*74 98])/16;    % mean symbol energy (complete over 1 quadrant)
%         points = [-7 -5 -3 -1 1 3 5 7]/sqrt(pointsSum)/sqrt(2);         % points on x-axis
%         case '256QAM'
%                     pointsSum = 170;
% %         radii = sqrt([2 10 18 26 34 50 58 74 82 90 98 106 122 130 146 162 170 178 194 202 218 226 234 242 250 274 290 306 338 346 394 450]/pointsSum);
%         points = (-15:2:15)/sqrt(pointsSum)/sqrt(2);
%         case '1024QAM'
%                     pointsSum = 170;
% %         radii = sqrt([2 10 18 26 34 50 58 74 82 90 98 106 122 130 146 162 170 178 194 202 218 226 234 242 250 274 290 306 338 346 394 450]/pointsSum);
%         points = (-15:2:15)/sqrt(pointsSum)/sqrt(2);
%     otherwise
%         disp('unknown modulation format in P.ModFormat')
%         return
% end
% 
% points = points*sqrt(2); 
% 
% if isfield(P,'Levels')
%     points = P.Levels.';
% end
% 
% SignalOut = SignalIn;
% 
% %% mex function
% [EtX,EtY]=interleave(1,SignalIn.Et(1,:),SignalIn.Et(2,:));
% [Phi1, Phi2] = cpe_qam_dd_mex(EtX, EtY, points, P.NTapsFFELength, P.Threads);
% 
% %% apply phase estimate
% SignalOut.Et(1,:) = SignalOut.Et(1,:).*exp(-1j*Phi1); % derotate by phi
% SignalOut.Et(2,:) = SignalOut.Et(2,:).*exp(-1j*Phi2);
% 
% SignalOut.Phase1 = Phi1;
% SignalOut.Phase2 = Phi2;
% 
% if isfield (P,'PhaseRotation')
%     arg1=angle(sum(SignalOut.Et(1,P.SDiscard+2:end-P.EDiscard).^4))/4; % residual phase estimation
%     arg2=angle(sum(SignalOut.Et(2,P.SDiscard+2:end-P.EDiscard).^4))/4;
%     
%     SignalOut.Et(1,:)=SignalOut.Et(1,:)*exp(-1i*(arg1+pi/4)); % residual phase rotation
%     SignalOut.Et(2,:)=SignalOut.Et(2,:)*exp(-1i*(arg2+pi/4));
% end