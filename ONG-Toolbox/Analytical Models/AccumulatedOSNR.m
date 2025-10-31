function OSNR = AccumulatedOSNR(P, Spans)
% Calculates the expected OSNR as a function of the fibre span launch Power
% and the number of spans traversed
%
% Source: IVAN P. KAMINOW and TINGYE LI, "OPTICAL FIBER TELECOMMUNICATIONS IV-B
% SYSTEMS AND IMPAIRMENTS", pg 203.
% 
% PdB               - Power lauched into fibre span (dBm)
% P.SpanLossdB      - span loss (dB)
% P.OXCLossdB       - OXC loss (dB)
% P.NFdB            - amplifier noise figure (dB)
% P.GaindB          - amplifier gain (dB)
%
% Spans - number of spans tranversed
% 
% Author:

if isfield(P,'OXCLossdB')
    NFeq = P.NFdB+10*log10(1+10^((P.OXCLossdB-P.GaindB)/10));
else
    NFeq = P.NFdB;
end

OSNR = 58+P.PdB-P.SpanLossdB-NFeq-10*log10(Spans);
end