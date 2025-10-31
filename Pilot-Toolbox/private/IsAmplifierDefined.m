function tf = IsAmplifierDefined(amplifier)
tf = false;
if isempty(amplifier)
    return;
end
if ~isstruct(amplifier)
    return;
end
tf = ~isempty(fieldnames(amplifier));
end
