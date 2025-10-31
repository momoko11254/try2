function str = GreekChars(letter)
% Unicode map for greek special characters
%
% str = GreekChars(letter)
%
% Input:
% letter - a string identifier e.g. 'alpha'
% 
% Output:
% str - a string representation of the special character
%
% Domanic Lavery, June 2014


switch letter
    case 'Alpha'
        str=char(hex2dec('0391')) 	 	; % Greek Capital Letter Alpha
    case 'Beta'
        str=char(hex2dec('0392')) 	 	; % Greek Capital Letter Beta
    case 'Gamma'
        str=char(hex2dec('0393')) 	 	; % Greek Capital Letter Gamma
    case 'Delta'
        str=char(hex2dec('0394')) 	 	; % Greek Capital Letter Delta
    case 'Epsilon'
        str=char(hex2dec('0395')) 	 	; % Greek Capital Letter Epsilon
    case 'Zeta'
        str=char(hex2dec('0396')) 	 	; % Greek Capital Letter Zeta
    case 'Eta'
        str=char(hex2dec('0397')) 	 	; % Greek Capital Letter Eta
    case 'Theta'
        str=char(hex2dec('0398')) 	 	; % Greek Capital Letter Theta
    case 'Iota'
        str=char(hex2dec('0399')) 	 	; % Greek Capital Letter Iota
    case 'Kappa'
        str=char(hex2dec('039A')) 	 	; % Greek Capital Letter Kappa
    case 'Lambda'
        str=char(hex2dec('039B')) 	 	; % Greek Capital Letter Lambda
    case 'Mu'
        str=char(hex2dec('039C')) 	 	; % Greek Capital Letter Mu
    case 'Nu'
        str=char(hex2dec('039D')) 	 	; % Greek Capital Letter Nu
    case 'Xi'
        str=char(hex2dec('039E')) 	 	; % Greek Capital Letter Xi
    case 'Omicron'
        str=char(hex2dec('039F')) 	 	; % Greek Capital Letter Omicron
    case 'Pi'
        str=char(hex2dec('03A0')) 	 	; % Greek Capital Letter Pi
    case 'Rho'
        str=char(hex2dec('03A1')) 	 	; % Greek Capital Letter Rho
    case 'Sigma'
        str=char(hex2dec('03A3')) 	 	; % Greek Capital Letter Sigma
    case 'Tau'
        str=char(hex2dec('03A4')) 	 	; % Greek Capital Letter Tau
    case 'Upsilon'
        str=char(hex2dec('03A5')) 	 	; % Greek Capital Letter Upsilon
    case 'Phi'
        str=char(hex2dec('03A6')) 	 	; % Greek Capital Letter Phi
    case 'Chi'
        str=char(hex2dec('03A7')) 	 	; % Greek Capital Letter Chi
    case 'Psi'
        str=char(hex2dec('03A8')) 	 	; % Greek Capital Letter Psi
    case 'Omega'
        str=char(hex2dec('03A9')) 	 	; % Greek Capital Letter Omega
        %         case 'IotaD'
        %         str=char(hex2dec('03AA')) 	 	; % Greek Capital Letter Iota with diaeresis
        %         case 'UpsilonD'
        %         str=char(hex2dec('03AB')) 	 	; % Greek Capital Letter Upsilon with diaeresis
        %         str=char(hex2dec('03AC')) 	 	; % Greek Small Letter Alpha with acute accent
        %         str=char(hex2dec('03AD')) 	 	; % Greek Small Letter Epsilon with acute accent
        %         str=char(hex2dec('03AE')) 	 	; % Greek Small Letter Eta with acute accent
        %         str=char(hex2dec('03AF')) 	 	; % Greek Small Letter Iota with acute accent
        %         str=char(hex2dec('03B0')) 	 	; % Greek Small Letter Upsilon with diaeresis and acute accent
    case 'alpha'
        str=char(hex2dec('03B1')) 	 	; % Greek Small Letter Alpha
    case 'beta'
        str=char(hex2dec('03B2')) 	 	; % Greek Small Letter Beta
    case 'gamma'
        str=char(hex2dec('03B3')) 	 	; % Greek Small Letter Gamma
    case 'delta'
        str=char(hex2dec('03B4')) 	 	; % Greek Small Letter Delta
    case 'epsilon'
        str=char(hex2dec('03B5')) 	 	; % Greek Small Letter Epsilon
    case 'zeta'
        str=char(hex2dec('03B6')) 	 	; % Greek Small Letter Zeta
    case 'eta'
        str=char(hex2dec('03B7')) 	 	; % Greek Small Letter Eta
    case 'theta'
        str=char(hex2dec('03B8')) 	 	; % Greek Small Letter Theta
    case 'iota'
        str=char(hex2dec('03B9')) 	 	; % Greek Small Letter Iota
    case 'kappa'
        str=char(hex2dec('03BA')) 	 	; % Greek Small Letter Kappa
    case 'lambda'
        str=char(hex2dec('03BB')) 	 	; % Greek Small Letter Lambda
    case 'mu'
        str=char(hex2dec('03BC')) 	 	; % Greek Small Letter Mu
    case 'nu'
        str=char(hex2dec('03BD')) 	 	; % Greek Small Letter Nu
    case 'xi'
        str=char(hex2dec('03BE')) 	 	; % Greek Small Letter Xi
    case 'omicron'
        str=char(hex2dec('03BF')) 	 	; % Greek Small Letter Omicron
    case 'pi'
        str=char(hex2dec('03C0')) 	 	; % Greek Small Letter Pi
    case 'rho'
        str=char(hex2dec('03C1')) 	 	; % Greek Small Letter Rho
    case 'sigma_'
        str=char(hex2dec('03C2')) 	 	; % Greek Small Letter Final Sigma
    case 'sigma'
        str=char(hex2dec('03C3')) 	 	; % Greek Small Letter Sigma
    case 'tau'
        str=char(hex2dec('03C4')) 	 	; % Greek Small Letter Tau
    case 'upsilon'
        str=char(hex2dec('03C5')) 	 	; % Greek Small Letter Upsilon
    case 'phi'
        str=char(hex2dec('03C6')) 	 	; % Greek Small Letter Phi
    case 'chi'
        str=char(hex2dec('03C7')) 	 	; % Greek Small Letter Chi
    case 'psi'
        str=char(hex2dec('03C8')) 	 	; % Greek Small Letter Psi
    case 'omega'
        str=char(hex2dec('03C9')) 	 	; % Greek Small Letter Omega
        %         case 'iotaD'
        %         str=char(hex2dec('03CA')) 	 	; % Greek Small Letter Iota with diaeresis
        %         str=char(hex2dec('03CB')) 	 	; % Greek Small Letter Upsilon with diaeresis
        %         str=char(hex2dec('03CC')) 	 	; % Greek Small Letter Omicron with acute accent
        %         str=char(hex2dec('03CD')) 	 	; % Greek Small Letter Upsilon with acute accent
        %         str=char(hex2dec('03CE')) 	 	; % Greek Small Letter Omega with acute accent
        %         str=char(hex2dec('03D0')) 	 	; % Greek Beta Symbol
        %         str=char(hex2dec('03D1')) 	 	; % Greek Theta Symbol
        %         str=char(hex2dec('03D2')) 	 	; % Greek Upsilon with hook Symbol
        %         str=char(hex2dec('03D3')) 	 	; % Greek Upsilon with acute and hook Symbol
        %         str=char(hex2dec('03D4')) 	 	; % Greek Upsilon with diaeresis and hook Symbol
    case 'PhiS'
        str=char(hex2dec('03D5')) 	 	; % Greek Phi Symbol
    case 'PiS'
        str=char(hex2dec('03D6')) 	 	; % Greek Pi Symbol
    otherwise
        %         str=char(hex2dec('03D7')) 	 	; % Greek Kai Symbol
        %         str=char(hex2dec('03D8')) 	 	; % Greek Letter Qoppa
        %         str=char(hex2dec('03D9')) 	 	; % Greek Small Letter Qoppa
        %         str=char(hex2dec('03DA')) 	 	; % Greek Letter Stigma (letter))
        %         str=char(hex2dec('03DB')) 	 	; % Greek Small Letter Stigma
        %         str=char(hex2dec('03DC')) 	 	; % Greek Letter Digamma
        %         str=char(hex2dec('03DD')) 	 	; % Greek Small Letter Digamma
        %         str=char(hex2dec('03DE')) 	 	; % Greek Letter Koppa
        %         str=char(hex2dec('03DF')) 	 	; % Greek Small Letter Koppa
        %         str=char(hex2dec('03E0')) 	 	; % Greek Letter Sampi
        %         str=char(hex2dec('03E1')) 	 	; % Greek Small Letter Sampi
        %         str=char(hex2dec('03E2')) 	 	; % Coptic Capital Letter Shei
        %         str=char(hex2dec('03E3')) 	 	; % Coptic Small Letter Shei
        %         str=char(hex2dec('03E4')) 	 	; % Coptic Capital Letter Fei
        %         str=char(hex2dec('03E5')) 	 	; % Coptic Small Letter Fei
        %         str=char(hex2dec('03E6')) 	 	; % Coptic Capital Letter Khei
        %         str=char(hex2dec('03E7')) 	 	; % Coptic Small Letter Khei
        %         str=char(hex2dec('03E8')) 	 	; % Coptic Capital Letter Hori
        %         str=char(hex2dec('03E9')) 	 	; % Coptic Small Letter Hori
        %         str=char(hex2dec('03EA')) 	 	; % Coptic Capital Letter Gangia
        %         str=char(hex2dec('03EB')) 	 	; % Coptic Small Letter Gangia
        %         str=char(hex2dec('03EC')) 	 	; % Coptic Capital Letter Shima
        %         str=char(hex2dec('03ED')) 	 	; % Coptic Small Letter Shima
        %         str=char(hex2dec('03EE')) 	 	; % Coptic Capital Letter Dei
        %         str=char(hex2dec('03EF')) 	 	; % Coptic Small Letter Dei
        %         str=char(hex2dec('03F0')) 	 	; % Greek Kappa Symbol
        %         str=char(hex2dec('03F1')) 	 	; % Greek Rho Symbol
        %         str=char(hex2dec('03F2')) 	 	; % Greek Lunate Sigma Symbol
        %         str=char(hex2dec('03F3')) 	 	; % Greek Letter Yot
        %         str=char(hex2dec('03F4')) 	 	; % Greek Capital Theta Symbol
        %         str=char(hex2dec('03F5')) 	 	; % Greek Lunate Epsilon Symbol
        %         str=char(hex2dec('03F6')) 	 	; % Greek Reversed Lunate Epsilon Symbol
        %         str=char(hex2dec('03F7')) 	 	; % Greek Capital Sho
        %         str=char(hex2dec('03F8')) 	 	; % Greek Small Letter Sho
        %         str=char(hex2dec('03F9')) 	 	; % Greek Capital Lunate Sigma Symbol
        %         str=char(hex2dec('03FA')) 	 	; % Greek Capital San
        %         str=char(hex2dec('03FB')) 	 	; % Greek Small Letter San
        %         str=char(hex2dec('03FC')) 	 	; % Greek Rho with stroke Symbol
        %         str=char(hex2dec('03FD')) 	 	; % Greek Capital Reversed Lunate Sigma Symbol
        %         str=char(hex2dec('03FE')) 	 	; % Greek Capital Dotted Lunate Sigma Symbol
        %         str=char(hex2dec('03FF')) 	 	; % Greek Capital Reversed Dotted Lunate Sigma Symbol
        str = '';
end
end