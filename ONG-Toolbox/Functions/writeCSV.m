function writeCSV( fileName, data )
%writeCSV( fileName, data ) 
% Writes data to a CSV file for uploading into the FPGA RAM
% Assumes that  data has already been quantised to integer values
% between 0:63 because the DAC has 6 bits of resolution.
%
% This fucntion runs slow under Windwos. Use linux if you can
%
% Inputs: fileName - name of the file (string)
% data - array of data to write as csv
%
%
% Author Sean Kimurray, November 2013


fid = fopen(fileName, 'w'); % 'w' to write, 'a' for append
for k = 1:length(data)-1
    fprintf(fid, '%d,\n', data(k)); % might need \n or \r for windows.
end
    fprintf(fid, '%d\n', data(k+1)); % might need \n or \r for windows.
fclose(fid);

end

