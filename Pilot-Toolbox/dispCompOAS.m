function [ varargout ] = dispCompOAS( varargin )
%dispComp Performs dispersion compensation using Over-lap and save FFT
%
% See R. Kudo et. al., "Coherent Optical Single Carrier Transmission Using Overlap Frequency
% Domain Equalization for Long-Haul Optical Systems", JLT V27, No.16, pp. 3721�3728, 2009.
%
% Assuming no frequency offset between Tx and Rx Lo.

%%
% INPUTS variable
% (XSignal, YSignal, P) - 2 Single Pol. signals wih complex sybols
% (SignalIn, P) - Dual Pol. signal with complex symbols
% (IxSignal, QxSignal, IySignal, QySignal, P) - 4 Real signal, one each for
% I & Q on both polarizatons
%
% P.D - Fibre dispersion parameter (ps/nm/km)
% P.RefWavelength - Reference Wavelength (nm)
% P.totalFibreSpan - Total Fibre length (km)
% P.FFTlength  - length of the FFT/IFFT for overlap & save CD comp
%
% Optional Inputs 
% P.Return = 'real' - Optional returns detected IxSignal, QxSignal,
%                     IySignal, QySignal as real �1
% P.Return = 'single pol' - Optional returns detected XSignal, YSignal
% P.Return = 'dual pol' - defauls returns dual pol
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
    varargin{1} = IxSignal;
    varargin{2} = QxSignal;
    varargin{3} = IySignal;
    varargin{4} = QySignal;
    P = varargin{5};
    
    SignalIn = IxSignal;
    SignalIn.Et(1,:) = IxSignal.Et + 1i*QxSignal;
    SignalIn.Et(2,:) = IySignal.Et + 1i*QyxSignal;
end

%%
% SignalIn = SignalRx;
SignalOut = SignalIn;

[~,Nt] = size(SignalIn.Et);

% Speed of light
c=3e8;              % [m/ps]

% if (isfield(P, 'Scrambling') && P.Scrambling)
%    SignalIn.Fb = 2*SignalIn.Fb; % pol scrambled signal occupies x2 bandwidth  
% end

Ne = ceil(abs(1.1*c*P.totalFibreSpan*P.D*SignalIn.Fb*SignalIn.Fs/(SignalIn.Fc^2))); % Number of samples to overlap
Nc = 2^(nextpow2(Ne*4));           % length of FFT/IFFT for overlap and save

if (Nc<4096)
    Nc = 4096;
end
    
dF = SignalIn.Fs/Nc;            % Spectral resolution (Hz)
FF = [0:(Nc/2)-1,-Nc/2:-1]*dF;  % Frequency array (Hz)

X = SignalIn.Et(1,1:end).';
Y = SignalIn.Et(2,1:end).';

% Overlap incoming data
Xb = buffer(X, Nc, Ne*2, 'nodelay');
Yb = buffer(Y, Nc, Ne*2, 'nodelay');

% Connvert signal to freq domain
Xf = ifft(Xb);
Yf = ifft(Yb);

[rw,cl] = size(Xb);

% Group Velocity Delay paramater Beta '2'
% have removed the minus sign from standard function to apply reverse dispersion
B2 = P.D*P.RefWavelength.^2/(2*pi*c);   	% -ps^2/km

% Set up array to apply dispersion
d2 = (1i/2*B2*(2*pi*FF).^2).';

% For dual polarisations if they exist
D = exp( P.totalFibreSpan*d2 );
D = padarray(D, [0 cl-1], 'replicate', 'post');

% Apply the compensation
Xf = Xf.*D;
Yf = Yf.*D;

% Fourier Transform to time domain
X = fft(Xf);
Y = fft(Yf);

% Grab the first set of smaples from the buffer
XoutStart = X(1:Ne,1).';
YoutStart = Y(1:Ne,1).';

% Grab the last set of smaples from the buffer
XoutEnd = X(rw-Ne+1:end,cl).';
YoutEnd = Y(rw-Ne+1:end,cl).';

% Remove the overlapped samples
XoutMid = X(1+Ne:rw-Ne, :);
YoutMid = Y(1+Ne:rw-Ne, :);

[rw,cl] = size(XoutMid);

% Reshape the array and recombine
Xout = [XoutStart, reshape(XoutMid, 1, rw*cl), XoutEnd];
Yout = [YoutStart, reshape(YoutMid, 1, rw*cl), YoutEnd];

SignalOut.Et(1,:) = Xout(1,1:Nt);
SignalOut.Et(2,:) = Yout(1,1:Nt);

%% Outputs - see above

% Return the signals
if ~isfield(P, 'Return') || ( strcmp(P.Return, 'dual pol') )
    varargout{1} = SignalOut; % Return the dual pol signal (default)
elseif ( strcmp(P.Return, 'single pol') )
    % Return the X and Y pols as separate signals
    [ XSignal YSignal ] = polSplitter( SignalOut );
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

