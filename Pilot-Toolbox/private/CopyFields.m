function fieldsStruct = CopyFields(source, fieldList)
fieldsStruct = struct();
if isempty(source)
    return;
end
for k = 1:numel(fieldList)
    fname = fieldList{k};
    if isfield(source, fname)
        fieldsStruct.(fname) = source.(fname);
    end
end
end
