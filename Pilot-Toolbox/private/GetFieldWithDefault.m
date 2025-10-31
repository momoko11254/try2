function value = GetFieldWithDefault(S, fieldName, defaultValue)
if nargin < 3
    defaultValue = [];
end
if isstruct(S) && isfield(S, fieldName)
    value = S.(fieldName);
else
    value = defaultValue;
end
end
