function [SpanCfg, TotalSpanLength, UseSpanModel] = ResolveSpanConfiguration(P)
SpanCfg = struct('Fiber', {}, 'Amplifier', {}, 'HasAmplifier', {});
TotalSpanLength = 0;
UseSpanModel = false;

hasSpanList = isfield(P, 'LinkSpans') && ~isempty(P.LinkSpans);
hasSpanOverrides = isfield(P, 'Span') && ~isempty(P.Span);
multiSpan = isfield(P, 'NSpans') && ~isempty(P.NSpans) && P.NSpans>1;
hasAmplifier = (isfield(P, 'Amplifier') && ~isempty(P.Amplifier)) || ...
    (isfield(P, 'EDFA') && ~isempty(P.EDFA)) || ...
    (isfield(P, 'EDFAParams') && ~isempty(P.EDFAParams));

if ~(hasSpanList || hasSpanOverrides || multiSpan || hasAmplifier)
    return;
end

fiberFields = {'Length','dz','Att','D','S','PMD','Gamma','RefWavelength','GPU','SinglePrecision','verbose'};
baseFiber = BuildBaseFiber(P, fiberFields);

if isempty(fieldnames(baseFiber)) || ~isfield(baseFiber, 'Length') || isempty(baseFiber.Length)
    return;
end

if hasSpanList
    rawSpans = P.LinkSpans;
    if iscell(rawSpans)
        rawSpans = [rawSpans{:}];
    end
else
    rawSpans = struct([]);
end

if isempty(rawSpans)
    numSpans = max(GetFieldWithDefault(P, 'NSpans', 1), 1);
    rawSpans = repmat(struct(), 1, numSpans);
    if hasSpanOverrides
        spanOverrides = P.Span;
        if iscell(spanOverrides)
            spanOverrides = [spanOverrides{:}];
        end
        for idx = 1:min(numel(spanOverrides), numSpans)
            rawSpans(idx) = spanOverrides(idx);
        end
    end
else
    numSpans = numel(rawSpans);
end

ampDefaults = ExpandAmplifierDefaults(P, numSpans);
SpanCfg = repmat(struct('Fiber', baseFiber, 'Amplifier', [], 'HasAmplifier', false), 1, numSpans);

for idx = 1:numSpans
    SpanCfg(idx).Fiber = MergeFiber(baseFiber, rawSpans(idx), fiberFields);
    SpanCfg(idx).Amplifier = MergeAmplifier(ampDefaults, idx, rawSpans(idx));
    SpanCfg(idx).HasAmplifier = IsAmplifierDefined(SpanCfg(idx).Amplifier);
    TotalSpanLength = TotalSpanLength + GetFieldWithDefault(SpanCfg(idx).Fiber, 'Length', 0);
end

UseSpanModel = true;
end
