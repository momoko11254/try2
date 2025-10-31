function SignalOut = PollScopeAgi(P, scope)
% Function used to capture data from a Agilent scope.
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
% Authors: Benn Thomsen, Kai Shi, 2013
% Modified: Milen Paskov, 2014

%% Init Signal
Channels = 1:4;
Nt = P.RecordLength;
SignalOut.Et = zeros(length(Channels),Nt);

%% Open ibject for AgilentScope and initialize
% [obj, Signal]=openAgilentScope(scope,P.RecordLength,Channels);

% Connect to instrument object, obj1.
obj = tcpip(scope, 5025);
obj.InputBufferSize = Nt+100;
obj.Timeout=100;
fopen(obj);

% Set cleanup parameters
c = onCleanup(@()disp('Closing scope'));
d = onCleanup(@()fclose(obj));

% For testing purpose
% fprintf(obj,'*IDN?');
% fprintf(fscanf(obj));

comStr = sprintf(':ACQuire:POINts:ANALog %d', P.RecordLength);
fprintf(obj, comStr);
readStr = query(obj,':ACQuire:POINts:DIGital?');
disp(['The the current memory depth is:',readStr]);

fprintf(obj,':WAVeform:FORMat BYTE');
readStr = query(obj,':WAVeform:FORMat?');
disp(['The data format is: ',readStr]);      %BYTE-signed 8- bit integers

% Special Case (2Channels at 160GS/s)
if length(Channels)==2 && Channels(1)==1 && Channels(2)==3
    fprintf(obj,':ACQuire:REDGe 1');
else
    fprintf(obj,':ACQuire:REDGe 0');
end
readStr = query(obj,':ACQuire:REDGe?');
if str2double(readStr)==1
    disp('The RealEdge channel inputs are ON');
else
    disp('The RealEdge channel inputs are OFF');
end
% Remove interpolate
fprintf(obj,':ACQuire:INTerpolate 0');

%% Trigger Scope Once
% AgilentDataSingle(obj);
disp('Initialising oscilloscope single acquisition triggered from the selected channel');
fprintf(obj,':SINGle');

%% Read Data
% Signal=ReadAgilentData(obj, Channels, Signal);
timingJitter = zeros(1,length(Channels));
for i=1:length(Channels)
    comStr = sprintf(':WAVeform:SOURce CHANnel%d', Channels(i));
    fprintf(obj, comStr);
    fprintf('Downloading waveform of Channel %d\n',Channels(i));
    
    readStr = '';
    while ~strcmp(readStr(1:end-1),num2str(Nt))
        pause(0.5);
        readStr = query(obj,':WAVeform:POINts?');
        disp(['The waveform points is:',readStr]);
    end
    
    readStr = query(obj,':WAVeform:XORigin?');
    timingJitter(i)=str2double(readStr);
    disp(['The XOR of Source ', num2str(Channels(i)), ' is ', readStr]);
    fprintf(obj,':WAVEFORM:DATA?');
    SignalOut.Et(i,:) = binblockread(obj,'int8');
end

%% Set Signal Parameters
dT = str2double(query(obj, ':WAVeform:XINCrement?'));
SignalOut.Fs = 1/dT;
SignalOut.Fb = P.Fb;
SignalOut.Fc = P.Fc;
SignalOut.Fchan = P.Fchan;
fprintf('The sampling rate is: %f GHz\n', SignalOut.Fs/1e9);

SignalOut.Et(1,:) = SignalOut.Et(1,:)+1j*SignalOut.Et(2,:);
SignalOut.Et(2,:) = SignalOut.Et(3,:)+1j*SignalOut.Et(4,:);
SignalOut.Et(4,:)=[];SignalOut.Et(3,:)=[];
end