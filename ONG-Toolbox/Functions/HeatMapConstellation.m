function [varargout] = HeatMapConstellation(Signal , varargin)
% HEATMAPCONSTELLATION displays a heat map of the constellation space
%   HEATMAPCONSTELLATION(Signal) Constellation heat map
%   HEATMAPCONSTELLATION(Signal, P) ignore symbols from start and end using:
%           P.SDiscard
%           P.EDiscard
%   HEATMAPCONSTELLATION(Signal, P, nbins) Select the number of bins for histogram [default 200]
%   HEATMAPCONSTELLATION(Signal, P, nbins, colormap) Take the colormap as a parameter [default 'jet']
%   [h] = HEATMAPCONSTELLATION(______) Output a handle to the generated figure
%
% Note that by default all colormaps will be altered to provide a white background. 
%   
%   Authors: Domanic Lavery, Lidia Galdino, Maskai Sato (2015)
%
%   See also HIST3, IMAGESC, COLORMAP.


%% Symbol discards
if nargin>1
    P = varargin{1};
    
    if ~isfield(P, 'SDiscard')
        P.SDiscard = 0;
    end
    
    if ~isfield(P, 'EDiscard')
        P.EDiscard = 0;
    end
        
else
    P.SDiscard = 0;
    P.EDiscard = 0;
end


%% Histogram bins
if nargin>2
    nbins_x = varargin{2};
else
    nbins_x = 200; % Default bin size
end


%% Color map
if nargin>3
    if ~isnumeric(varargin{3})
        C=colormap(varargin{3});
    else
        C = varargin{3};
    end
else
    C = colormap('jet'); % Default color map, also 'parula' and 'hot' look good
end

C(1,:)=1;           % Make background white

%% Histogram
nbins_y = nbins_x;  % Equal number of bins for I/Q
histdata=[real(Signal.Et(1,(1+P.SDiscard):end-P.EDiscard)).',imag(Signal.Et(1,(1+P.SDiscard):end-P.EDiscard)).'];
[N, ~] = hist3(histdata, [nbins_x,nbins_y]); % Get histogram of data

%% Plot 2D histogram as heat map
if nargout >=1
    varargout{1} = imagesc(N);               % Provide handle to figure           
else
    imagesc(N);
end

%% Format figure
axis square
colormap(C);                                 % Set color map
box off
set(gca,'xtick',[],'ytick',[])
set(gca,'ycolor',[1 1 1],'xcolor',[1 1 1])
end