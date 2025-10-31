function [SignalOut1,SignalOut2,SignalOut3]=Coupler3x3(varargin)
% Returns the output fields from a four port optical coupler for one or
% two input signals. Works for one or two polarisation states
%
% S_in1__	    __S_out1
%        \	   /
%         |   |
% S_in2___|___|___S_out2
%         |   |
%         |   |
% S3_in__/	   \__S_out3
%
% [signalOut4,signalOut5,signalOut6]=Coupler3x3(SignalIn1,SignalIn2,SignalIn3,P)
%
% Inputs:
% varargin      - Input field structures
% P.coupling    - coupling ratio
%
% Returns:
% SignalOut1    - output signal structure 1
% SignalOut2    - output signal structure 2
% SignalOut3    - output signal structure 3
% 
% Author: Domaniç Lavery, December 2013.

%% Outputs from 3 ports
SignalOut1=varargin{1};
SignalOut2=varargin{1};
SignalOut3=varargin{1};

SignalIn1=varargin{1};

%% Work out which input ports are used
if nargin == 2,                  % Single input case
    P=varargin{2};
    SignalIn2=SignalIn1; SignalIn2.Et=zeros(size(SignalIn2.Et));
    SignalIn3=SignalIn1; SignalIn3.Et=zeros(size(SignalIn3.Et));
elseif nargin ==3                % Two input case
    P=varargin{3};
    SignalIn2=varargin{2};
    SignalIn3=SignalIn1; SignalIn3.Et=zeros(size(SignalIn3.Et));
else % nargin==4                 % Three input case
    P=varargin{4};
    SignalIn2=varargin{2};
    SignalIn3=varargin{3};
end

%% Set up 3x3 coupler transfer function
if isfield(P,'CouplingRatio')
    error('3x3 Coupling Ratio not implemented')
else
    if(isfield(P,'verbose')&&(P.verbose==1)), disp('default 1:1:1 coupling ratio'), end
    kl = 2*pi/9; % 2pi/9 is a 1:1:1 coupler, see Xie et al. OpEx vol.20 num.2
    a = (2/3)*exp(1i*kl)+(1/3)*exp(-1i*2*kl);
    b = (1/3)*exp(-1i*2*kl)-(1/3)*exp(1i*kl);
    tbttransfer=([a b b;...
        b a b;...
        b b a]);
end

%% Apply 3x3 filter transfer function to inputs
[CouplerOutputX]=tbttransfer*([SignalIn1.Et(1,:);SignalIn2.Et(1,:);SignalIn3.Et(1,:)]);
[CouplerOutputY]=tbttransfer*([SignalIn1.Et(2,:);SignalIn2.Et(2,:);SignalIn3.Et(2,:)]);

%% Output Structures
SignalOut1.Et(1,:) = CouplerOutputX(1,:);
SignalOut2.Et(1,:) = CouplerOutputX(2,:);
SignalOut3.Et(1,:) = CouplerOutputX(3,:);

SignalOut1.Et(2,:) = CouplerOutputY(1,:);
SignalOut2.Et(2,:) = CouplerOutputY(2,:);
SignalOut3.Et(2,:) = CouplerOutputY(3,:);
end