function [SignalOut, P] = PropagateLinkWithAmplifiers(SignalIn, P, SpanCfg, TotalSpanLength)
SignalOut = SignalIn;
spanLengths = zeros(1, numel(SpanCfg));

for idx = 1:numel(SpanCfg)
    fiberParams = SpanCfg(idx).Fiber;
    if ~isfield(fiberParams, 'dz') || isempty(fiberParams.dz)
        fiberLen = GetFieldWithDefault(fiberParams, 'Length', []);
        if ~isempty(fiberLen)
            fiberParams.dz = fiberLen/1000;
        end
    end

    SignalOut = Manakov(SignalOut, fiberParams);
    spanLengths(idx) = GetFieldWithDefault(fiberParams, 'Length', 0);

    if SpanCfg(idx).HasAmplifier
        SignalOut = EDFA(SignalOut, SpanCfg(idx).Amplifier);
    end
end

computedTotal = sum(spanLengths);
if computedTotal > 0
    TotalSpanLength = computedTotal;
end

P.totalFibreSpan = TotalSpanLength;
P.Length = TotalSpanLength;
P.NSpansSimulated = numel(SpanCfg);
P.AppliedLinkSpans = SpanCfg;
P.SimulatedSpanLengths = spanLengths;
end
