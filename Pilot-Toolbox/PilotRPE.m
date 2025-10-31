function Signal = PilotRPE(Signal,P)

% if strcmp(P.ModFormatData,'shaped1024QAM')
%     M = 1024;
% %     [~,~,CP] = QAM_Generator(P);
% %     Const = CP.Conste;
% elseif strcmp(P.ModFormatData,'QPSK')
%     M = 4;
% %     Const = qammod(0:M-1,M,'bin','UnitAveragePower',true);
% elseif strcmp(P.ModFormatData(end-2:end),'QAM')
%     M = str2double(P.ModFormatData(1:end-3));
% %     Const = qammod(0:M-1,M,'bin','UnitAveragePower',true);
% end

Const = P.Conste;

Payload = Signal.Et(:,P.PilotSeqLen+1:end);

CPEblocks = reshape(Payload.',P.PilotRat,[]);
CPEblocks(P.PilotRat,:) = []; % remove pilots

% HD = Const(1+qamdemod(CPEblocks,M,'bin','UnitAveragePower',true));
HD = Const(1+genqamdemod(CPEblocks, P.Conste));

RPN = conj(CPEblocks).*HD;

% RPN = RPN./abs(RPN); % comment out to give more power to higher power
% symbols

RPN = movmean(RPN,P.RPElength,'EndPoints',1);
RPN = RPN./abs(RPN);

RPN = [RPN;ones(1,size(RPN,2))];

RPN = reshape(RPN,[],2).';

Signal.Et(:,P.PilotSeqLen+1:end) = Signal.Et(:,P.PilotSeqLen+1:end).*mean(RPN);