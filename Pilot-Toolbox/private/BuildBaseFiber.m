function baseFiber = BuildBaseFiber(P, fiberFields)
baseFiber = CopyFields(P, fiberFields);
if isfield(P, 'SpanLength') && ~isempty(P.SpanLength)
    baseFiber.Length = P.SpanLength;
end
if (~isfield(baseFiber, 'Length') || isempty(baseFiber.Length)) && isfield(P, 'Length')
    baseFiber.Length = P.Length;
end
if isfield(P, 'totalFibreSpan') && isfield(P, 'NSpans') && ~isempty(P.NSpans) && P.NSpans>0
    spanLen = P.totalFibreSpan./P.NSpans;
    if ~isfield(baseFiber, 'Length') || isempty(baseFiber.Length)
        baseFiber.Length = spanLen;
    else
        targetTotal = baseFiber.Length.*P.NSpans;
        if abs(targetTotal - P.totalFibreSpan) > max(1e-9, 1e-6*P.totalFibreSpan)
            baseFiber.Length = spanLen;
        end
    end
end
end
