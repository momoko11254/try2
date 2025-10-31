function ampDefaults = ExpandAmplifierDefaults(P, numSpans)
ampDefaults = [];
if isfield(P, 'Amplifier') && ~isempty(P.Amplifier)
    base = P.Amplifier;
elseif isfield(P, 'EDFA') && ~isempty(P.EDFA)
    base = P.EDFA;
elseif isfield(P, 'EDFAParams') && ~isempty(P.EDFAParams)
    base = P.EDFAParams;
else
    base = [];
end
if isempty(base)
    return;
end
if iscell(base)
    base = [base{:}];
end
if numel(base) == 1
    ampDefaults = repmat(base, 1, numSpans);
else
    ampDefaults = repmat(base(1), 1, numSpans);
    for idx = 1:min(numel(base), numSpans)
        ampDefaults(idx) = base(idx);
    end
end
end
