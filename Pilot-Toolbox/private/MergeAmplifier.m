function amplifier = MergeAmplifier(defaults, idx, spanEntry)
amplifier = [];
if ~isempty(defaults)
    amplifier = defaults(min(idx, numel(defaults)));
end
override = struct();
if ~isempty(spanEntry)
    if isfield(spanEntry, 'Amplifier') && ~isempty(spanEntry.Amplifier)
        override = spanEntry.Amplifier;
    elseif isfield(spanEntry, 'Amp') && ~isempty(spanEntry.Amp)
        override = spanEntry.Amp;
    elseif isfield(spanEntry, 'EDFA') && ~isempty(spanEntry.EDFA)
        override = spanEntry.EDFA;
    end
end
if iscell(override)
    override = [override{:}];
end
if ~isempty(override)
    if numel(override) > 1
        override = override(1);
    end
    if isempty(amplifier)
        amplifier = override;
    else
        fn = fieldnames(override);
        for k = 1:numel(fn)
            amplifier.(fn{k}) = override.(fn{k});
        end
    end
end
if ~IsAmplifierDefined(amplifier)
    amplifier = [];
end
end
