function ProcessFiles(pathnames,outfolder)

% PROCESSFILES - Process and convert file(s) to S-array.
% ProcessFiles(pathnames,outfolder)
%
% (TEMPLATE)
%
% P.G. Bonanni
% 1/28/21

% Copyright (c) 2024  Pierino G. Bonanni
% Distributed under GNU General Public License v2.0.


% Run batch process
fun = @(x)ProcessFile(x,outfolder);
RunBatchFunction(fun,pathnames)



% -----------------------------------------------------------------------
function ProcessFile(pathname,outfolder)

% Get filename parts
[folder,rootname,ext] = fileparts(pathname);
fname = [rootname,ext];

% Check file type
if ~IsFileType(pathname,'xls')
  error('Works on .xlsx or .csv files only.')
end

% Read the file as an S-array
S = ReadXlsFile(pathname);

% Collapse the S-array into dataset form
Data = CollapseSarray(S);


% ...


% Convert back to S-array
S = DataToSarray(Data);

% Build output pathname
outfile = ['S_',rootname,'.mat'];
outpath = fullfile(outfolder,outfile);

% Save S-array to file
save(outpath,'S','-v7.3')
