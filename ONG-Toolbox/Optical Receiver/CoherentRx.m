function [SignalOut, varargout] = CoherentRx(SignalIn, P, varargin)
% Converts the optical field to a 4 electric fields corresponding to the
% in-phase and quadrature compenents for each polarisation.
%
% [SignalOut, varargout] = CoherentRx(SignalIn, P, varargin)
%
% Inputs:
% SignalIn          - Input signal structure
% P.LOoffset        - Frequency offset in [Hz]
% P.LOpower         - Local oscillator power [dBm]
% P.Rxtype          - AsymmetricCoupler,Ideal
% P.Linewidth       - Linewidth of local oscillator in [Hz]
% P.Responsivity    - Responsivity of Photodiodes in [A/W]
%
% Optional Inputs:
% LO                - Local oscillator signal structure
%
% Returns:
% SignalOut         - Output signal structure
% P                 - Parameter structure
%
% Author: Seb Savory, July 2005
% Modified: Benn Thomsen, Oct 2010
% Modified: Milen Paskov, December 2013

%% Create Parameters
SignalOut = SignalIn;
[~,Nt] = size(SignalIn.Et);

%% Default Parameters
if (~isfield(P, 'LOOffset'))
    P.LOOffset = 0;
end
if (~isfield(P, 'LOPower'))
    P.LOPower = 9;
end
if (~isfield(P, 'Responsivity'))
    P.Responsivity = 0.6;
end
if (~isfield(P, 'RxType'))
    P.RxType = 'Ideal';
end
if (~isfield (P,'Linewidth'))
    P.Linewidth = 0;
end
ReceiverLoad = 50;      % Output impedance in Ohms

%% LO
if nargin>2
    % LO is passed as a parameter
    LO = varargin{1};
else
    LO = SignalIn;
    LO.Np = 1;
    LOP.Power = P.LOPower;
    LOP.Linewidth = P.Linewidth;
    LOP.Offset = P.LOOffset;
    
    LO = CWLaser(LO, LOP);
end
E_lo = LO.Et(1,:);

%% Signal In
Ex = SignalIn.Et(1,:);
Ey = SignalIn.Et(2,:);

%% Receiver
switch P.RxType
    case 'Ideal'
        SignalOut.Et =[Ex;Ey];
    case 'AsymmetricCoupler'
        E_lo = E_lo*exp(-1j*3*pi/4);
        Exi = P.Responsivity*0.2*abs(Ex+(-1+1j)*E_lo).^2;
        Exq = P.Responsivity*0.2*abs(Ex*(-1+1j)+E_lo).^2;
        Eyi = P.Responsivity*0.2*abs(Ey+(-1+1j)*E_lo).^2;
        Eyq = P.Responsivity*0.2*abs(Ey*(-1+1j)+E_lo).^2;
        
        SignalOut.Et = [Exi+1j*Exq;Eyi+1j*Eyq]*ReceiverLoad;
    case 'OpticalHybridSingle'
        Exi = P.Responsivity*abs(0.5*[1 -1j]*[Ex; E_lo]).^2;
        Eyi = P.Responsivity*abs(0.5*[1 -1j]*[Ey; E_lo]).^2;
        E_lo = 1j*E_lo;
        Exq = P.Responsivity*abs(0.5*[1 -1j]*[Ex; E_lo]).^2;
        Eyq = P.Responsivity*abs(0.5*[1 -1j]*[Ey; E_lo]).^2;
        
        SignalOut.Et =[Exi+1j*Exq;Eyi+1j*Eyq]*ReceiverLoad;
    case 'OpticalHybridDifferential'
        Exi = P.Responsivity*abs(0.5*[1 -1j; -1j 1]*[Ex; E_lo]).^2;
        Eyi = P.Responsivity*abs(0.5*[1 -1j; -1j 1]*[Ey; E_lo]).^2;
        E_lo = 1j*E_lo;
        Exq = P.Responsivity*abs(0.5*[1 -1j; -1j 1]*[Ex; E_lo]).^2;
        Eyq = P.Responsivity*abs(0.5*[1 -1j; -1j 1]*[Ey; E_lo]).^2;
        
        SignalOut.Et = [Exi(1,:)-Exi(2,:)+1j*(Exq(1,:)-Exq(2,:));...
            Eyi(1,:)-Eyi(2,:)+1j*(Eyq(1,:)-Eyq(2,:))]*ReceiverLoad;
    case 'OpticalHybridDifferentialPhotodiode'
        R = @(theta) [cos(theta) sin(theta);...
            -sin(theta) cos(theta)]; % Rotation matrix (anonymous func)
        
        Exip.Et = SignalIn.Et(1,:)+1j*LO.Et; Exip.Fs = SignalIn.Fs;
        Exin.Et = 1j*SignalIn.Et(1,:)+LO.Et; Exin.Fs = SignalIn.Fs;
        Exqp.Et = exp(1j*pi/2)*SignalIn.Et(1,:)+1j*LO.Et; Exqp.Fs = SignalIn.Fs;
        Exqn.Et = exp(1j*pi/2)*1j*SignalIn.Et(1,:)+LO.Et; Exqn.Fs = SignalIn.Fs;
        
        Eyip.Et = SignalIn.Et(2,:)+1j*R(pi/2)*LO.Et; Eyip.Fs = SignalIn.Fs;
        Eyin.Et = 1j*SignalIn.Et(2,:)+R(pi/2)*LO.Et; Eyin.Fs = SignalIn.Fs;
        Eyqp.Et = exp(1j*pi/2)*SignalIn.Et(2,:)+R(pi/2)*1j*LO.Et; Eyqp.Fs = SignalIn.Fs;
        Eyqn.Et = exp(1j*pi/2)*1j*SignalIn.Et(2,:)+R(pi/2)*LO.Et; Eyqn.Fs = SignalIn.Fs;
        
        Ixip = PhotoDiode(Exip,P);
        Ixin = PhotoDiode(Exin,P);
        Ixqp = PhotoDiode(Exqp,P);
        Ixqn = PhotoDiode(Exqn,P);
        
        Iyip = PhotoDiode(Eyip,P);
        Iyin = PhotoDiode(Eyin,P);
        Iyqp = PhotoDiode(Eyqp,P);
        Iyqn = PhotoDiode(Eyqn,P);
        
        Ixi = Ixip.Et-Ixin.Et;
        Ixq = Ixqp.Et-Ixqn.Et;
        Iyi = Iyip.Et-Iyin.Et;
        Iyq = Iyqp.Et-Iyqn.Et;
        
        SignalOut.Et =[Ixi+1j*Ixq;...
            Iyi+1j*Iyq];
end

%% AC Coupling
SignalOut.Et = 1e3*[SignalOut.Et(1,:)-mean(SignalOut.Et(1,:)); ...
    SignalOut.Et(2,:)-mean(SignalOut.Et(2,:))];

varargout{1} = P;
%% Verbose
if(isfield(P, 'verbose') && (P.verbose>=2))
    disp(' ');
    disp('QAM Receiver');
    disp(['LO Offset: ' num2str(P.LOOffset/1e6) 'MHz']);
    disp(['LO Linewidth: ' num2str(P.Linewidth/1e3) 'kHz']);
end

if(isfield(P, 'verbose') && (P.verbose>1))
    power = sum(sum(abs(SignalIn.Et+[E_lo; E_lo]).^2,1),2)/Nt;   % Average power (W)
    pdBm = 10*log10(power)+30-9;                                          % Average power (dBm)
    
    PeakSwingVoltage = max(real(SignalOut.Et(1,:)))-min(real(SignalOut.Et(1,:)));
    OutputRMS = sqrt(mean(mean(abs(SignalOut.Et).^2)));
    
    disp(' ');
    disp('Coherent Receiver');
    disp(['LO Power ' num2str(P.LOPower) 'dBm']);
    disp(['Signal Power ' num2str(P.SigPower) 'dBm']);
    disp(['Input power per photodiode is: ' num2str(pdBm) 'dBm']);
    disp(['Photodiode output swing ' num2str(PeakSwingVoltage) 'mV']);
    disp(['Photodiode output RMS ' num2str(OutputRMS) 'mV']);
end
end
