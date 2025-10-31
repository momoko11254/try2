function Compile(varargin)
% Function used to compile all mex-function located in the current
% directory using the predefined options files.
% 
% Author: Milen Paskov, December 2013
% Option files authors: Domanic Lavery, Milen Paskov

%% Get Files
if nargin>0
    list.name = char(varargin);
    N_files = 1;
else
    list = dir('*.cpp');
    N_files = length(list);
end

%% Compile
for index=1:N_files
    filename = list(index).name;
    
    fprintf(['Compiling file: ' filename '\n'])
    
    if(strcmp(computer,'PCWIN64'))
        % Windows
        mex(filename)
    elseif(strcmp(computer,'GLNXA64'))
        % Linux
        fprintf('GCC compiler...\n')
        mex(filename,'-f','mexopts_o3.sh'); % use the gcc compiler
    elseif(strcmp(computer,'MACI64'))
        % Mac
        fprintf('Clang compiler...\n')
        mex(filename,'-f','mex_C++_maci64.xml'); % use the gcc compiler
    else
        mex(filename); % just try and compile the file!
    end
    fprintf('Compile complete\n')
end
end