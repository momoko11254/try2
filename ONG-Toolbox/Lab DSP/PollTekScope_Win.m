function Signal = PollTekScope_Win(IPAddress, Nt)

disp('Creating Scope Instrument Object')
obj = instrfind('Type', 'visa-tcpip', 'RsrcName', ['TCPIP0::' IPAddress '::inst0::INSTR'], 'Tag', '');

% Create the VISA-TCPIP object if it does not exist
% otherwise use the object that was found.
if isempty(obj)
    obj = visa('Agilent', ['TCPIP0::' IPAddress '::inst0::INSTR']);
else
    fclose(obj);
    obj = obj(1);
end
obj.InputBufferSize = Nt;
obj.Timeout=100;

fopen(obj);                         % Connect to instrument object, obj

c = onCleanup(@()fclose(obj));
d = onCleanup(@()delete(obj));

s = num2str(Nt,'%d');
fprintf(obj, ['HORIZONTAL:MODE:RECORDLENGTH ' s] );
disp('Horizontal record length set')
fprintf(obj, 'DATA:START 1');
fprintf(obj, ['DATA:STOP ' s]);

fprintf(obj, 'WFMO:ENC BIN');
fprintf(obj, 'WFMO:BN_F RI');
fprintf(obj, 'WFMO:BYT_N 1');
fprintf(obj, 'DATA:SOURCE CH1,CH2,CH3,CH4');
Signal.dT = str2double(query(obj, 'WFMOutpre:XINcr?'));
Signal.Fs = 1/Signal.dT;

disp('Downloading curve data from Oscilloscope')
fprintf(obj, 'CURVE?');

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
Signal.Nt = str2double(fscanf(obj,'%c',x));
Signal.Et = zeros(2,Signal.Nt);
Signal.Et(1,:) = fread(obj,Signal.Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
Signal.Nt = str2double(fscanf(obj,'%c',x));
Signal.Et(1,:) = Signal.Et(1,:)+ 1i*fread(obj,Signal.Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
Signal.Nt = str2double(fscanf(obj,'%c',x));
Signal.Et(2,:) = fread(obj,Signal.Nt,'int8')';

fscanf(obj,'%c',1);
x = str2double(fscanf(obj,'%c',1));
Signal.Nt = str2double(fscanf(obj,'%c',x));
Signal.Et(2,:) = Signal.Et(2,:)+ 1i*fread(obj,Signal.Nt,'int8')';


