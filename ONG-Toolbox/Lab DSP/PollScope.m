function [SignalOut, P] = PollScope(P)

% IP for Tektronic Scopes
% TekScope1_old = '128.40.39.66'; % This scope is no longer with us
TekScope1 = '128.40.39.92';   % New Scope for 2014, replaces TekScope1
TekScope2 = '128.40.39.67';
% TekScope3 = '128.40.39.70'; % Scope was on loan

% IP for Agilent Scopes
AgiScope1 = '128.40.39.84';
AgiScope2 = '128.40.39.85';
AgiScope3 = '128.40.39.86';

switch P.Scope
    case 1
        SignalOut = PollScopeTek(P, TekScope1);
    case 2
        SignalOut = PollScopeTek(P, TekScope2);
    case 3
        SignalOut = PollScopeAgi(P, AgiScope1);
    case 4
        SignalOut = PollScopeAgi(P, AgiScope2);
    case 5
        SignalOut = PollScopeAgi(P, AgiScope3);
    otherwise
        error('Scope unknown')
end
