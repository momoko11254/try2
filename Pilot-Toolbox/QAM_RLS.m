function [Signal,P] = QAM_RLS(Signal,Training,P)

% lambda = 1-P.mu;
lambda = 1; % for stationary process
% delta = sigma_u^2*mu^alpha
alpha = 0; % for input snr order of 10dB
delta = 1;

% get taps
tapcenter = floor(P.FilterLength/2+1/2);
if isfield(P,'Taps')
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Reusing Taps'), end
    % reuse taps from previous run
    H11 = P.Taps(1,:);    H12 = P.Taps(2,:);
    H21 = P.Taps(3,:);    H22 = P.Taps(4,:);
else
    if (isfield(P,'verbose'))&&(P.verbose>=2), disp('Initialise Taps'), end
    % initial AFIR tap weights, all zeros according to Haykin
    H11=zeros(1,P.FilterLength); H11(tapcenter)=0;
    H12=zeros(1,P.FilterLength); H12(tapcenter)=0;
    H21=zeros(1,P.FilterLength); H21(tapcenter)=0;
    H22=zeros(1,P.FilterLength); H22(tapcenter)=0;
end
% prepare signal
X = Signal.Et.';
Y = zeros(size(X));
for pol=1:2
    % desired signal
    d = Training.Et(pol,:);
    if pol==1
        w = [H11.';H12.'];
    else
        w = [H21.';H22.'];
    end
    % P is the inverse correlatation matrix can also be seen as covariance
    % matrix of estimate w normalised wrt noise variance
    PP = 1/delta*eye(2*P.FilterLength);
    for n = P.FilterLength+1:2:size(X,1)
        %transition
        Y(n-1,pol) = w'*reshape(X(n-P.FilterLength:n-1,:),[],1);
        %input for signal
        u = reshape(X(n-P.FilterLength+1:n,:),[],1);
        % intermediate quantity
        Pu = PP*u;
        % gain vector
        k = Pu/(lambda+u'*Pu);
        % output prediction
        yhat = w'*u;
        % apriori error
        e = d(n) - yhat;
        % tap weight update
        w = w + k*e';
        % correlation matrix update
        PP = 1/lambda*PP-1/lambda*(k*u'*PP);
        % write output
        Y(n,pol) =  yhat;
    end
    if pol==1
       H11 = w(1:P.FilterLength)';
       H12 = w(P.FilterLength+1:end)';
    else
       H21 = w(1:P.FilterLength)';
       H22 = w(P.FilterLength+1:end)';
    end
end
P.Taps = [H11;H12;H21;H22];
Signal.Et = Y.';