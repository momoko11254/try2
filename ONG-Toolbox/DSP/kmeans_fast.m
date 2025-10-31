function [SignalOut, varargout] = kmeans_fast(SignalIn, P)
% Performs mex-assisted k-means clustering
%
% SignalOut=kmeans_fast(SignalIn, P)
%
% Inputs:
% SignalIn              - optical input signal structure containing fields
% P.ModFormat           - input modulation format (sets expected means)
% 
% Optional Inputs:
% P.kmeans_iterations   - sets number if iterations (default = 3)
%
% Returns:
% SignalOut             - output signal structure
%
% Author: Domanic Lavery, 2011
% Modified: Milen Paskov, January 2016

SignalOut = SignalIn;

%% Initialisation (choose expected means)
% Threads
if ~isfield(P,'Threads')
    P.Threads = 1;
end

if(~isfield(P,'ModFormat'))
    disp('Need to specify modulation format for k-means clustering')
    return
end

switch P.ModFormat
    case 'BPSK'
        means = [1 -1];
    case 'QPSK'
        means = [1+1i; -1+1i; -1-1i; 1-1i];
    case '8PSK'
        means = [0.0000 + 1.0000i
            -0.7071 + 0.7071i
            -1.0000 + 0.0000i
            -0.7071 - 0.7071i
            -0.0000 - 1.0000i
            0.7071 - 0.7071i
            1.0000 - 0.0000i
            0.7071 + 0.7071i];
    case '16QAM'
        varX = -3:2:3;
        varY = 3:-2:-3;
        means = zeros(length(varX),length(varY));
        for i=1:length(varX)
            for n=1:length(varY)
                means(i,n) = varX(i)+1j*varY(n);
            end
        end
        means = means./sqrt(mean(mean(abs(means).^2)));
        means = means(:);
    case '64QAM'
        varX = -7:2:7;
        varY = 7:-2:-7;
        means = zeros(length(varX),length(varY));
        for i=1:length(varX)
            for n=1:length(varY)
                means(i,n) = varX(i)+1j*varY(n);
            end
        end
        means = means./sqrt(mean(mean(abs(means).^2)));
        means = means(:);
    case '256QAM'
        varX = (-15:2:15);
        varY = (15:-2:-15);
        means = zeros(length(varX),length(varY));
        for i=1:length(varX)
            for n=1:length(varY)
                means(i,n) = varX(i)+1j*varY(n);
            end
        end
        means = means./sqrt(mean(mean(abs(means).^2)));
        means = means(:);
    case 'PSQPSK'
        means = [0; 1+1i; 1-1i; -1+1i; -1-1i];
    case '8QAM'
        means = 1/2*sqrt(2)/sqrt(sqrt(3)+3)*exp(1i*[pi/4 3*pi/4 -pi/4 -3*pi/4]);
        means = [means 1/2*(1+sqrt(3))/sqrt(sqrt(3)+3)*exp(1i*[0 pi/2 pi 3/2*pi])];
        means = means';
    otherwise
        disp('unknown modulation format in P.ModFormat')
        return
end

means1 = means;  % expected means for first polarisation
means2 = means;  % expected means for second polarisation

exclude = 1e3;
% set number of iterations
iter = 3;
if(isfield(P,'kmeans_iterations'))
    iter = P.kmeans_iterations;
end

%% assignment stage
% N.B the interleave blocks simplify the interface with C++
[EtX,EtY,means1,means2]=interleave(1,SignalIn.Et(1,:),SignalIn.Et(2,:),means1.',means2.');
[r1_raw, r2_raw] = kmeans_mex(EtX,EtY,means1,means2,iter,P.Threads);
[means1,means2]=interleave(-1,means1,means2);

% Note for future versions: the following could be implemented in C++
r1 = reshape(r1_raw,length(r1_raw)/length(means1),length(means1))';
r2 = reshape(r2_raw,length(r2_raw)/length(means2),length(means2))';

%% plot clustered outputs
% if(1==1) % set (1==1) to plot clusters
if(isfield(P, 'verbose') && (P.verbose==1))
    xy = 1.5;
    
    figure(11);
    subplot(1,2,1); axis square; hold on; axis([-xy xy -xy xy]); grid on;
    cla;
    colours = [0 0 0];
    for index = 1:length(means1)
        colours = circshift(colours',1)';
        plot(r1(index,exclude:end-exclude).*SignalIn.Et(1,exclude:end-exclude),'markeredgecolor',colours,'marker','.','linestyle','none','markersize',2);
        colours(3) = colours(1)+0.25;
        if(sum(colours>1)>0.5), colours = [0 0 0]; end
    end
    
    subplot(1,2,2); axis square; hold on; axis([-xy xy -xy xy]); grid on;
    cla;
    colours = [0 0 0];
    for index = 1:length(means2)
        colours = circshift(colours',1)';
        plot(r2(index,exclude:end-exclude).*SignalIn.Et(2,exclude:end-exclude),'markeredgecolor',colours,'marker','.','linestyle','none','markersize',2);
        colours(2) = colours(1)+0.15;
        if(sum(colours>1)>0.5), colours = [0 0 0]; end
    end
    hold off
    drawnow;
end

%% Calculate EVM
if(1==1)
    Ref = mean(abs(means).^2); % Normalize to the mean of all contstallation points
    
    Perrors1 = zeros(length(means1),1);
    for index = 1:length(means1)
        Npoints = sum(r1(index,exclude:end-exclude));
        points = r1(index,exclude:end-exclude).*SignalIn.Et(1,exclude:end-exclude);
        
        Err_vec = r1(index,exclude:end-exclude).*abs(means1(index)-points).^2;
        Perrors1(index,:) = sqrt(sum(Err_vec)/(Npoints*Ref)); % abs(means1(index))^2 if normalizing to expected value
    end
    
    Perrors2 = zeros(length(means2),1);
    for index = 1:length(means2)
        Npoints = sum(r2(index,exclude:end-exclude));
        points = r2(index,exclude:end-exclude).*SignalIn.Et(2,exclude:end-exclude);
        
        Err_vec = r2(index,exclude:end-exclude).*abs(means2(index)-points).^2;
        Perrors2(index,:) = sqrt(sum(Err_vec)/(Npoints*Ref));
    end
    
    if(isfield(P, 'verbose') && (P.verbose==1))
        % disp(['EVM vector X = ' num2str(100*Perrors1')]);
        % disp(['EVM vector Y = ' num2str(100*Perrors2')]);
        disp(['EVM X = ' num2str(100*mean(Perrors1)) '%']);
        disp(['EVM Y = ' num2str(100*mean(Perrors2)) '%']);
    end
    P.EVMX = 100*mean(Perrors1);
    P.EVMY = 100*mean(Perrors2);
end

%%
SignalOut.Et(1,:) = zeros(1,length(SignalOut.Et(1,:)));
SignalOut.Et(2,:) = zeros(1,length(SignalOut.Et(2,:)));

for index = 1:length(means)
    SignalOut.Et(1,:) = r1(index,:)*means1(index)+SignalOut.Et(1,:);
    SignalOut.Et(2,:) = r2(index,:)*means2(index)+SignalOut.Et(2,:);
end
varargout{1} = P;
end