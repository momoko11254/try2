function [alignTxSignal,rotSignal,varargout] = alignSignalComplex(Signal,TxSignal,varargin)
TxData = TxSignal; %copy in
rotSignal = Signal;%copy in
[Np,Nb] = size(Signal.Et);
if size(TxData,1)<Np
    TxData(2,:) = TxData(1,:);
end
Nprbs = size(TxData,2);
nSequence = floor(Nb/Nprbs);
if nargin<=2
    alignTxSignal = zeros(size(Signal.Et));
else
    alignTxSignal = zeros(Np,Nb/2);
end
XYDelay = zeros(1,Np);
figure;
hold on;
for i = 1:Np
    [crossCorrelationCC,lagCC] = xcorr(TxData(i,:),Signal.Et(i,1:Nprbs));
    plot(lagCC,abs(crossCorrelationCC));
    [crossCorrelationCCconj,lagCCconj] = xcorr(TxData(i,:),conj(Signal.Et(i,1:Nprbs)));
    plot(lagCCconj,abs(crossCorrelationCCconj));
    
    if max(abs(crossCorrelationCC))>max(abs(crossCorrelationCCconj))
        varargout{1}(i,:) =  crossCorrelationCC;
        [~,ind] =  max(abs(crossCorrelationCC));
        rot(i) = pi/2*round(angle(crossCorrelationCC(ind))/pi*2);
        shift(i) = lagCC(ind);
        rotSignal.Et(i,:) = Signal.Et(i,1:Nprbs*nSequence)*exp(1j*rot(i));
    else
        varargout{1}(i,:) =  crossCorrelationCCconj;
        [~,ind] =  max(abs(crossCorrelationCCconj));
        rot(i) = pi/2*round(angle(crossCorrelationCCconj(ind))/pi*2);
        shift(i) = lagCCconj(ind);
        rotSignal.Et(i,:) = conj(Signal.Et(i,1:Nprbs*nSequence))*exp(1j*rot(i));
    end
    TxPatt = circshift(TxData(i,:),[0 -shift(i)]);
    alignTxSignal(i,:) = repmat(TxPatt,1,nSequence);
    fprintf('channel %d peak is located at %d\n',i,ind);
    XYDelay(i) = ind;
    varargout{2}(i) = ind;
end
if diff(XYDelay)<Nprbs/2
    fprintf('XY delay is:%d\n',diff(XYDelay));
    varargout{3} = diff(XYDelay);
else
    fprintf('XY delay is:%d\n',Nprbs-diff(XYDelay));
    varargout{3} = Nprbs-diff(XYDelay);
end
