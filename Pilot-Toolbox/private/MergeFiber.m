function newFiber = MergeFiber(baseFiber, override, fiberFields)
newFiber = baseFiber;
if isempty(override)
    return;
end
if iscell(override)
    override = [override{:}];
end
if isfield(override, 'Fiber')
    override = override.Fiber;
elseif isfield(override, 'Fibre')
    override = override.Fibre;
end
if isempty(override)
    return;
end
for k = 1:numel(fiberFields)
    fname = fiberFields{k};
    if isfield(override, fname)
        newFiber.(fname) = override.(fname);
    end
end
if isfield(override, 'SpanLength') && (~isfield(newFiber, 'Length') || isempty(newFiber.Length))
    newFiber.Length = override.SpanLength;
elseif isfield(override, 'Length')
    newFiber.Length = override.Length;
end
end
