function [data_path,diary_path] = create_waveforms_path(P,data_path)

fields.layer1               = {'year' 'confJournal' 'key_subject' 'extra_info1'};
fields.layer1_mandatory     = {1      1              1             0          };

fields.layer2               = {'ModFormat' 'baudRate' 'extra_info2'};
fields.layer2_mandatory     = {1           1           0          };

fields.layer3               = {'distance' 'sweep_param' 'extra_info3'};
fields.layer3_mandatory     = {1           1             0          };

if isfield(P,'extra_info1')
    fields.layer1_mandatory{4} = 1;
elseif isfield(P,'extra_info2')
    fields.layer2_mandatory{3} = 1;  
elseif isfield(P,'extra_info3')
    fields.layer2_mandatory{3} = 1;  
end
% % fields.layer2        = {'year' 'confJournal' 'key_subject' 'other_info'};
% %     'baudRate' 'sampRate' 'key1'};
% %
% % fields.mandatory        = {'dataType' 'year' 'paper' 'baudRate' 'sampRate' 'key1'};
% % fields.mandatory_type   = {'char' 'int32' 'char' 'double' 'double' 'char'};
% % fields.optional         = {'ModFormat' 'OSNR' 'PatternLength' 'key2' 'key3' 'key4' 'key5' 'key6' 'key7' 'key8'};
% % fields.optional_type    = {'char' 'double' 'int32' 'char' 'char' 'char' 'char' 'char' 'char' 'char'};
illegalCharacters       = {'/' ' ' '<' '>' ':' '"' '|' '?' '*' '"\"'};

%% check that P is a struct
if nargin > 0
    if ~isa(P,'struct')
        fprintf('\nP needs to be a struct -  Run "create_waveforms_path()" to learn fields !!!\n')
        error(' ')
    end
end

%% Default answer if function called without parameters (help kind of return)
if nargin == 0
    fprintf(['\nFields Folder Level 1:       ']);
    for i = 1:numel(fields.layer1)
        fprintf([fields.layer1{i},'('])
        if(fields.layer1_mandatory{i}); fprintf('req.'); else; fprintf('opt.'); end;
        fprintf([') ']);
    end
    fprintf(['\nFields Folder Level 2:       ']);
    for i = 1:numel(fields.layer2)
        fprintf([fields.layer2{i},'('])
        if(fields.layer2_mandatory{i}); fprintf('req.'); else; fprintf('opt.'); end;
        fprintf([') ']);
    end
    fprintf(['\nFields Folder Level 3:       ']);
    for i = 1:numel(fields.layer3)
        fprintf([fields.layer3{i},'('])
        if(fields.layer3_mandatory{i}); fprintf('req.'); else; fprintf('opt.'); end;
        fprintf([') ']);
    end
    
    fprintf(['\nIllegal characters:          ']);
    for i = 1:numel(illegalCharacters)
        fprintf(['"-',illegalCharacters{i},'-" ']);
    end
    fprintf('\n\n--> All fields should be provided as strings! <--')
    fprintf('\n\n');
    return;
    
end
%% Test and assemble path
n = 0;
temp = [];
for k1 = 1:3
    for i = 1:eval(['numel(fields.layer',num2str(k1),')'])
        field_layer_name = eval(['fields.layer',num2str(k1),'{i}']);
        if eval(['fields.layer',num2str(k1),'_mandatory{i}'])
            if ~isfield(P, field_layer_name)
                fprintf(['\nERROR - Mandatory fields missing: ',field_layer_name]);
                n = n+1;
            else
                if ~isa(eval(['P.',field_layer_name]),'char')
                    fprintf(['\nERROR - P.',field_layer_name,' is not a string']);
                    n = n+1;
                end
                
                for j = 1:numel(illegalCharacters)
                    if ~isempty(strfind(eval(['P.',field_layer_name]),illegalCharacters{j}))
                        fprintf(['\nERROR - P.',field_layer_name,' using illegal characters: "-',illegalCharacters{j},'-" !!!']);
                        n = n+1;
                    end
                end
                if strcmp(field_layer_name,'sweep_param')
                    temp = [temp,'_sweep'];
                end
                    
                if n == 0
                    if i == 1
                        temp = [temp,eval(['P.',field_layer_name])];
                    else
                        temp = [temp,'_',eval(['P.',field_layer_name])];
                    end
                end
            end
        end
    end
    if isunix
        temp = [temp,'/'];
    else
        temp = [temp,'\'];
    end
    if k1 == 1
        temp_diary = temp;
    end
end
if n > 0
    fprintf('\n')
    error(' ')
end

%% Build path
% if isunix
%     data_path = ['/rdata/ong-archive/waveforms_repository/'];
% else
%     data_path = ['X:\waveforms_repository\'];
% end

diary_path = fullfile(data_path,temp_diary);
data_path  = fullfile(data_path,[temp]);













