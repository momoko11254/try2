function BER = TheoreticalBER(P)
% Theoretical limits of bit-error-probability for several modulation formats in the presence of additive
% white gaussian noise (AWGN channels)
%
% Sources: Proakis & Salehi "Digital Communications" 5th Edition,
%          McGraw-Hill (2008) Chapter 4
%          E. Ip and J.M. Kahn "Carrier Synchronization for 3- and 4-bit-per-Symbol
%          Optical Transmission", JLT, vol. 23, 12, 2005
%          E. Ip and J.M. Kahn "Feedforward Carrier Recovery for Coherent Optical
%          Communications", JLT, vol. 25, 9, 2007
% 
% Inputs:
% P.ModFormat - 'BPSK', 'QPSK', '8PSK', '16PSK', '8QAM', '16QAM', '32QAM' or other square QAM
% P.M - number of constellation points
% P.OSNRdB OR
% P.SNRperBitdB - signal to noise ratios [dB]
% P.Bref - noise reference bandwidth [Hz] e.g. 12.5e9 -> 0.1nm
% P.DataRate - overall bitrate [bit/s] OR
% P.Fb - Symbol Rate [Baud]
% P.differential - differential encoding? ('0' or '1')%
%
% Author: C Behrens
% Modified: Many, many times!

% P.ModFormat='BPSK';
% P.AntiPodal = false;
% P.M=2;
%P.OSNRdB=10:0.25:20;
% P.SNRperBitdB=0:0.1:15;%13;
% P.Bref=12.5e9;
% P.DataRate=28*2*log2(P.M)*1e9; % bit rate both pols
% P.differential=0;

%% Default Parameters
if ~isfield(P, 'differential')
    P.differential = 0;
end
if ~isfield(P, 'Bref')
    P.Bref = 12.5e9;
end

if ~isfield(P, 'DataRate')
    P.DataRate = 2*log2(P.M)*P.Fb; % Symbol rate x two polarisations x bits/symbol
end

if isfield(P,'OSNRdB')
    %% BER VS OSNR
    OSNR=10.^(P.OSNRdB./10);
    SNRperBit=2*P.Bref/P.DataRate*OSNR;
elseif isfield(P,'SNRperBitdB')
    %% BER VS SNRperBit
    SNRperBit=10.^(P.SNRperBitdB./10);
end

% Q=@(x)(1/2)*erfc(x/sqrt(2)); % Q-function: pg 44, eq 2.3-18

if strcmp(P.ModFormat(end-2:end),'PSK')
    if P.differential
        % differential coding
        [BER,SER] = berawgn(10*log10(SNRperBit),'psk',P.M,'diff');
    else
        % gray coding
        [BER,SER] = berawgn(10*log10(SNRperBit),'psk',P.M,'nodiff');
    end
elseif strcmp(P.ModFormat(end-2:end),'QAM')
    [BER,SER] = berawgn(10*log10(SNRperBit),'qam',P.M);
elseif strcmp(P.ModFormat(end-2:end),'PAM')
    [BER,SER] = berawgn(10*log10(SNRperBit),'pam',P.M);
else
    switch P.ModFormat
        case {'PSQPSK'}
            for ind = 1:length(SNRperBit)
                SER(ind) = 0.5*erfc(sqrt(3*SNRperBit(ind))) + (1/sqrt(pi)).*quadgk(@(x)(erfc(x).*(3-3.*erfc(x)+(erfc(x).^2)).*exp(-(x-sqrt(3*SNRperBit(ind))).^2)),0,inf);
            end
            for ind=1:length(SNRperBit)
                BER(ind) = 1/(2*sqrt(pi))*quadgk(@(x)((erfc(x).*(3-3.*erfc(x)+(erfc(x).^2)).*exp(-(x-sqrt(3*SNRperBit(ind))).^2))),-inf,inf);
            end
            BER=SER/2;
            if P.differential
                % differential coding
                BER=2*BER;  % ???
            end
    end
end

if 1==0
    if isfield(P,'OSNRdB')
        %% BER VS OSNR
        figure(1)
        semilogy(P.OSNRdB,BER,'sb')
        grid on
        xlabel(strcat('OSNR_{',num2str(P.Bref),'GHz} [dB]'))
        ylabel('BER')
        
    elseif isfield(P,'SNRperBitdB')
        hold on;%figure(1)
        %% BER VS SNRperBit
        semilogy(P.SNRperBitdB,BER,'sg')
        grid on
        xlabel(strcat('SNR per Bit [dB]'))
        ylabel('BER')
        xlim([0 15])
        ylim([1e-12 2e-2])
    end
end

    function BER = TheoreticalBERQAM8(P)
        % see "Carrier Synchronization for 3- and 4-bit-per-Symbol
        % Optical-Transmission", E.Ip and J.M. Kahn, JLT 2005
        
        SNRperSymbol=log2(8)*P.SNRperBit;
        
        %% Energy per Symbol
        A=1;
        % Eavg=2*A^2;  % M-(D)PSK
        Eavg=4.73*A^2;  % nonrectangular 8-QAM
        
        %% ideal constellation
        symbol=A.*[1+1i 1-1i -1+1i -1-1i -1-sqrt(3) 1+sqrt(3) 1i*(1+sqrt(3)) -1i*(1+sqrt(3))];  % nonrectangular 8-QAM
        % symbol=A.*[1+j 1-j -1+j -1-j];  % (D)QPSK
        
        %% constructing grid
        N=1000;  % NxN points
        gamma=4; % -gamma*A...gammaA
        deltaRe=2*gamma*A/(N-1); % stepsize real axis
        deltaIm=deltaRe; % stepsize imaginary axis
        
        grid=zeros(1,N^2);
        count=1;
        for Re=-gamma*A:deltaRe:gamma*A
            for Im=-gamma*A:deltaIm:gamma*A
                grid(count)=Re+1i*Im;
                count=count+1;
            end
        end
        
        SERnest = ones(1,length(SNRperSymbol));
        for h=1:length(SNRperSymbol)
            N_0=Eavg/(2*SNRperSymbol(h));  % noise spectral density
            
            %     %% alpha ... Carrier to Noise ratio
            %     P_c=1e-3;
            %     B_L=12.5e9;
            %     alpha=2*P_c/(N_0*B_L);
            %     alpha=1e4;
            
            %% calculating error probability assuming maximum likelihood detection
            B=zeros(N^2,P.M);
            for m=1:P.M;
                for n=1:N^2
                    %% AWGN only
                    B(n,m)=1/(2*pi*N_0)*exp(-1/(2*N_0)*(abs(grid(n)-symbol(m))^2));
                    
                    %% AWGN + phase noise
                    %         beta=sqrt(abs(grid(n))^2*abs(symbol(m))^2+2*alpha*N_0*conj(grid(n))*symbol(m)+(alpha*N_0)^2);
                    %         A(n,m)=1/(2*pi*N_0)*besseli(0,beta/N_0)/besseli(0,alpha)*exp(-1/(2*N_0)*(abs(grid(n)-symbol(m))^2+2*conj(z(n))*symbol(m)));
                    %         if (beta/N_0)>3
                    %             A(n,m)=1/(2*pi*N_0)*sqrt(alpha*N_0/beta)*exp(-1/(2*N_0)*(abs(grid(n)-symbol(m))^2+2*conj(grid(n))*symbol(m)+2*alpha*N_0-2*beta));
                    %         else
                    %             A(n,m)=1/(2*pi*N_0)*sqrt(alpha)/0.4*besseli(0,beta/N_0)*exp(-1/(2*N_0)*(abs(grid(n)-symbol(m))^2+2*conj(grid(n))*symbol(m)+2*alpha*N_0));
                    %         end
                end
            end
            SERnest(h)=1-1/P.M*deltaRe*deltaRe*sum(max(B,[],2));
        end
        if P.differential
            BER=2/3*SERnest; % nonrectangular 8-DQAM
        else
            BER=11/24*SERnest; % nonrectangular 8-QAM
        end
    end
end

%%
%        elseif strcmp('PAM',P.ModFormat(end-2:end))
%            if P.AntiPodal
%                x = sqrt(6*log2(P.M)*SNRperBit/(P.M^2-1));
%            else
%               % Half the minimum distance for PAM >= 0 (e.g. OOK)
%                x = sqrt(3*log2(P.M)*SNRperBit/(P.M^2-1));
%            end
%            SER = 2*(1-1/P.M)*Q(x);
%
% gray coding
% BER=1/log2(P.M)*SER;