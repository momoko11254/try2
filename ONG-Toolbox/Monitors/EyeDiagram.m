function EyeDiagram(varargin)
% Plots the eye diagram
% Converts the temporal pulse electrical signal into a sampled eyediagram.
%
% figure(n),EyeDiagram(varargin)
%
% varargin - signal structure(s) to be displayed
% followed by optional structure to control display options, containing some or all of
%          .Delay - (ps)
%          .Bits - fraction of bits to plot
%          .Width - number of eyes to show
% If multiple signals are input the display options can be
% vectors with an element for each signal otherwise the same value is used
% for each signal
%
% Author: Benn Thomsen, May 2005.
% Modified: Benn Thomsen, January 2006.


if ~isfield(varargin{nargin},'Et'),
    Nsig=nargin-1;
    P=varargin{nargin};
    if isfield(P,'Delay'),
        delay=P.Delay;
        delay=delay(:).*ones(Nsig,1);
    else delay=zeros(Nsig,1);
    end
    if isfield(P,'Bits'),
        bits=P.Bits;
        bits=bits(:).*ones(Nsig,1);
    else bits=ones(Nsig,1);
    end
    if isfield(P,'Width'),
        width=P.Width;
        width=width(:).*ones(Nsig,1);
    else width=ones(Nsig,1);
    end
else
    Nsig=nargin;
    delay=zeros(Nsig,1);
    bits=ones(Nsig,1);
    width=ones(Nsig,1);
end



for n=1:Nsig,
    Signal=varargin{n};
    [Np,Nt]=size(Signal.Et);
    Ns=round(Signal.Fs/Signal.Fb);
    Nb=Nt/Ns;
    dT=1e12/Signal.Fs;
    TT=[0:width(n)*Ns-1]*dT+delay(n);
    Nd=rem(round(abs(delay(n))/dT),Ns)+1;
    np=max([width(n) width(n)*floor(bits(n)/width(n)*Nb)-width(n)])*Ns;
    if strcmp(Signal.Type,'Optical')
        It=sum(abs(Signal.Et(:,Nd:np+Nd-1)).^2,1);
    else
        It=Signal.Et(:,Nd:np+Nd-1);
    end
    
    Eye=reshape(It,width(n)*Ns,np/Ns/width(n));
    h(n)=subplot(Nsig,1,n);
    plot(TT,Eye);
    set(get(h(n),'title'),'string',inputname(n));
    xlim([TT(1) TT(end)])
    ylabel('Intensity')
end
xlabel('Time (ps)')
end