function Copy_List = collectDependantFiles(Source, Destination)
%Copy_List = collectDependantFiles(Source, Destination)
% This function will copy your files (Source) and all dependent functions to
% a directory (Destination). In built Matlab functions are not copied.
%
% Copy_List = collectForOutput('/Users/user/Documents/MATLAB/A_Matlab_File.m', '/Users/user/Desktop/SomeDirectory/')
%
% Inputs
% Source: Path to the Matlab script 
% Destination: Path to directory where the files will be copied.

%% Input parsing
if ~exist(Source, 'file')
    error('Input file does not exist');
end

% If Source is a directory throw an error
if isdir(Source)
    error('Source should be a file, not a directory')
end

%% Otherwise find all top-level dependencies for current file
Dep_List = depfun(Source, '-quiet', '-toponly');

% Determine which dependencies are matlab bundled functions/toolboxes
IN_matlab = strncmp(matlabroot, Dep_List, length(matlabroot));

% Remove them from the list
Dep_List = Dep_List(~IN_matlab);

% Check that the directory exists
if ~isdir(Destination)
    mkdir(Destination); 
end

% Loop through reduced dependency list recursively finding all other required files
Copy_List = [];
for  nn = 2:length(Dep_List)
    Copy_List = [Copy_List; collectDependantFiles(Dep_List{nn},Destination)];
end

copyfile(Source,Destination);

%% End of Function
return;


