function ProcessFiles(pathnames)

% PROCESSFILES - Process text files.
% ProcessFiles(pathnames)
%
% In-place processing of text files (TEMPLATE). 
%
% P.G. Bonanni
% 1/28/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Run batch process
fun = @(x)ProcessFile(x);
RunBatchFunction(fun,pathnames)



% -----------------------------------------------------------------------
function ProcessFile(pathname)

% Get filename parts
[folder,rootname,ext] = fileparts(pathname);
fname = [rootname,ext];

% Check file extension
if ~strcmpi(ext,'.txt')
  error('Works on .txt files only.')
end

% Read the file as text lines
lines = textread(pathname,'%s','delimiter','\n','whitespace','');


% ...


% Save a copy of the original file
pathname1 = fullfile(folder,[rootname,' (orig)',ext]);
copyfile(pathname,pathname1)

% Write the new file
fid = fopen(pathname,'w');
fprintf(fid,'%s\r\n',lines{:});
fclose(fid);
