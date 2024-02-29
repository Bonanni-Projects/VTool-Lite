function ProcessFiles(pathnames,outfolder)

% PROCESSFILES - Process data file(s) and store in vtl format.
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
[~,rootname,ext] = fileparts(pathname);
fname = [rootname,ext];

% Extract data from the file
s = ExtractData(pathname);


% ...


% Build output pathname
outfile = [rootname,'.vtl'];
outpath = fullfile(outfolder,outfile);

% Save to output file
save(outpath,'-struct','s')
