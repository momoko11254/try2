function Signal = ADC(Signal,P)
% Implements an analogue to digital converter
%
% Signal=Attenuator(Signal,P)
%
% Inputs:
% Signal        - input signal structure
% P.Res         - Resolution (bits)
% P.Vmin        - Quantisation range (V)
% P.Vmax        - (V)
% 
% Returns:
% Signal        - output signal structure
%
% Author: Benn Thomsen, January 2006.

partition = linspace(P.Vmin,P.Vmax,2^P.Res-1);  % Create Vector of quantization intervals
codebook = (-2^(P.Res-1):2^(P.Res-1)-1)./(2^(P.Res-1)-1); % Create Vector of quantised outputs
[~,Nt]=size(Signal);
index = zeros(1, Nt);
for i = 1 : length(partition)
    index = index + (Signal > partition(i));
end

Signal = codebook(index+1);
end
% partition = linspace(P.Vmin,P.Vmax,2^P.Res-1);  % Create Vector of quantization intervals
% codebook = (-2^(P.Res-1):2^(P.Res-1)-1)./(2^(P.Res-1)-1); % Create Vector of quantised outputs
% [~,Nt]=size(Signal.Et);
% index = zeros(1, Nt);
% for i = 1 : length(partition)
%     index = index + (Signal.Et > partition(i));
% end
% 
% Signal.Et = codebook(index+1);
% end