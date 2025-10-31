function P = PilotTaps(Signal,P)

da = 0;

if da
    P.mu = [1,1,1];
    Pilot.Et = [zeros(2,P.FilterLength-1) kron(P.TrainingSequence,[0,1])];
    [temp,P] = QAM_DAE_fast(Signal,Pilot,P);
else
y = P.TrainingSequence;

% not 
% y = kron(P.TrainingSequence,[0,1]);
% Y = fft(P.TrainingSequence,[],2);
% y = ifft([Y(:,1:end/2),zeros(2,P.PilotSeqLen),Y(:,end/2+1:end)],[],2);

if size(Signal.Et,2)==P.PilotSeqLen*2+P.TapCor-1
%     x = Signal.Et(:,1:end-2);
    x = Signal.Et;
else
    x = Signal.Et(:,P.FilterLength:P.PilotDelay*2+P.PilotSeqLen*2);
end

x = [flipud(toeplitz(x(1,P.FilterLength:-1:1),x(1,P.FilterLength:end)));
    flipud(toeplitz(x(2,P.FilterLength:-1:1),x(2,P.FilterLength:end)))];

x = x(:,2:2:end);

% estimate channel x = Ay + b
A = y.'\x.';

% MMSE from wikipedia
% Cx = cov(x.');
% Cz = cov( (A.'\x - y).');
% h=Cx*A'*inv(A*Cx*A'+Cz);

% but this works better
h = pinv(A);

% h = x.'\y.';

Taps = h;

Taps = ([Taps(1:P.FilterLength,:),Taps(P.FilterLength+1:end,:)])';
Taps = conj(Taps([1,3,2,4],:));

% brickwall out of band components
% H = fft(Taps.');
% H(ceil(P.FilterLength/4):end-floor(P.FilterLength/4),:) = 0;
% Taps = ifft(H).';

P.Taps = Taps;
end

return
yhat = QAM_RDE_fast(Signal,setfield(P,'mu',0));
% yhat.Et = [zeros(2,P.FilterLength-1), (x.'*h).'];
extracted = yhat.Et(:,P.FilterLength+(1:2:2*P.PilotSeqLen-1));
figure,plot(extracted.','.')
