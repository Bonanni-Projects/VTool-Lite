function ProcessFiles(pathnames)

% PROCESSFILES - Process .mat files.
% ProcessFiles(pathnames)
%
% In-place processing of .mat files (TEMPLATE). 
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
if ~strcmp(ext,'.mat')
  error('Works on .mat files only.')
end

% Load the file
s = load(pathname);


% ...


% Save a copy of the original file
pathname1 = fullfile(folder,[rootname,' (orig)',ext]);
copyfile(pathname,pathname1)

% Save the new file
save(pathname,'-struct','s')
