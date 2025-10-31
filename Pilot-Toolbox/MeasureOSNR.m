function OSNR = MeasureOSNR(P)
if isfield(P,'OSNR') && P.OSNR~=0
    OSNR = P.OSNR;
elseif P.ReadfromFile==0 && P.ReadfromScope==1
    OSNR = getfield( YokogawaOSA('Dual'), 'OSNR');
    YokogawaOSA('Repeat');
else
    OSNR = 0;
end
end
