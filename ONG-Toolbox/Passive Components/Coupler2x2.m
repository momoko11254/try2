function [SignalOut1,SignalOut2]=Coupler2x2(varargin)
% Returns the output fields from a four port optical coupler for one or
% two input signals. Works for one or two polarisation states
%
% S_in1__	    __S_out1
%        \     /
%      	  -----
% S_in2__/     \__S_out2
%
% [SignalOut1,SignalOut2]=Coupler2x2(SignalIn1,SignalIn2,P)
%
% Inputs:
% varargin      - Input field structures
% P.coupling    - coupling ratio
%
% Returns:
% SignalOut1    - output signal structure 1
% SignalOut2    - output signal structure 2
% 
% Author: Benn Thomsen, September 2004.
% Modified: Domaniç Lavery, December 2013.

%% Outputs from 2 ports
SignalOut1=varargin{1};
SignalOut2=varargin{1};

SignalIn1=varargin{1};

%% Work out which input ports are used
if nargin == 2,                  % Single input case
    P=varargin{2};
    SignalIn2=SignalIn1; SignalIn2.Et=zeros(size(SignalIn2.Et));
else % nargin ==3                % Two input case
    P=varargin{3};
    SignalIn2=varargin{2};
end

if ~isfield(P,'Coupling')
    P.Coupling = 0.5;
end


%% Set up 2x2 coupler transfer function
% always a pi/2 phase shift for crossing the S12 or S21
% see "Fiber optic measurement techniques" by Hui & O'Sullivan, Section 2.1.1
tbttransfer=@(ep) ([sqrt(1-ep) 1j*sqrt(ep);...
                    1j*sqrt(ep) sqrt(1-ep)]);


%% Apply 3x3 filter transfer function to inputs
[CouplerOutputX]=tbttransfer(P.Coupling)*([SignalIn1.Et(1,:);SignalIn2.Et(1,:)]);
[CouplerOutputY]=tbttransfer(P.Coupling)*([SignalIn1.Et(2,:);SignalIn2.Et(2,:)]);

%% Output Structures
SignalOut1.Et(1,:) = CouplerOutputX(1,:);
SignalOut2.Et(1,:) = CouplerOutputX(2,:);

SignalOut1.Et(2,:) = CouplerOutputY(1,:);
SignalOut2.Et(2,:) = CouplerOutputY(2,:);
end