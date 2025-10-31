function [SignalOut, varargout] = FunctionTemplate(SignalIn, P)
% Template for a new function
%
% [SignalOut, varargout] = FunctionTemplate(SignalIn, P)
% If optional arguement P is not included default values are returned
%
% Inputs:
% SignalIn          - Signal structure
%
% Optional Inputs:
% P.XX              - description of XX [Units]
%
% Returns:
% SignalOut         - Output signal structure
%
% Author: X Y, Month Year

%% Create Parameters
% e.g dT dF TT FF
% You can use function "MakeTimeFrequencyArray"
SignalOut = SignalIn;

%% Default Parameters
% Check if all parameter in P are set, if not set defaults ones
if ~isfield(P, 'XX'),
    P.XX = 0;
end

%% Function Implementation
% Anything that is you feel is impronant to outside of the function but is
% not attached to SignalOut can be save in P-structure.

% Then P is returned
varargout{1} = P;

%% Verbose
% Print some details about the function if verbose is used
if(isfield(P, 'verbose') && (P.verbose>=1))
    disp('Function FunctionTemplate');
    disp(['XX: ' num2str(P.XX) '[Units]']);
end
end