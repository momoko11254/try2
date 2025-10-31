function SignalOut = PollScopeTek(P, scope)
% Function used to capture data from a Tektornix scope.
% 
% SignalOut = PollScopeTek(P, scope)
% 
% Inputs:
% P.RecordLength        - Desired capture length in the native sampling rate
% scope                 - IP address of the scope
% 
% Returns:
% SignalOut             - captured signal structure
% 
% Author: Domanic Lavery

%% Init Signal
Nt = P.RecordLength;
SignalOut.Et = zeros(2,Nt);

%% Creatring object
obj = instrfind('Type', 'visa-tcpip', 'RsrcName', ['TCPIP0::' scope '::inst0::INSTR'], 'Tag', '');

% Create the VISA-TCPIP object if it does not exist
% otherwise use the object that was found.
if isempty(obj)
    obj = visa('Agilent', ['TCPIP0::' scope '::inst0::INSTR']);
else
    fclose(obj);
    obj = obj(1);
end
obj.InputBufferSize = Nt;
obj.Timeout=100;

fopen(obj);                         % Connect to instrument object, obj

c = onCleanup(@()fclose(obj));
d = onCleanup(@()delete(obj));

%% Initial setup
disp(' ');
disp('Configuring Scope...')
fprintf(obj,'HORIZONTAL:MODE MANUAL'); % Enables HORIZONTAL:MODE:RECORDLENGTH
s = num2str(Nt,'%d');
fprintf(obj, ['HORIZONTAL:MODE:RECORDLENGTH ' s] );
disp(['Record length set to: ' num2str(s)])
fprintf(obj, 'DATA:START 1');
fprintf(obj, ['DATA:STOP ' s]);

fprintf(obj, 'WFMO:ENC BIN');
fprintf(obj, 'WFMO:BN_F RI');
fprintf(obj, 'WFMO:BYT_N 1');
fprintf(obj, 'DATA:SOURCE CH1,CH2,CH3,CH4');
dT = str2double(query(obj, 'WFMOutpre:XINcr?'));
SignalOut.Fs = 1/dT;

%% Trigger Scope Once
fprintf(obj, 'ACQUIRE:STOPAFTER SEQUENCE');
fprintf(obj, 'ACQUIRE:STATE 1');
while str2double(query(obj, 'ACQUIRE:STATE?'))==0
    pause(0.1)
end
fprintf(obj, 'TRIGGER FORCE');
pause(0.5);
while str2double(query(obj, 'ACQUIRE:STATE?'))==1
    pause(0.1);
end

%% Read Data
disp('Downloading Data from Oscilloscope...')
fprintf(obj, 'CURVE?');

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
str2double(fscanf(obj,'%c',x));
SignalOut.Et(1,:) = fread(obj,Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
str2double(fscanf(obj,'%c',x));
SignalOut.Et(1,:) = SignalOut.Et(1,:)+ 1i*fread(obj,Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
str2double(fscanf(obj,'%c',x));
SignalOut.Et(2,:) = fread(obj,Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
str2double(fscanf(obj,'%c',x));
SignalOut.Et(2,:) = SignalOut.Et(2,:)+ 1i*fread(obj,Nt,'int8')';

disp('Closing Scope')
disp(' ');

%% Set Signal Parameters
SignalOut.Fs = 1/dT;
SignalOut.Fb = P.Fb;
SignalOut.Fc = P.Fc;
SignalOut.Fchan = P.Fchan;
end