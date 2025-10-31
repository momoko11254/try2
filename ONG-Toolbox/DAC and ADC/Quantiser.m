function Signal = Quantiser(Signal, P)
% Implements an ideal Digital-to-analog converter (DAC) or ADC.
% Assumes an electrical signal as the imput.
% Works for single or dual pol signals
%
% Signal = Quantiser(Signal, P)
% 
% Inputs:
% Signal        - Dignal structure
% P.Res         - Resolution [bits]
%
% Optional inputs
% P.Vmin        - Quantisation range (V)
% P.Vmax        - [V] Values outside the range P.Vmin -> P.Vmax will be clipped
% P.IntOut      - will return only integer values for the signal components in the range 0 -> 2^P.Res-1
%
% Returns:
% Signal        - Signal structure
%
% Author: Sean Kilmurray, November 2013

% Quantisation levels
Levels = ceil(2^P.Res);

% Signal Components
I = real(Signal.Et);
Q = imag(Signal.Et);

% Clip the Signal components
if isfield(P, 'Vmax')
    I(I>=P.Vmax) = P.Vmax;
    Q(Q>=P.Vmax) = P.Vmax;
end

if isfield(P, 'Vmax')
    I(I<=P.Vmin) = P.Vmin;
    Q(Q<=P.Vmin) = P.Vmin;
end

% Get the minimum range of the signal accross all signal components
if isreal(Signal.Et)
    VrangeMin = min(min(I,[],2));
    VrangeMax = max(max(I,[],2));
else % Complex field
    VrangeMin = [min(min(I,[],2)), min(min(Q,[],2))];
    VrangeMax = [max(max(I,[],2)), max(max(Q,[],2))];
end

% Values to set dynamic range after quantisation
Vmin = min(VrangeMin);
Vmax = max(VrangeMax);

% Set the minumum to zero accross all signal components
I = I - min(VrangeMin);
Q = Q - min(VrangeMin);

% Get the max range of the signal accross all signal components
if isreal(Signal.Et)
    VrangeMax = max(max(I,[],2));
else % Complex field
    VrangeMax = [max(max(I,[],2)), max(max(Q,[],2))];
end

% Set the maximum to one accross all signal components
I = I./max(VrangeMax);
Q = Q./max(VrangeMax);

% Round to nearest integer level
I = round(I*(Levels-1));
Q = round(Q*(Levels-1));

if (~isfield(P, 'IntOut')  || (P.IntOut == 0))
    % Set the dynamic range of the signal to Vim -> Vmax
    I = I./(Levels-1);
    Q = Q./(Levels-1);
    
    I = (I.*(Vmax - Vmin)) + Vmin;
    Q = (Q.*(Vmax - Vmin)) + Vmin;
end

% Return the quantised signal;
if isreal(Signal.Et);
    Signal.Et = I;
else
    Signal.Et = I + 1i*Q;
end

end