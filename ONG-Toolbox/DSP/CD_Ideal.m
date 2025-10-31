function [varargout] = CD_Ideal(varargin)
%dispComp Performs ideal dispersion compensation
%%
% INPUTS variable
% (XSignal, YSignal, P) - 2 Single Pol. signals wih complex sybols
% (SignalIn, P) - Dual Pol. signal with complex symbols
% (IxSignal, QxSignal, IySignal, QySignal, P) - 4 Real signal, one each for
% I & Q on both polarizatons
% P.D - Fibre dispersion parameter [s/m^2]
% P.RefWavelength - Reference Wavelength [m]
% P.totalFibreSpan - Total Fibre length [m]
% Optional Inputs
% Optional Inputs
% P.Return = 'real' - Optional returns detected IxSignal, QxSignal,
%                     IySignal, QySignal as real ?1
% P.Return = 'single pol' - Optional returns detected XSignal, YSignal  +-1 -+j
% P.Return = 'dual pol' - defauls returns dual pol  SignalOut  +-1 -+j
%
% Outputs - see above
% [ IxSignal QxSignal IySignal QySignal ]
% [ XSignal YSignal ]
% [ SignalOut ]

%%
% Incoming signals

if (nargin == 2) % (SignalIn, P)
    SignalIn = varargin{1};
    P = varargin{2};
elseif (nargin == 3) % (XSignal, YSignal, P)
    XSignal = varargin{1};
    YSignal = varargin{2};
    P = varargin{3};
    [ SignalIn ] = polCombine( XSignal, YSignal );
elseif (nargin == 5) % (IxSignal, QxSignal, IySignal, QySignal, P)
    IxSignal = varargin{1};
    QxSignal = varargin{2};
    IySignal = varargin{3};
    QySignal = varargin{4};
    P = varargin{5};
    
    SignalIn = IxSignal;
    SignalIn.Et(1,:) = IxSignal.Et + 1i*QxSignal;
    SignalIn.Et(2,:) = IySignal.Et + 1i*QySignal;
end

SignalOut = SignalIn;

% Converts SI to Optical Units
P=SItoOpt(1,P);

% Speed of light
% c=3e5;              % nm/ps
c = physconst('lightspeed')*1e-3;

Np = size(SignalIn.Et,1);                   % Total number of points
% dF = 1e-12*SignalIn.Fs/Nt;                % Spectral resolution (THz)
FF = MakeTimeFrequencyArray(SignalIn)/1e12; % Frequency array (THz)

% Group Velocity Delay paramater Beta '2'
% have removed the minus sign from standard function to apply reverse dispersion
B2 = P.D*P.RefWavelength^2/(2*pi*c);   	% -ps^2/km

% Set up array to apply dispersion
d2 = 1i/2*B2*(2*pi*FF).^2;

% For dual polarisations if they exist
D = ones(Np,1)*exp( P.totalFibreSpan*d2 );

% Convert signal to freq domain
Ef=ifft(SignalIn.Et,[],2);

% Apply the compensation
Ef = Ef.*D;

% Fourier Transform to time domain
SignalOut.Et = fft(Ef,[],2);

% Outputs - see above
% [ IxSignal QxSignal IySignal QySignal ]
% [ XSignal YSignal ]
% [ SignalOut ]

% Return the signals
if ~isfield(P, 'Return') || ( strcmp(P.Return, 'dual pol') )
    varargout{1} = SignalOut; % Return the dual pol signal (default)
elseif ( strcmp(P.Return, 'single pol') )
    % Return the X and Y pols as separate signals
    [XSignal, YSignal] = polSplitter( SignalOut );
    varargout{1} = XSignal;
    varargout{2} = YSignal;
    
elseif ( strcmp(P.Return, 'real') )
    % Return 4 real signals
    IxSignal = SignalOut;
    IxSignal.Et = real(SignalOut.Et(1,:));
    
    QxSignal = SignalOut;
    QxSignal.Et = imag(SignalOut.Et(1,:));
    
    IySignal = SignalOut;
    IySignal.Et = real(SignalOut.Et(2,:));
    
    QySignal = SignalOut;
    QySignal.Et = imag(SignalOut.Et(2,:));
    
    varargout{1} = IxSignal;
    varargout{2} = QxSignal;
    varargout{3} = IySignal;
    varargout{4} = QySignal;
end
end